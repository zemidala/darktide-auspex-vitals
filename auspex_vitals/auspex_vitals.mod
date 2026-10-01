return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`auspex_vitals` encountered an error loading the Darktide Mod Framework.")

		new_mod("auspex_vitals", {
			mod_script       = "auspex_vitals/scripts/mods/auspex_vitals/auspex_vitals",
			mod_data         = "auspex_vitals/scripts/mods/auspex_vitals/auspex_vitals_data",
			mod_localization = "auspex_vitals/scripts/mods/auspex_vitals/auspex_vitals_localization",
		})
	end,
	packages = {},
	version = "0.2.0",
	-- AML: после DMF
	load_after = { "dmf" },
}
