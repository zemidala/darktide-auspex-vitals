# Архитектура (черновик для 0.1)

Сверено с исходниками игры 1.13.0 (дамп Aussiemon, коммит `419fe18`, 2026-09-29). Пути ниже — от корня дампа.

## Откуда брать данные (ответы на открытые вопросы)

Всё нужное для 0.1 доступно клиенту, а не только хосту.

| Что | Где | Заметки |
|---|---|---|
| Список врагов по категориям | `side:alive_units_by_tag("enemy", tag)` — `scripts/extension_systems/side/side.lua` | Сторона игрока — через `side_system`. Теги из `breed.tags`: `horde`, `roamer`, `elite`, `special`, `monster`, `captain` и др. Формат списка: `{ size = N, [1..N] = unit }`. На клиенте `SideExtension` ставится и для husk-юнитов (`minion_unit_template.lua`, `husk_init`). |
| Здоровье | `ScriptUnit.has_extension(unit, "health_system")` → `current_health_percent()`, `max_health()`, `current_health()` | На клиенте это `HuskHealthExtension`: читает поля `health` / `damage` сетевого объекта. На хосте и в соло — `HealthExtension` с тем же интерфейсом. |
| Периодический урон | `ScriptUnit.has_extension(unit, "buff_system")` → `current_stacks(имя_шаблона)`, `has_keyword(kw)` | Баффы миньонов синхронизируются клиентам RPC (`rpc_add_buff`, `rpc_remove_buff_stacks`), см. `minion_buff_extension.lua`. |
| Категория, имя врага | `breed.tags`, `breed.display_name` (через `unit_data_system` → `breed()`) | |

Шаблоны периодического урона (`scripts/settings/buff/weapon_buff_templates.lua`):

| Эффект | Шаблоны | Ключевое слово | Макс. стаков |
|---|---|---|---|
| Горение | `flamer_assault`, `phosphor_burn` (+ огонь от луж в `liquid_area_buff_templates.lua`) | `burning` | 31 |
| Варп-огонь | `warp_fire` | `burning` + `warpfire_burning` | 31 |
| Кровотечение | `bleed`, `bleed_long` | `bleeding` | 16 / 18 |
| Токсин | `neurotoxin_interval_buff`, `…2`, `…3` (+ `broker_buff_templates.lua`) | `toxin` | см. шаблоны |

Для иконки проверять ключевое слово (`has_keyword`) — это дёшево и переживёт новые шаблоны. Число стаков брать через `current_stacks` по известным именам. Если имени в `BuffTemplates` нет, пропускать его: защита от патчей.

## Каркас отображения: маркеры мира

Решение: **свой шаблон для `HudElementWorldMarkers`**, без своего элемента HUD.

- Движок уже делает всё нужное: переводит позицию из мира в экран, ограничивает дальность (`max_distance`), делает затухание и масштаб по расстоянию (`fade_settings`, `scale_settings`) и проверяет прямую видимость пакетно, раз в `raycasts_frame_delay` кадров.
- Шаблоны читаются из `HudElementWorldMarkersSettings.marker_templates` в `init` и хранятся в `self._marker_templates[name]`. Свой шаблон добавляем через `mod:hook_safe("HudElementWorldMarkers", "init", …)`: кладём его в `self._marker_templates`.
- Маркер ставится событием `Managers.event:trigger("add_world_marker_unit", type, unit, callback, data)`, снимается — `"remove_world_marker"` по id. Если юнит умер (`ALIVE[unit]` ложно), движок снимает маркер сам.
- В игре есть готовый шаблон `health_bar` (`world_marker_template_health_bar.lua`) и логика полосы `HudHealthBarLogic` с «призрачным» уроном. Это код игры, на него можно опираться.

### Почему не маркер на каждого врага

`_calculate_markers` каждый кадр обходит **все** маркеры, а `add_world_marker_unit` создаёт по виджету на маркер. В орде сотни юнитов: маркер на каждого бьёт по FPS. Похоже, отсюда и тормоза у существующих модов.

Поэтому маркеры ставятся **лениво**, через собственный планировщик:

1. Раз в N кадров (например, каждые 0,1–0,2 с) обходим списки `alive_units_by_tag` для включённых категорий.
2. Отбираем кандидатов: в пределах дальности, режим категории (всегда / только раненые) и условие «ранен» (`current_health_percent() < 1` или есть периодический урон).
3. Сортируем по расстоянию и оставляем первые K — это лимит маркеров из настроек.
4. Разница с текущим набором: новым кандидатам ставим маркер, выбывшим снимаем.

Виджеты при этом создаются только для K ближайших, а не для всей орды. Отдельный кэш не нужен: юнит→маркер хранится в одной таблице мода.

## Модули мода

```
auspex_vitals.lua            -- точка входа: настройки, хуки, жизненный цикл
av_marker_template.lua       -- шаблон маркера (виджет, update_function)
av_tracker.lua               -- планировщик: выбор юнитов, add/remove маркеров
av_status.lua                -- чтение здоровья и периодического урона с защитными проверками
```

Подключаются из `auspex_vitals.lua` через `mod:io_dofile`.

## Защита от патчей

- Каждое расширение брать через `ScriptUnit.has_extension`, методы проверять перед вызовом.
- Если класса `HudElementWorldMarkers` или события нет, мод пишет в лог одно предупреждение и отключает отображение, но не падает.
- Если включён Healthbars (`get_mod("Healthbars")`), при загрузке выводится одно предупреждение в чат.

## Открыто

- Иконки периодического урона: какие текстуры игры подходят (искать в `content/ui/materials/icons/buffs/`).
- Нужна ли проверка прямой видимости (`check_line_of_sight`): она скрывает полосы за стенами, но стоит лучей. По умолчанию — вкл.
