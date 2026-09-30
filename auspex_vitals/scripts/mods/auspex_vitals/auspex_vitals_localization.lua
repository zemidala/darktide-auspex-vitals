return {
	mod_name = {
		en = "Auspex Vitals",
		ru = "Auspex Vitals",
	},
	mod_description = {
		en = "Enemy health bars and status: damage over time, debuffs, stagger.",
		ru = "Полосы здоровья и состояние врагов: периодический урон, дебаффы, ошеломление.",
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
		en = "Bar — a thin bar over the enemy. Ring — a compact ring, damage eats it clockwise: dots (with a light trail of fresh damage) or smooth. Sphere — a filled circle, health poured bottom-up like liquid. Rings and the sphere take less space in a crowd.",
		ru = "Полоса — тонкая полоса над врагом. Кольцо — компактное кольцо, урон «съедает» его по часовой стрелке: из точек (со светлым следом свежего урона) или гладкое. Сфера — залитый круг, здоровье налито снизу вверх, как жидкость. Кольца и сфера в толпе занимают меньше места.",
	},
	bar_style_bar = {
		en = "Bar",
		ru = "Полоса",
	},
	bar_style_ring = {
		en = "Ring (dots)",
		ru = "Кольцо (точки)",
	},
	bar_style_ring_smooth = {
		en = "Ring (smooth)",
		ru = "Кольцо (гладкое)",
	},
	bar_style_sphere = {
		en = "Sphere",
		ru = "Сфера",
	},
	bar_width = {
		en = "Bar width / ring size",
		ru = "Ширина полос / размер колец",
	},
	bar_width_description = {
		en = "Base bar width: horde 100, elites and specialists 140, bosses 190 pixels. Base ring diameter: 26, 34 and 46; sphere: 22, 30 and 40 pixels.",
		ru = "Базовая ширина полосы: орда 100, элита и специалисты 140, боссы 190 пикселей. Базовый диаметр кольца: 26, 34 и 46, сферы: 22, 30 и 40 пикселей.",
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
		en = "For rings and the sphere: the top-priority effect icon sits inside the shape, its stacks to the left; other effects stay in a row below.",
		ru = "Для колец и сферы: значок самого важного эффекта — внутри фигуры, его стаки — слева; остальные эффекты — строкой ниже.",
	},
	show_health_number = {
		en = "Health number",
		ru = "Число здоровья",
	},
	show_name = {
		en = "Enemy name",
		ru = "Имя врага",
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
	ring_preview_command = {
		en = "Show or hide round material candidates for the health ring",
		ru = "Показать или скрыть круглые материалы-кандидаты для кольца здоровья",
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
