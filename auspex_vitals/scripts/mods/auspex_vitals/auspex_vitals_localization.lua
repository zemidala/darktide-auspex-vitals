return {
	mod_name = {
		en = "Auspex Vitals",
		ru = "Auspex Vitals",
	},
	mod_description = {
		en = "Enemy health bars with damage-over-time icons, and your own damage numbers.",
		ru = "Полосы здоровья врагов со значками периодического урона и цифры вашего урона.",
	},

	preset = {
		en = "Preset",
		ru = "Пресет",
	},
	preset_description = {
		en = "Applies a set of values to the settings below. Reopen the mod options to see them.",
		ru = "Выставляет набор значений для настроек ниже. Чтобы их увидеть, откройте настройки мода заново.",
	},
	preset_custom = {
		en = "Custom",
		ru = "Свой",
	},
	preset_minimal = {
		en = "Minimal",
		ru = "Минимум",
	},
	preset_standard = {
		en = "Standard",
		ru = "Стандарт",
	},
	preset_everything = {
		en = "Everything",
		ru = "Всё",
	},

	group_categories = {
		en = "Enemy categories",
		ru = "Категории врагов",
	},
	mode_horde = {
		en = "Horde",
		ru = "Орда",
	},
	mode_elite = {
		en = "Elites",
		ru = "Элита",
	},
	mode_special = {
		en = "Specialists",
		ru = "Специалисты",
	},
	mode_boss = {
		en = "Monstrosities and captains",
		ru = "Чудовища и капитаны",
	},
	mode_always = {
		en = "Always",
		ru = "Всегда",
	},
	mode_wounded = {
		en = "Only wounded",
		ru = "Только раненые",
	},
	mode_recent = {
		en = "Recently damaged",
		ru = "Недавно раненые",
	},
	recent_seconds = {
		en = "\"Recently damaged\": show for, s",
		ru = "«Недавно раненые»: показывать, с",
	},
	recent_seconds_description = {
		en = "How long a bar stays after the enemy last lost health. While it burns, bleeds etc., the bar stays anyway.",
		ru = "Сколько секунд полоса держится после последнего урона по врагу. Пока враг горит, кровоточит и т. п., полоса видна в любом случае.",
	},
	mode_tagged = {
		en = "Only tagged",
		ru = "Только помеченные",
	},
	mode_off = {
		en = "Off",
		ru = "Выкл",
	},

	group_display = {
		en = "Display",
		ru = "Отображение",
	},
	bar_style = {
		en = "Health display",
		ru = "Вид здоровья",
	},
	bar_style_description = {
		en = "Bar — a thin bar over the enemy. Sphere — a compact filled circle, health poured bottom-up like liquid; takes less space in a crowd.",
		ru = "Полоса — тонкая полоса над врагом. Сфера — компактный залитый круг, здоровье налито снизу вверх, как жидкость; в толпе занимает меньше места.",
	},
	bar_style_bar = {
		en = "Bar",
		ru = "Полоса",
	},
	bar_style_sphere = {
		en = "Sphere",
		ru = "Сфера",
	},
	bar_width = {
		en = "Bar width / sphere size",
		ru = "Ширина полос / размер сферы",
	},
	bar_width_description = {
		en = "Base bar width: horde 100, elites and specialists 140, bosses 190 pixels. Base sphere diameter: 22, 30 and 40 pixels.",
		ru = "Базовая ширина полосы: орда 100, элита и специалисты 140, боссы 190 пикселей. Базовый диаметр сферы: 22, 30 и 40 пикселей.",
	},
	bar_thickness = {
		en = "Bar thickness, px",
		ru = "Толщина полосы, пикс.",
	},
	bar_thickness_description = {
		en = "Height of the health bar in pixels at close range (default 7). Shrinks with distance together with the width. Does not affect the sphere.",
		ru = "Высота полосы здоровья в пикселях вблизи (по умолчанию 7). С расстоянием уменьшается вместе с шириной. На сферу не влияет.",
	},
	bar_height_offset = {
		en = "Bar height offset, cm",
		ru = "Сдвиг полосы по высоте, см",
	},
	bar_height_offset_description = {
		en = "The bar is placed above the enemy automatically: above the head or at the breed's height, whichever is higher. This shifts it up (+) or down (-).",
		ru = "Полоса ставится над врагом автоматически: над головой или на высоте роста породы — что выше. Этот сдвиг поднимает (+) или опускает (-) её.",
	},
	percent = {
		en = "%%",
		ru = "%%",
	},
	show_dots = {
		en = "Damage over time",
		ru = "Периодический урон",
	},
	show_dots_description = {
		en = "Burning, warpfire, electrocution, bleeding and toxin under the bar, with stack counts where the effect stacks.",
		ru = "Горение, варп-огонь, электрошок, кровотечение и токсин под полосой, с числом стаков, если эффект стакается.",
	},
	show_debuffs = {
		en = "Debuffs",
		ru = "Дебаффы",
	},
	show_debuffs_description = {
		en = "After the damage-over-time icons: brittleness (armor rending), extra damage taken (all / melee / ranged) and easier stagger, in percent. Taken from the enemy's real stats, so any talent or blessing counts.",
		ru = "После значков периодического урона: хрупкость брони, повышенный получаемый урон (весь / в ближнем бою / от стрельбы) и лёгкость ошеломления — в процентах. Берётся из настоящих характеристик врага, поэтому учитывается любой талант или благословение.",
	},
	show_toughness = {
		en = "Void shield",
		ru = "Щит пустоты",
	},
	show_toughness_description = {
		en = "A thin blue bar above the health of enemies that have toughness: captains (void shield) and the renegade psyker. Empty — the shield is down.",
		ru = "Тонкая голубая полоска над здоровьем у врагов со стойкостью: капитаны (щит пустоты) и колдун ренегатов. Пустая — щит снят.",
	},
	boss_state_color = {
		en = "Weakened / empowered boss color",
		ru = "Цвет ослабленных и усиленных боссов",
	},
	boss_state_color_description = {
		en = "Bosses spawned with reduced health (weakened) get a grey-green bar, empowered ones a purple bar. The name gets the same prefix as on the game's boss bar.",
		ru = "Боссы, появившиеся с уменьшенным здоровьем (ослабленные), получают серо-зелёную полосу, усиленные — фиолетовую. Имя получает ту же приставку, что на полосе босса у игры.",
	},
	shrink_with_distance = {
		en = "Shrink with distance",
		ru = "Уменьшать с расстоянием",
	},
	shrink_with_distance_description = {
		en = "Full size up to 6 m, then smoothly down to 55% at the max distance — so far bars don't cover small enemy models.",
		ru = "Полный размер до 6 м, дальше плавно до 55% на пределе дальности — чтобы у дальних врагов значки не закрывали маленькую модель.",
	},
	dot_center = {
		en = "Main effect in the center",
		ru = "Главный эффект в центре",
	},
	dot_center_description = {
		en = "For the sphere: the top-priority effect icon sits inside it (white with a dark outline), its stacks to the left; other effects stay in a row above.",
		ru = "Для сферы: значок самого важного эффекта — внутри неё (белый с тёмной обводкой), его стаки — слева; остальные эффекты — строкой выше.",
	},
	show_health_number = {
		en = "Health number",
		ru = "Число здоровья",
	},
	health_number_size = {
		en = "Health number size",
		ru = "Размер числа здоровья",
	},
	health_number_size_description = {
		en = "100% is the size of the enemy name text. Shrinks with distance like the bar.",
		ru = "100% — как у имени врага. С расстоянием уменьшается вместе с полосой.",
	},
	health_number_format = {
		en = "Health number format",
		ru = "Вид числа здоровья",
	},
	health_number_format_description = {
		en = "Short: from 1000 health it is shown in thousands with one decimal: 2345 -> 2.3k, 3000 -> 3.0k, 24700 -> 24.7k. Below 1000 the number stays exact.",
		ru = "Сокращённо: от 1000 здоровья — в тысячах с одним знаком: 2345 -> 2.3к, 3000 -> 3.0к, 24700 -> 24.7к. Меньше 1000 — точное число.",
	},
	health_number_format_exact = {
		en = "Exact (2345)",
		ru = "Точно (2345)",
	},
	health_number_format_short = {
		en = "Short (2.3k)",
		ru = "Сокращённо (2.3к)",
	},
	health_number_separator = {
		en = "Separator",
		ru = "Разделитель",
	},
	health_number_separator_description = {
		en = "Exact: between thousands — 24.700, 24,700 or 24 700. Short: the decimal mark — 2.3k or 2,3k (with Space or None — a dot). Visible on enemies with 1000+ health.",
		ru = "Точно: между разрядами — 24.700, 24,700 или 24 700. Сокращённо: десятичный знак — 2.3к или 2,3к (при «Пробел» и «Нет» — точка). Виден у врагов с 1000+ здоровья.",
	},
	separator_none = {
		en = "None (24700)",
		ru = "Нет (24700)",
	},
	separator_space = {
		en = "Space (24 700)",
		ru = "Пробел (24 700)",
	},
	separator_dot = {
		en = "Dot (24.700 / 2.3k)",
		ru = "Точка (24.700 / 2.3к)",
	},
	separator_comma = {
		en = "Comma (24,700 / 2,3k)",
		ru = "Запятая (24,700 / 2,3к)",
	},
	thousands_suffix = {
		en = "k",
		ru = "к",
	},
	health_number_color = {
		en = "Health number color",
		ru = "Цвет числа здоровья",
	},
	health_number_color_description = {
		en = "\"By health\": green at full health, yellow at half, red when almost dead.",
		ru = "«По здоровью»: зелёный при полном здоровье, жёлтый на половине, красный, когда враг почти мёртв.",
	},
	color_white = {
		en = "White",
		ru = "Белый",
	},
	color_by_health = {
		en = "By health",
		ru = "По здоровью",
	},
	color_gray = {
		en = "Gray",
		ru = "Серый",
	},
	color_yellow = {
		en = "Yellow",
		ru = "Жёлтый",
	},
	color_orange = {
		en = "Orange",
		ru = "Оранжевый",
	},
	color_red = {
		en = "Red",
		ru = "Красный",
	},
	color_green = {
		en = "Green",
		ru = "Зелёный",
	},
	color_cyan = {
		en = "Cyan",
		ru = "Голубой",
	},
	show_name = {
		en = "Enemy name",
		ru = "Имя врага",
	},
	name_categories = {
		en = "Show name for",
		ru = "Показывать имя для",
	},
	name_categories_all = {
		en = "All enemies with a bar",
		ru = "Всех врагов с полосой",
	},
	name_categories_elite = {
		en = "Elites, specialists and bosses",
		ru = "Элиты, специалистов и боссов",
	},
	name_categories_boss = {
		en = "Monstrosities and captains only",
		ru = "Только чудовищ и капитанов",
	},
	name_size = {
		en = "Name size",
		ru = "Размер имени",
	},
	name_size_description = {
		en = "100% is the default text size. Shrinks with distance like the bar.",
		ru = "100% — обычный размер текста. С расстоянием уменьшается вместе с полосой.",
	},
	name_color = {
		en = "Name color",
		ru = "Цвет имени",
	},
	name_color_description = {
		en = "\"By category\": the same color as the bar (horde, elites and specialists, bosses).",
		ru = "«По категории»: тот же цвет, что у полосы (орда, элита и специалисты, боссы).",
	},
	color_by_category = {
		en = "By category",
		ru = "По категории",
	},
	name_uppercase = {
		en = "Name in capitals",
		ru = "Имя заглавными",
	},
	ads_opacity = {
		en = "Opacity while aiming",
		ru = "Прозрачность при прицеливании",
	},
	ads_opacity_description = {
		en = "Bars fade to this opacity while you aim down sights (or charge a staff), so they don't cover targets. The enemy at your crosshair keeps a full bar. 100% — no change.",
		ru = "Пока вы целитесь (или заряжаете посох), полосы тускнеют до этой непрозрачности, чтобы не закрывать цели. Враг у прицела остаётся с яркой полосой. 100% — без изменений.",
	},
	line_of_sight = {
		en = "Hide behind walls",
		ru = "Скрывать за стенами",
	},
	line_of_sight_description = {
		en = "Hides bars of enemies you can't see. Costs a few raycasts.",
		ru = "Скрывает полосы врагов, которых не видно. Стоит немного производительности.",
	},

	hide_behind_enemies = {
		en = "Hide behind closer enemies",
		ru = "Скрывать за ближними врагами",
	},
	hide_behind_enemies_description = {
		en = "A bar fades out when a closer enemy's model covers it.",
		ru = "Полоса гаснет, если её закрывает модель врага, стоящего ближе.",
	},
	group_game_elements = {
		en = "Game's own elements",
		ru = "Элементы игры",
	},
	hide_game_boss_bar = {
		en = "Hide the game's boss bar",
		ru = "Скрывать полосу босса игры",
	},
	hide_game_boss_bar_description = {
		en = "The boss health bar at the top of the screen. On — only our bars are shown.",
		ru = "Полоса здоровья босса вверху экрана. Вкл — остаются только наши полосы.",
	},
	hide_game_damage_indicator = {
		en = "Hide the game's damage indicator",
		ru = "Скрывать индикатор урона игры",
	},
	hide_game_damage_indicator_description = {
		en = "The game puts its own bar with armor type and damage numbers on enemies in Psykhanium training. On — only our bar stays.",
		ru = "В тренировках Психаниума игра вешает на врагов свою полосу с типом брони и цифрами урона. Вкл — остаётся только наша полоса.",
	},
	group_damage_numbers = {
		en = "Damage numbers",
		ru = "Цифры урона",
	},
	show_damage_numbers = {
		en = "Show damage numbers",
		ru = "Показывать цифры урона",
	},
	show_damage_numbers_description = {
		en = "Your damage at the hit point. White — normal, yellow — weakspot, orange — critical. Hits landing together are summed.",
		ru = "Ваш урон в точке попадания. Белый — обычный, жёлтый — слабое место, оранжевый — крит. Одновременные попадания складываются.",
	},
	damage_numbers_style = {
		en = "Style",
		ru = "Стиль",
	},
	damage_numbers_style_description = {
		en = "At the hit point — numbers pop up where you hit and float up. Column — numbers stack next to the enemy: the newest at the bottom, older ones move up. Feed — one list next to the crosshair for all your damage, not tied to enemies.",
		ru = "У точки попадания — цифры появляются там, куда попали, и всплывают. Столбцом — цифры встают рядом с врагом: новая внизу, старые сдвигаются вверх. Лентой — один список рядом с прицелом для всего вашего урона, без привязки к врагам.",
	},
	damage_numbers_floating = {
		en = "At the hit point",
		ru = "У точки попадания",
	},
	damage_numbers_column_right = {
		en = "Column to the right",
		ru = "Столбцом справа",
	},
	damage_numbers_column_left = {
		en = "Column to the left",
		ru = "Столбцом слева",
	},
	damage_numbers_screen_right = {
		en = "Feed right of the crosshair",
		ru = "Лентой справа от прицела",
	},
	damage_numbers_screen_left = {
		en = "Feed left of the crosshair",
		ru = "Лентой слева от прицела",
	},
	damage_numbers_scale = {
		en = "Size",
		ru = "Размер",
	},
	damage_numbers_column_offset = {
		en = "Column offset, px",
		ru = "Отступ столбца, пикс.",
	},
	damage_numbers_column_offset_description = {
		en = "How far from the enemy's center (column) or from the crosshair (feed) the numbers stand. Increase it if the enemy model covers the numbers.",
		ru = "Насколько далеко от центра врага (столбец) или от прицела (лента) стоят цифры. Увеличьте, если модель врага закрывает цифры.",
	},
	damage_numbers_dots = {
		en = "Damage over time",
		ru = "Периодический урон",
	},
	damage_numbers_dots_description = {
		en = "Burning, bleeding and other effect ticks, summed per enemy within a second.",
		ru = "Тики горения, кровотечения и других эффектов, сложенные по врагу за секунду.",
	},
	group_performance = {
		en = "Performance",
		ru = "Производительность",
	},
	max_distance = {
		en = "Max distance, m",
		ru = "Дальность, м",
	},
	max_markers = {
		en = "Max bars at once",
		ru = "Полос одновременно",
	},
	prioritize_aim = {
		en = "Prioritize crosshair",
		ru = "Приоритет по прицелу",
	},
	prioritize_aim_description = {
		en = "When there are more enemies than bars, bars go to the ones closer to the crosshair, not just the nearest.",
		ru = "Если врагов больше, чем полос, полосы получают те, кто ближе к прицелу, а не просто ближайшие.",
	},
	max_markers_description = {
		en = "Nearest enemies get bars first. Fewer bars — less load.",
		ru = "Полосы получают ближайшие враги. Чем меньше полос, тем меньше нагрузка.",
	},

	icon_preview_command = {
		en = "Show or hide the effect icon preview",
		ru = "Показать или скрыть просмотр значков эффектов",
	},
	visibility_debug_command = {
		en = "Debug: show what hides each bar",
		ru = "Отладка: показать, что закрывает каждую полосу",
	},
	icon_preview_no_hud = {
		en = "Icon preview works only in a mission or the Psykhanium.",
		ru = "Просмотр значков работает только на миссии или в Психаниуме.",
	},
	icon_preview_not_loaded = {
		en = "not loaded",
		ru = "не загружен",
	},
	icon_preview_burning = {
		en = "Burning",
		ru = "Горение",
	},
	icon_preview_warpfire = {
		en = "Warpfire",
		ru = "Варп-огонь",
	},
	icon_preview_electrocuted = {
		en = "Electrocution",
		ru = "Электрошок",
	},
	icon_preview_bleeding = {
		en = "Bleeding",
		ru = "Кровотечение",
	},
	icon_preview_brittle = {
		en = "Brittleness",
		ru = "Хрупкость",
	},
	icon_preview_vulnerable = {
		en = "Damage taken",
		ru = "Получаемый урон",
	},
	icon_preview_melee_vulnerable = {
		en = "Melee damage taken",
		ru = "Урон в ближнем бою",
	},
	icon_preview_ranged_vulnerable = {
		en = "Ranged damage taken",
		ru = "Урон от стрельбы",
	},
	icon_preview_stagger = {
		en = "Stagger",
		ru = "Ошеломление",
	},
	icon_preview_toxin = {
		en = "Toxin",
		ru = "Токсин",
	},
	warning_other_numbers = {
		en = "%s mod is enabled too: its damage numbers will mix with ours.",
		ru = "Включён ещё и мод %s: его цифры урона смешаются с нашими.",
	},
	warning_other_bars = {
		en = "%s mod is enabled too: enemies may get two health bars.",
		ru = "Включён ещё и мод %s: у врагов могут быть две полосы здоровья.",
	},
}
