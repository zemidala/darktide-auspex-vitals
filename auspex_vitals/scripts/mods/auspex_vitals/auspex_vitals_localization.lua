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
	show_bosses_with_game_bar = {
		en = "Bosses with the game's bar",
		ru = "Боссы с полосой игры",
	},
	show_bosses_with_game_bar_description = {
		en = "During a boss fight the game shows its own bar at the top of the screen. Off — our bar over such a boss is hidden.",
		ru = "Во время схватки с боссом игра показывает свою полосу вверху экрана. Выкл — наша полоса над таким боссом скрывается.",
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
	bar_width = {
		en = "Bar width",
		ru = "Ширина полос",
	},
	bar_width_description = {
		en = "Base width: horde 100, elites and specialists 140, bosses 190 pixels.",
		ru = "Базовая ширина: орда 100, элита и специалисты 140, боссы 190 пикселей.",
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
		en = "Burning, warpfire, bleeding and toxin with stack counts under the bar.",
		ru = "Горение, варп-огонь, кровотечение и токсин с числом стаков под полосой.",
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

	warning_other_numbers = {
		en = "%s mod is enabled too: its damage numbers will mix with ours.",
		ru = "Включён ещё и мод %s: его цифры урона смешаются с нашими.",
	},
	warning_other_bars = {
		en = "%s mod is enabled too: enemies may get two health bars.",
		ru = "Включён ещё и мод %s: у врагов могут быть две полосы здоровья.",
	},
}
