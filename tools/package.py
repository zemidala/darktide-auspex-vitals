"""Собирает релиз для Nexus.

Запуск:  python tools/package.py

Результат в dist/:
  auspex_vitals-<версия>.zip            — папка мода в корне архива (как ждёт Vortex), LICENSE внутри;
  nexus/auspex_vitals.bbcode, .summary.txt — описание страницы с подставленной версией.
"""

import re
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
    """UTF-8 без BOM, LF."""
    for path in MOD_DIR.rglob("*"):
        if not path.is_file():
            continue
        data = path.read_bytes()
        if data.startswith(b"\xef\xbb\xbf"):
            sys.exit(f"BOM в {path}")
        if b"\r\n" in data:
            sys.exit(f"CRLF в {path}")
        data.decode("utf-8")


def main() -> None:
    check_files()
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
