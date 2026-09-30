-- Auspex Vitals: полосы здоровья и состояние врагов.
-- Устройство — docs/architecture.md: свой шаблон маркера HudElementWorldMarkers
-- и планировщик, который ставит маркеры только ближайшим врагам.

local mod = get_mod("auspex_vitals")

local SCRIPTS = "auspex_vitals/scripts/mods/auspex_vitals/"

-- порядок важен: шаблон и планировщик берут модули из mod.*
mod.av_status = mod:io_dofile(SCRIPTS .. "av_status")
mod.av_marker_template = mod:io_dofile(SCRIPTS .. "av_marker_template")
mod.av_tracker = mod:io_dofile(SCRIPTS .. "av_tracker")

local Template = mod.av_marker_template
local Tracker = mod.av_tracker

local PRESETS = {
	minimal = {
		mode_horde = "off",
		mode_elite = "wounded",
		mode_special = "always",
		mode_boss = "always",
		show_dots = false,
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
		show_health_number = mod:get("show_health_number") == true,
		show_name = mod:get("show_name") == true,
		line_of_sight = mod:get("line_of_sight") ~= false,
		prioritize_aim = mod:get("prioritize_aim") ~= false,
		max_distance = mod:get("max_distance") or 25,
		max_markers = mod:get("max_markers") or 20,
	}

	mod.cfg = cfg
	Template.apply_settings(cfg)
end

_read_settings()

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
end

mod.on_disabled = function ()
	Tracker.remove_all()
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

	templates[Template.name] = Template
	Tracker.attach(element)

	return true
end

mod:hook_safe("HudElementWorldMarkers", "init", function (self)
	_attach(self)
end)

mod:hook_safe("HudElementWorldMarkers", "update", function (self, dt)
	if Tracker.element() ~= self and not _attach(self) then
		return
	end

	Tracker.update(self, dt)
end)

mod:hook_safe("HudElementWorldMarkers", "destroy", function (self)
	Tracker.detach(self)
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
end
