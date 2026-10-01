local mod = get_mod("auspex_vitals")

local function mode_dropdown(setting_id, default_value)
	return {
		setting_id = setting_id,
		type = "dropdown",
		default_value = default_value,
		options = {
			{ text = "mode_always", value = "always" },
			{ text = "mode_wounded", value = "wounded" },
			{ text = "mode_recent", value = "recent" },
			{ text = "mode_tagged", value = "tagged" },
			{ text = "mode_off", value = "off" },
		},
	}
end

-- Цвета текста: первым — особый вариант (по здоровью / по категории), дальше общий набор.
local function color_options(special)
	local options = { { text = "color_white", value = "white" } }

	if special then
		options[#options + 1] = { text = "color_" .. special, value = special }
	end

	for _, id in ipairs({ "gray", "yellow", "orange", "red", "green", "cyan" }) do
		options[#options + 1] = { text = "color_" .. id, value = id }
	end

	return options
end

local function percent_slider(setting_id)
	return {
		setting_id = setting_id,
		type = "numeric",
		default_value = 100,
		range = { 50, 250 },
		decimals_number = 0,
		unit_text = "percent",
	}
end

-- Меню разложено по вопросам игрока: кому показывать -> как выглядит -> что над полосой -> подписи ->
-- цифры урона -> когда прятать -> сколько полос. Пункты под галочкой DMF показывает, только когда она включена;
-- у выпадающего списка show_widgets — номера вложенных пунктов, видимых при этом значении.
-- Идентификаторы настроек не менять: от них зависят сохранённые значения игроков.
return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "preset",
				type = "dropdown",
				default_value = "custom",
				options = {
					{ text = "preset_custom", value = "custom" },
					{ text = "preset_minimal", value = "minimal" },
					{ text = "preset_standard", value = "standard" },
					{ text = "preset_everything", value = "everything" },
				},
			},
			-- 1. Кому показывать полосу
			{
				setting_id = "group_categories",
				type = "group",
				sub_widgets = {
					mode_dropdown("mode_horde", "wounded"),
					mode_dropdown("mode_elite", "always"),
					mode_dropdown("mode_special", "always"),
					mode_dropdown("mode_boss", "always"),
					{
						setting_id = "recent_seconds",
						type = "numeric",
						default_value = 10,
						range = { 3, 60 },
						decimals_number = 0,
					},
				},
			},
			-- 2. Как выглядит здоровье
			{
				setting_id = "group_shape",
				type = "group",
				sub_widgets = {
					{
						setting_id = "bar_style",
						type = "dropdown",
						default_value = "bar",
						options = {
							{ text = "bar_style_bar", value = "bar", show_widgets = { 1 } },
							{ text = "bar_style_sphere", value = "sphere", show_widgets = { 2 } },
						},
						sub_widgets = {
							{
								setting_id = "bar_thickness",
								type = "numeric",
								default_value = 7,
								range = { 3, 20 },
								decimals_number = 0,
							},
							{ setting_id = "dot_center", type = "checkbox", default_value = false },
						},
					},
					{
						setting_id = "bar_width",
						type = "numeric",
						default_value = 100,
						range = { 50, 200 },
						decimals_number = 0,
						unit_text = "percent",
					},
					{
						setting_id = "bar_height_offset",
						type = "numeric",
						default_value = 0,
						range = { -100, 150 },
						decimals_number = 0,
					},
					{ setting_id = "shrink_with_distance", type = "checkbox", default_value = true },
					{ setting_id = "show_toughness", type = "checkbox", default_value = true },
					{ setting_id = "boss_state_color", type = "checkbox", default_value = true },
				},
			},
			-- 3. Значки над полосой
			{
				setting_id = "group_effects",
				type = "group",
				sub_widgets = {
					{ setting_id = "show_dots", type = "checkbox", default_value = true },
					{
						setting_id = "show_debuffs",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{ setting_id = "effect_labels", type = "checkbox", default_value = false },
						},
					},
					{
						setting_id = "effect_icon_size",
						type = "numeric",
						default_value = 130,
						range = { 50, 250 },
						decimals_number = 0,
						unit_text = "percent",
					},
				},
			},
			-- 4. Подписи: число здоровья и имя
			{
				setting_id = "group_text",
				type = "group",
				sub_widgets = {
					{
						setting_id = "show_health_number",
						type = "checkbox",
						default_value = false,
						sub_widgets = {
							percent_slider("health_number_size"),
							{
								setting_id = "health_number_format",
								type = "dropdown",
								default_value = "exact",
								options = {
									{ text = "health_number_format_exact", value = "exact" },
									{ text = "health_number_format_short", value = "short" },
								},
							},
							{
								setting_id = "health_number_separator",
								type = "dropdown",
								default_value = "none",
								options = {
									{ text = "separator_none", value = "none" },
									{ text = "separator_dot", value = "dot" },
									{ text = "separator_comma", value = "comma" },
									{ text = "separator_space", value = "space" },
								},
							},
							{
								setting_id = "health_number_color",
								type = "dropdown",
								default_value = "white",
								options = color_options("by_health"),
							},
						},
					},
					{
						setting_id = "show_name",
						type = "checkbox",
						default_value = false,
						sub_widgets = {
							{
								setting_id = "name_categories",
								type = "dropdown",
								default_value = "all",
								options = {
									{ text = "name_categories_all", value = "all" },
									{ text = "name_categories_elite", value = "elite" },
									{ text = "name_categories_boss", value = "boss" },
								},
							},
							percent_slider("name_size"),
							{
								setting_id = "name_color",
								type = "dropdown",
								default_value = "white",
								options = color_options("by_category"),
							},
							{ setting_id = "name_uppercase", type = "checkbox", default_value = false },
						},
					},
				},
			},
			-- 5. Цифры урона
			{
				setting_id = "group_damage_numbers",
				type = "group",
				sub_widgets = {
					{
						setting_id = "show_damage_numbers",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{
								setting_id = "damage_numbers_style",
								type = "dropdown",
								default_value = "floating",
								options = {
									{ text = "damage_numbers_floating", value = "floating" },
									{ text = "damage_numbers_column_right", value = "column_right" },
									{ text = "damage_numbers_column_left", value = "column_left" },
									{ text = "damage_numbers_screen_right", value = "screen_right" },
									{ text = "damage_numbers_screen_left", value = "screen_left" },
								},
							},
							{
								setting_id = "damage_numbers_column_offset",
								type = "numeric",
								default_value = 120,
								range = { 20, 500 },
								decimals_number = 0,
							},
							{
								setting_id = "damage_numbers_scale",
								type = "numeric",
								default_value = 100,
								range = { 50, 250 },
								decimals_number = 0,
								unit_text = "percent",
							},
							{ setting_id = "damage_numbers_dots", type = "checkbox", default_value = true },
						},
					},
				},
			},
			-- 6. Когда полосу прятать или приглушать
			{
				setting_id = "group_visibility",
				type = "group",
				sub_widgets = {
					{ setting_id = "line_of_sight", type = "checkbox", default_value = true },
					{ setting_id = "hide_behind_enemies", type = "checkbox", default_value = true },
					{
						setting_id = "ads_opacity",
						type = "numeric",
						default_value = 100,
						range = { 0, 100 },
						decimals_number = 0,
						unit_text = "percent",
					},
				},
			},
			-- 7. Сколько полос и как далеко
			{
				setting_id = "group_limits",
				type = "group",
				sub_widgets = {
					{
						setting_id = "max_distance",
						type = "numeric",
						default_value = 25,
						range = { 5, 60 },
						decimals_number = 0,
					},
					{
						setting_id = "max_markers",
						type = "numeric",
						default_value = 20,
						range = { 1, 60 },
						decimals_number = 0,
					},
					{ setting_id = "prioritize_aim", type = "checkbox", default_value = true },
				},
			},
			-- 8. Свои элементы игры
			{
				setting_id = "group_game_elements",
				type = "group",
				sub_widgets = {
					{ setting_id = "hide_game_boss_bar", type = "checkbox", default_value = true },
					{ setting_id = "hide_game_damage_indicator", type = "checkbox", default_value = true },
				},
			},
		},
	},
}
