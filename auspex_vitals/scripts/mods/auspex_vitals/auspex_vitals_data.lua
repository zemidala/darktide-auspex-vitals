local mod = get_mod("auspex_vitals")

local function mode_dropdown(setting_id, default_value)
	return {
		setting_id = setting_id,
		type = "dropdown",
		default_value = default_value,
		options = {
			{ text = "mode_always", value = "always" },
			{ text = "mode_wounded", value = "wounded" },
			{ text = "mode_off", value = "off" },
		},
	}
end

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
			{
				setting_id = "group_categories",
				type = "group",
				sub_widgets = {
					mode_dropdown("mode_horde", "wounded"),
					mode_dropdown("mode_elite", "always"),
					mode_dropdown("mode_special", "always"),
					mode_dropdown("mode_boss", "always"),
				},
			},
			{
				setting_id = "group_display",
				type = "group",
				sub_widgets = {
					{
						setting_id = "bar_style",
						type = "dropdown",
						default_value = "bar",
						options = {
							{ text = "bar_style_bar", value = "bar" },
							{ text = "bar_style_ring", value = "ring" },
							{ text = "bar_style_ring_smooth", value = "ring_smooth" },
							{ text = "bar_style_sphere", value = "sphere" },
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
					{ setting_id = "show_dots", type = "checkbox", default_value = true },
					{ setting_id = "dot_center", type = "checkbox", default_value = false },
					{ setting_id = "show_health_number", type = "checkbox", default_value = false },
					{ setting_id = "show_name", type = "checkbox", default_value = false },
					{ setting_id = "line_of_sight", type = "checkbox", default_value = true },
					{ setting_id = "hide_behind_enemies", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "group_game_elements",
				type = "group",
				sub_widgets = {
					{ setting_id = "hide_game_boss_bar", type = "checkbox", default_value = true },
					{ setting_id = "hide_game_damage_indicator", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "group_damage_numbers",
				type = "group",
				sub_widgets = {
					{ setting_id = "show_damage_numbers", type = "checkbox", default_value = true },
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
						setting_id = "damage_numbers_scale",
						type = "numeric",
						default_value = 100,
						range = { 50, 250 },
						decimals_number = 0,
						unit_text = "percent",
					},
					{
						setting_id = "damage_numbers_column_offset",
						type = "numeric",
						default_value = 120,
						range = { 20, 500 },
						decimals_number = 0,
					},
					{ setting_id = "damage_numbers_dots", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "group_performance",
				type = "group",
				sub_widgets = {
					{ setting_id = "prioritize_aim", type = "checkbox", default_value = true },
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
				},
			},
		},
	},
}
