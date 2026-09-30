-- Auspex Vitals: полосы здоровья и состояние врагов.
-- Заготовка: мод загружается и пишет в лог. Функциональность — см. docs/ideas.md.

local mod = get_mod("auspex_vitals")

mod.on_all_mods_loaded = function()
	mod:info("Auspex Vitals %s загружен", "0.1.0")
end
