"""Собирает релиз для Nexus.

Запуск:  python tools/package.py

Результат в dist/:
  auspex_vitals-<версия>.zip            — папка мода в корне архива (как ждёт Vortex), LICENSE внутри;
  nexus/auspex_vitals.bbcode, .summary.txt — описание страницы с подставленной версией.
"""

import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOD = "auspex_vitals"
MOD_DIR = ROOT / MOD
DIST = ROOT / "dist"
NEXUS = ROOT / "nexus"


def mod_version() -> str:
    text = (MOD_DIR / f"{MOD}.mod").read_text(encoding="utf-8")
    m = re.search(r'version\s*=\s*"([^"]+)"', text)
    if not m:
        sys.exit(f"В {MOD}.mod нет version")
    return m.group(1)


def check_files() -> None:
    """UTF-8 без BOM, LF, без управляющих символов (в игре они дают квадратики)."""
    for path in MOD_DIR.rglob("*"):
        if not path.is_file():
            continue
        data = path.read_bytes()
        if data.startswith(b"\xef\xbb\xbf"):
            sys.exit(f"BOM в {path}")
        if b"\r\n" in data:
            sys.exit(f"CRLF в {path}")
        text = data.decode("utf-8")
        for number, line in enumerate(text.split("\n"), 1):
            for ch in line:
                code = ord(ch)
                if (code < 32 and ch != "\t") or 0x7F <= code < 0xA0 or 0xE000 <= code <= 0xF8FF or code in (0xFFFD, 0xFEFF):
                    sys.exit(f"Недопустимый символ U+{code:04X} в {path}:{number}")


LOC_ENTRY = re.compile(r'\n\t([a-z_0-9]+) = \{\n(.*?)\n\t\},', re.S)
LOC_STRING = re.compile(r'(\w+) = "((?:[^"\\]|\\.)*)"')
# символы вне ASCII и кириллицы, которые точно есть в шрифтах игры
ALLOWED_EXTRA = set("«»—ёЁ")


def check_localization() -> None:
    """У каждой строки есть en и ru; знак % — как ждёт DMF; только символы, которые игра умеет рисовать.

    Названия идут через string.format (нужно %%), подсказки *_description — без форматирования (нужен %).
    """
    path = MOD_DIR / "scripts" / "mods" / MOD / f"{MOD}_localization.lua"
    text = path.read_text(encoding="utf-8")
    errors = []
    for match in LOC_ENTRY.finditer(text):
        key, body = match.group(1), match.group(2)
        strings = dict(LOC_STRING.findall(body))
        if set(strings) != {"en", "ru"}:
            errors.append(f"{key}: языки {sorted(strings)}, нужны en и ru")
        for lang, value in strings.items():
            if key.endswith("_description"):
                if "%%" in value:
                    errors.append(f"{key}.{lang}: в подсказке %% покажется как есть — нужен один %")
            else:
                rest = value.replace("%%", "").replace("%s", "").replace("%d", "")
                if "%" in rest:
                    errors.append(f"{key}.{lang}: одиночный % в названии — нужно %%")
            for ch in value:
                code = ord(ch)
                if code >= 128 and not 0x410 <= code <= 0x44F and ch not in ALLOWED_EXTRA:
                    errors.append(f"{key}.{lang}: символ {ch!r} (U+{code:04X}) может не отрисоваться")
    if errors:
        sys.exit("Локализация:\n  " + "\n  ".join(errors))


def find_luajit() -> str | None:
    found = shutil.which("luajit")
    if found:
        return found
    local = Path.home() / "AppData" / "Local" / "Programs" / "LuaJIT" / "bin" / "luajit.exe"
    return str(local) if local.is_file() else None


def check_syntax() -> None:
    """Синтаксис Lua тем же LuaJIT, на котором работает игра. Без LuaJIT проверка пропускается."""
    luajit = find_luajit()
    if not luajit:
        print("LuaJIT не найден — синтаксис не проверен (winget install DEVCOM.LuaJIT)")
        return
    files = sorted(MOD_DIR.rglob("*.lua")) + sorted(MOD_DIR.rglob("*.mod"))
    for path in files:
        result = subprocess.run([luajit, "-bl", str(path)], capture_output=True, text=True)
        if result.returncode != 0:
            sys.exit(f"Синтаксис: {path}\n{result.stderr.strip()}")


def main() -> None:
    check_files()
    check_localization()
    check_syntax()
    version = mod_version()
    DIST.mkdir(exist_ok=True)

    archive = DIST / f"{MOD}-{version}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(MOD_DIR.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(ROOT).as_posix())
        zf.write(ROOT / "LICENSE", f"{MOD}/LICENSE")

    out = DIST / "nexus"
    out.mkdir(exist_ok=True)
    for template in NEXUS.glob(f"{MOD}.*"):
        text = template.read_text(encoding="utf-8").replace("{{VERSION}}", version)
        (out / template.name).write_text(text, encoding="utf-8", newline="\n")

    print(f"{archive.relative_to(ROOT)}  ({archive.stat().st_size // 1024} KB)")
    print(f"{out.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
