-- Auspex Vitals: полосы здоровья и состояние врагов.
-- Устройство — docs/architecture.md: свой шаблон маркера HudElementWorldMarkers
-- и планировщик, который ставит маркеры только ближайшим врагам.

local mod = get_mod("auspex_vitals")

local SCRIPTS = "auspex_vitals/scripts/mods/auspex_vitals/"

-- порядок важен: шаблон и планировщик берут модули из mod.*
mod.av_status = mod:io_dofile(SCRIPTS .. "av_status")
mod.av_marker_template = mod:io_dofile(SCRIPTS .. "av_marker_template")
mod.av_tracker = mod:io_dofile(SCRIPTS .. "av_tracker")
mod.av_damage_numbers = mod:io_dofile(SCRIPTS .. "av_damage_numbers")
mod.av_icon_preview = mod:io_dofile(SCRIPTS .. "av_icon_preview")

local Template = mod.av_marker_template
local Tracker = mod.av_tracker
local DamageNumbers = mod.av_damage_numbers
local IconPreview = mod.av_icon_preview

local PRESETS = {
	minimal = {
		mode_horde = "off",
		mode_elite = "wounded",
		mode_special = "always",
		mode_boss = "always",
		show_dots = false,
		show_damage_numbers = false,
		show_health_number = false,
		show_name = false,
		max_distance = 20,
		max_markers = 10,
	},
	standard = {
		mode_horde = "wounded",
		mode_elite = "always",
		mode_special = "always",
		mode_boss = "always",
		show_dots = true,
		show_damage_numbers = true,
		show_health_number = false,
		show_name = false,
		max_distance = 25,
		max_markers = 20,
	},
	everything = {
		mode_horde = "always",
		mode_elite = "always",
		mode_special = "always",
		mode_boss = "always",
		show_dots = true,
		show_damage_numbers = true,
		show_health_number = true,
		show_name = true,
		max_distance = 40,
		max_markers = 40,
	},
}

local function _read_settings()
	local cfg = {
		modes = {
			horde = mod:get("mode_horde") or "wounded",
			elite = mod:get("mode_elite") or "always",
			special = mod:get("mode_special") or "always",
			boss = mod:get("mode_boss") or "always",
		},
		show_dots = mod:get("show_dots") ~= false,
		bar_width = mod:get("bar_width") or 100,
		bar_thickness = mod:get("bar_thickness") or 7,
		bar_style = mod:get("bar_style") or "bar",
		dot_center = mod:get("dot_center") == true,
		bar_height_offset = mod:get("bar_height_offset") or 0,
		shrink_with_distance = mod:get("shrink_with_distance") ~= false,
		show_health_number = mod:get("show_health_number") == true,
		health_number_size = mod:get("health_number_size") or 100,
		health_number_color = mod:get("health_number_color") or "white",
		health_number_format = mod:get("health_number_format") or "exact",
		health_number_separator = mod:get("health_number_separator") == "comma" and "," or ".",
		thousands_suffix = mod:localize("thousands_suffix"),
		show_name = mod:get("show_name") == true,
		line_of_sight = mod:get("line_of_sight") ~= false,
		hide_behind_enemies = mod:get("hide_behind_enemies") ~= false,
		hide_game_damage_indicator = mod:get("hide_game_damage_indicator") ~= false,
		show_damage_numbers = mod:get("show_damage_numbers") ~= false,
		damage_numbers_style = mod:get("damage_numbers_style") or "floating",
		damage_numbers_scale = mod:get("damage_numbers_scale") or 100,
		damage_numbers_column_offset = mod:get("damage_numbers_column_offset") or 120,
		damage_numbers_dots = mod:get("damage_numbers_dots") ~= false,
		hide_game_boss_bar = mod:get("hide_game_boss_bar") ~= false,
		prioritize_aim = mod:get("prioritize_aim") ~= false,
		max_distance = mod:get("max_distance") or 25,
		max_markers = mod:get("max_markers") or 20,
	}

	mod.cfg = cfg
	Template.apply_settings(cfg)
end

_read_settings()

-- Индикатор урона игры (damage_indicator): полоса, тип брони, цифры урона.
-- Игра вешает его на врагов тренировочных сценариев Психаниума.
local GAME_DAMAGE_INDICATOR = "damage_indicator"

local function _skip_marker(marker_type)
	return marker_type == GAME_DAMAGE_INDICATOR and mod.cfg.hide_game_damage_indicator and mod:is_enabled()
end

-- снять уже поставленные индикаторы игры, когда настройку включили
local function _remove_game_damage_indicators()
	local element = Tracker.element()
	local markers = element and mod.cfg.hide_game_damage_indicator and element._markers_by_type
	local indicators = markers and markers[GAME_DAMAGE_INDICATOR]

	if not indicators then
		return
	end

	local ids = {}

	for i = 1, #indicators do
		ids[i] = indicators[i].id
	end

	for i = 1, #ids do
		element:event_remove_world_marker(ids[i])
	end
end

-- Полоса босса игры вверху экрана: не рисуем, если включено скрытие.
mod:hook("HudElementBossHealth", "draw", function (func, self, ...)
	if mod.cfg.hide_game_boss_bar and mod:is_enabled() then
		return
	end

	return func(self, ...)
end)

mod:hook("HudElementWorldMarkers", "event_add_world_marker_unit", function (func, self, marker_type, ...)
	if _skip_marker(marker_type) then
		return
	end

	return func(self, marker_type, ...)
end)

mod:hook("HudElementWorldMarkers", "event_add_world_marker_position", function (func, self, marker_type, ...)
	if _skip_marker(marker_type) then
		return
	end

	return func(self, marker_type, ...)
end)

mod.on_setting_changed = function (setting_id)
	if setting_id == "preset" then
		local preset = PRESETS[mod:get("preset")]

		if preset then
			for id, value in pairs(preset) do
				mod:set(id, value)
			end
		end
	end

	_read_settings()
	-- маркеры с прежними настройками пересоздаст планировщик
	Tracker.remove_all()
	DamageNumbers.clear()
	_remove_game_damage_indicators()
end

mod.on_disabled = function ()
	Tracker.remove_all()
	DamageNumbers.clear()
end

-- Перезагрузка модов (DMF, режим разработчика, Ctrl+Shift+R): убрать все свои маркеры и шаблоны,
-- иначе старые полосы останутся висеть со старым кодом рядом с новыми.
mod.on_unload = function (exit_game)
	if exit_game then
		return
	end

	local element = Tracker.element()

	if not element then
		return
	end

	local markers_by_type = element._markers_by_type
	local templates = element._marker_templates
	local names = { Template.name, DamageNumbers.template.name, IconPreview.template.name, IconPreview.ring_template.name }

	for _, name in ipairs(names) do
		local list = type(markers_by_type) == "table" and markers_by_type[name]

		if list then
			local ids = {}

			for i = 1, #list do
				ids[#ids + 1] = list[i].id
			end

			for i = 1, #ids do
				element:event_remove_world_marker(ids[i])
			end
		end

		if type(templates) == "table" then
			templates[name] = nil
		end
	end
end

local _warned_no_templates = false

-- Регистрирует шаблон в элементе маркеров. Вызывается и из update: если мод включили посреди миссии,
-- init уже прошёл без нас.
local function _attach(element)
	local templates = element._marker_templates

	if type(templates) ~= "table" then
		if not _warned_no_templates then
			_warned_no_templates = true
			mod:warning("HudElementWorldMarkers has no _marker_templates: bars disabled")
		end

		return false
	end

	mod.av_status.reset_resource_cache()
	templates[Template.name] = Template
	templates[DamageNumbers.template.name] = DamageNumbers.template
	templates[IconPreview.template.name] = IconPreview.template
	templates[IconPreview.ring_template.name] = IconPreview.ring_template
	Tracker.attach(element)
	DamageNumbers.attach(element)

	return true
end

mod:hook_safe("HudElementWorldMarkers", "init", function (self)
	_attach(self)
end)

mod:hook_safe("HudElementWorldMarkers", "update", function (self, dt, t)
	if Tracker.element() ~= self and not _attach(self) then
		return
	end

	-- общее время для цифр урона: отчёты об атаках приходят без времени
	DamageNumbers.now = t
	Tracker.update(self, dt)
end)

mod:hook_safe("HudElementWorldMarkers", "destroy", function (self)
	Tracker.detach(self)
	DamageNumbers.detach(self)
	IconPreview.detach()
end)

mod:hook_safe("AttackReportManager", "add_attack_result", function (self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike)
	DamageNumbers.on_attack_result(damage_profile, attacked_unit, attacking_unit, hit_world_position, hit_weakspot, damage, attack_type, is_critical_strike)
end)

-- /av_icons — показать или скрыть сетку значков эффектов, чтобы выбрать читаемые
mod:command("av_icons", mod:localize("icon_preview_command"), function ()
	IconPreview.toggle(Tracker.element())
end)

-- /av_rings — показать или скрыть круглые материалы игры-кандидаты для кольца здоровья
mod:command("av_rings", mod:localize("ring_preview_command"), function ()
	IconPreview.toggle_rings(Tracker.element())
end)

mod.on_all_mods_loaded = function ()
	mod:info("loaded")

	-- моды со своими полосами над врагами: вместе с нами у врага будет две полосы
	local other_bars = {
		Healthbars = "Healthbars",
		enemies_improved = "Enemies Improved",
	}

	for mod_id, title in pairs(other_bars) do
		local other = get_mod(mod_id)

		if other and other:is_enabled() then
			mod:echo(mod:localize("warning_other_bars", title))
		end
	end

	-- моды со своими цифрами урона: их цифры не отличить от наших
	local other_numbers = {
		DamageNumbers = "Damage Numbers",
	}

	if mod.cfg.show_damage_numbers then
		for mod_id, title in pairs(other_numbers) do
			local other = get_mod(mod_id)

			if other and other:is_enabled() then
				mod:echo(mod:localize("warning_other_numbers", title))
			end
		end
	end
end
