-- Чтение состояния врага: категория, здоровье, периодический урон.
-- Всё через проверки: после патча метод или шаблон может пропасть — тогда просто нет данных.

local mod = get_mod("auspex_vitals")

local Status = {}

-- Порядок = приоритет показа. keywords — ключевые слова баффа (эффект есть, если есть любое),
-- templates — шаблоны со стаками (у электрошока стаков нет: только ключевые слова).
-- Имена сверены с weapon_buff_templates.lua (игра 1.13.0).
Status.DOTS = {
	{
		id = "warpfire",
		keywords = { "warpfire_burning" },
		templates = { "warp_fire" },
		icon = "content/ui/textures/icons/buffs/hud/psyker/psyker_ranged_shots_soulblaze",
		color = { 255, 170, 110, 255 },
	},
	{
		id = "burning",
		keywords = { "burning" },
		templates = { "flamer_assault", "phosphor_burn" },
		icon = "content/ui/textures/icons/buffs/hud/states_fire_buff_hud",
		color = { 255, 255, 140, 30 },
	},
	{
		-- электрошок (Скитарий, дуговые гранаты, шоковые молоты, цепная молния): не стакается
		id = "electrocuted",
		keywords = {
			"electrocuted",
			"electrocuted_arc",
			"electrocuted_arc_ability",
			"electrocuted_arc_grenade",
			"electrocuted_chain_lightning",
			"electrocuted_shock_mine",
		},
		templates = {},
		icon = "content/ui/textures/icons/buffs/hud/states_electric_buff_hud",
		color = { 255, 120, 200, 255 },
	},
	{
		id = "bleeding",
		keywords = { "bleeding" },
		templates = { "bleed", "bleed_long" },
		icon = "content/ui/textures/icons/buffs/hud/zealot/zealot_crits_apply_bleed",
		color = { 255, 220, 30, 30 },
	},
	{
		id = "toxin",
		keywords = { "toxin" },
		templates = { "neurotoxin_interval_buff", "neurotoxin_interval_buff2", "neurotoxin_interval_buff3", "exploding_toxin_interval_buff" },
		icon = "content/ui/textures/icons/buffs/hud/states_toxic_cloud_buff_hud",
		color = { 255, 120, 220, 60 },
	},
}

-- Загружен ли ресурс сейчас. Иконки и материалы берём из пакетов игры, которые мы не грузим сами:
-- рисовать незагруженную текстуру нельзя, поэтому без неё показываем цветную метку.
local _resource_cache = {}

function Status.resource_available(resource_type, path)
	local key = resource_type .. ":" .. path
	local available = _resource_cache[key]

	if available == nil then
		local ok, result = pcall(Application.can_get_resource, resource_type, path)

		available = ok and result == true
		_resource_cache[key] = available

		if not available then
			mod:info("%s not loaded, fallback used: %s", resource_type, path)
		end
	end

	return available
end

-- набор загруженных пакетов меняется между хабом и миссией
function Status.reset_resource_cache()
	table.clear(_resource_cache)
end

local BOSS_TAGS = { "monster", "captain", "cultist_captain", "lord" }

-- Оставить только шаблоны, которые есть в текущей версии игры.
local function _filter_templates()
	local ok, BuffTemplates = pcall(require, "scripts/settings/buff/buff_templates")

	if not ok or type(BuffTemplates) ~= "table" then
		mod:warning("BuffTemplates not found: stack counts disabled")

		for _, dot in ipairs(Status.DOTS) do
			dot.templates = {}
		end

		return
	end

	for _, dot in ipairs(Status.DOTS) do
		local present = {}

		for _, name in ipairs(dot.templates) do
			if rawget(BuffTemplates, name) then
				present[#present + 1] = name
			else
				mod:info("buff template '%s' not found, skipped", name)
			end
		end

		dot.templates = present
	end
end

_filter_templates()

local _breed_cache = setmetatable({}, { __mode = "k" })

function Status.breed(unit)
	local breed = _breed_cache[unit]

	if breed == nil then
		local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")

		breed = unit_data and unit_data.breed and unit_data:breed() or false
		_breed_cache[unit] = breed
	end

	return breed or nil
end

-- "boss" | "special" | "elite" | "horde" | nil
function Status.category(unit)
	local breed = Status.breed(unit)
	local tags = breed and breed.tags

	if not tags then
		return nil
	end

	for i = 1, #BOSS_TAGS do
		if tags[BOSS_TAGS[i]] then
			return "boss"
		end
	end

	if tags.special then
		return "special"
	elseif tags.elite then
		return "elite"
	end

	return "horde"
end

-- Имя как в полосе игры: у боссов — их титул, у остальных — название породы.
function Status.display_name(unit)
	local boss_extension = ScriptUnit.has_extension(unit, "boss_system")
	local name = boss_extension and boss_extension.display_name and boss_extension:display_name()

	if not name then
		local breed = Status.breed(unit)

		name = breed and breed.display_name
	end

	return name and Localize(name) or nil
end

function Status.health_extension(unit)
	return ScriptUnit.has_extension(unit, "health_system")
end

function Status.health_fraction(health_extension)
	if not health_extension or not health_extension.current_health_percent then
		return 1
	end

	return health_extension:current_health_percent() or 1
end

function Status.current_health(health_extension)
	if not health_extension or not health_extension.current_health then
		return nil
	end

	return health_extension:current_health()
end

local function _has_keyword(buff_extension, keywords)
	if buff_extension.has_keyword == nil then
		return false
	end

	for i = 1, #keywords do
		if buff_extension:has_keyword(keywords[i]) then
			return true
		end
	end

	return false
end

-- Пишет в out[i] = { dot, stacks } и возвращает число записей (не больше max_count).
-- stacks = 0 — эффект есть по ключевому слову, но число стаков неизвестно (например, огонь от луж).
function Status.collect_dots(unit, out, max_count)
	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	if not buff_extension then
		return 0
	end

	local has_stacks = buff_extension.current_stacks ~= nil
	local count = 0
	local has_warpfire = false

	for _, dot in ipairs(Status.DOTS) do
		if count >= max_count then
			break
		end

		local stacks = 0

		if has_stacks then
			for _, name in ipairs(dot.templates) do
				stacks = stacks + buff_extension:current_stacks(name)
			end
		end

		local shown = stacks > 0

		-- варп-огонь тоже несёт ключевое слово burning: без своих стаков горение не показываем
		if not shown and _has_keyword(buff_extension, dot.keywords) then
			shown = not (dot.id == "burning" and has_warpfire)
		end

		if shown then
			if dot.id == "warpfire" then
				has_warpfire = true
			end

			count = count + 1

			local entry = out[count]

			entry.dot = dot
			entry.stacks = stacks
		end
	end

	return count
end

-- Раненый: потерял здоровье или горит/кровоточит.
function Status.is_wounded(unit, health_extension)
	if Status.health_fraction(health_extension) < 1 then
		return true
	end

	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	if buff_extension then
		for _, dot in ipairs(Status.DOTS) do
			if _has_keyword(buff_extension, dot.keywords) then
				return true
			end
		end
	end

	return false
end

return Status
