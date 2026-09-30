# Auspex Vitals

Мод для **Warhammer 40,000: Darktide** (Darktide Mod Framework): полосы здоровья и состояние врагов —
урон, периодический урон, дебаффы, ошеломление.

> Статус: заготовка. Мод загружается, функциональность в разработке — см. [docs/ideas.md](docs/ideas.md).

Это самостоятельный мод, а не форк: код [Healthbars](https://www.nexusmods.com/warhammer40kdarktide/mods/16)
не используется.

## Разработка

1. Склонировать репозиторий.
2. Запустить `dev-link.cmd` — он создаст в папке `mods` игры ссылку `auspex_vitals` на папку мода в репозитории
   (junction, права администратора не нужны). Правки в репозитории игра увидит после перезапуска.
3. С AML порядок загрузки выставится сам; без AML — добавить `auspex_vitals` в `mod_load_order.txt`.

Лог игры: `%APPDATA%\Fatshark\Darktide\console_logs\` (строки `[MOD][auspex_vitals]`).

## Требования

- [Darktide Mod Loader](https://www.nexusmods.com/warhammer40kdarktide/mods/19)
- [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8)

## Лицензия

MIT, см. [LICENSE](LICENSE).
