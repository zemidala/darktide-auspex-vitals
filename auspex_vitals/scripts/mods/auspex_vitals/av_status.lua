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
		profiles = { "warpfire" },
		flat = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_ember",
		templates = { "warp_fire" },
		icon = "content/ui/textures/icons/buffs/hud/psyker/psyker_ranged_shots_soulblaze",
		color = { 255, 170, 110, 255 },
	},
	{
		id = "burning",
		keywords = { "burning" },
		profiles = { "burn" },
		flat = "content/ui/materials/icons/presets/preset_20",
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
		profiles = { "shock", "stun", "chain_light", "electr" },
		flat = "content/ui/materials/icons/presets/preset_11",
		icon = "content/ui/textures/icons/buffs/hud/states_electric_buff_hud",
		color = { 255, 120, 200, 255 },
	},
	{
		id = "bleeding",
		keywords = { "bleeding" },
		profiles = { "bleed" },
		flat = "content/ui/materials/icons/presets/preset_13",
		templates = { "bleed", "bleed_long" },
		icon = "content/ui/textures/icons/buffs/hud/zealot/zealot_crits_apply_bleed",
		color = { 255, 220, 30, 30 },
	},
	{
		id = "toxin",
		keywords = { "toxin" },
		profiles = { "toxin" },
		flat = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_nurgle",
		templates = { "neurotoxin_interval_buff", "neurotoxin_interval_buff2", "neurotoxin_interval_buff3", "exploding_toxin_interval_buff" },
		icon = "content/ui/textures/icons/buffs/hud/states_toxic_cloud_buff_hud",
		color = { 255, 120, 220, 60 },
	},
}

-- Дебаффы: не шаблоны, а итоговые характеристики врага, на которые игра умножает урон и ошеломление
-- (damage_calculation.lua, stagger_calculation.lua). Так подхватываются любые таланты и благословения.
-- value = произведение stats - 1; показываем, если больше MIN_DEBUFF. Значки — из постоянного пакета
-- circumstances (havoc_*) или с проверкой загрузки; без значка — цветная метка.
local MIN_DEBUFF = 0.01

Status.DEBUFFS = {
	{
		id = "brittle", -- хрупкость брони
		stats = { "rending_multiplier" },
		flat = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_rotten_armor",
		color = { 255, 170, 200, 230 },
		plus = false,
	},
	{
		id = "vulnerable", -- получает больше урона от всего
		stats = { "damage_taken_multiplier", "damage_taken_modifier" },
		flat = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_skin",
		color = { 255, 255, 120, 170 },
		plus = true,
	},
	{
		id = "melee_vulnerable",
		stats = { "melee_damage_taken_multiplier", "melee_damage_taken_modifier" },
		flat = "content/ui/materials/icons/weapons/actions/melee",
		color = { 255, 255, 190, 120 },
		plus = true,
	},
	{
		id = "ranged_vulnerable",
		stats = { "ranged_damage_taken_multiplier" },
		flat = "content/ui/materials/icons/weapons/actions/hipfire",
		color = { 255, 150, 230, 255 },
		plus = true,
	},
	{
		id = "stagger", -- легче ошеломить
		stats = { "impact_modifier" },
		flat = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_rampaging_enemies",
		color = { 255, 240, 240, 140 },
		plus = true,
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

-- Материал иконок баффов игры (как в её панели баффов): картинка — material_values.talent_icon.
Status.ICON_MATERIAL = "content/ui/materials/icons/buffs/hud/buff_container_with_background"
Status.ICON_GRADIENT = "content/ui/textures/color_ramps/talent_default"

-- Как рисовать значок эффекта:
--   "flat", путь — плоский одноцветный значок-материал игры, красим в цвет эффекта (читается лучше всего;
--                  те же значки выбрали Healthbars, Enemies Improved и DivisionHUD);
--   "buff", путь — картинка баффа в материале панели баффов (запасной вариант);
--   nil          — ничего не загружено, рисуем цветную метку.
function Status.dot_visual(dot)
	if dot.flat and Status.resource_available("material", dot.flat) then
		return "flat", dot.flat
	end

	if dot.icon and Status.resource_available("material", Status.ICON_MATERIAL) and Status.resource_available("texture", dot.icon) then
		return "buff", dot.icon
	end

	return nil
end

-- Эффект по имени профиля урона тика (burning, phosphor_burning, warpfire, bleeding, toxin_variant_1,
-- cryptic_arc_shock_damage...). Сравниваем по подстроке: так переживём новые профили тех же эффектов.
-- Если подходят несколько, побеждает та подстрока, что стоит в имени раньше
-- (broker_toxin_stacks_stun_interval — токсин, а не электрошок).
local _dot_by_profile = {}

function Status.dot_by_damage_profile(damage_profile)
	local name = damage_profile and damage_profile.name

	if not name then
		return nil
	end

	local dot = _dot_by_profile[name]

	if dot == nil then
		dot = false

		local best_position

		for _, candidate in ipairs(Status.DOTS) do
			for _, pattern in ipairs(candidate.profiles or {}) do
				local position = string.find(name, pattern, 1, true)

				if position and (not best_position or position < best_position) then
					best_position = position
					dot = candidate
				end
			end
		end

		_dot_by_profile[name] = dot
	end

	return dot or nil
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

-- Босс ослаблен (заспавнен с уменьшенным здоровьем) или усилен: "weakened" | "empowered" | nil.
-- Усиление — строка-ключ приставки имени (как её использует полоса босса игры).
function Status.boss_state(unit)
	local boss_extension = ScriptUnit.has_extension(unit, "boss_system")

	if not boss_extension then
		return nil
	end

	local empowered = boss_extension.is_empowered and boss_extension:is_empowered()

	if empowered then
		return "empowered", empowered
	end

	if boss_extension.is_weakened and boss_extension:is_weakened() then
		return "weakened"
	end

	return nil
end

-- Имя как в полосе игры: у боссов — их титул (с приставкой «ослабленный»/«усиленный»), у остальных — порода.
function Status.display_name(unit)
	local boss_extension = ScriptUnit.has_extension(unit, "boss_system")
	local name = boss_extension and boss_extension.display_name and boss_extension:display_name()

	if not name then
		local breed = Status.breed(unit)

		name = breed and breed.display_name
	end

	if not name then
		return nil
	end

	local localized = Localize(name)
	local state, prefix_key = Status.boss_state(unit)
	local breed = Status.breed(unit)

	if state and not (breed and breed.ignore_weakened_boss_name) then
		local ok, prefixed = pcall(Localize, state == "weakened" and "loc_weakened_monster_prefix" or prefix_key, true, {
			breed = localized,
		})

		if ok and type(prefixed) == "string" then
			localized = prefixed
		end
	end

	return localized
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
			entry.label = nil
		end
	end

	return count
end

-- Дописывает дебаффы в out после count уже собранных записей; возвращает новое число записей.
-- entry.label — подпись вместо стаков: "40%" (хрупкость) или "+25%".
function Status.collect_debuffs(unit, out, count, max_count)
	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")
	local stat_buffs = buff_extension and buff_extension.stat_buffs and buff_extension:stat_buffs()

	if type(stat_buffs) ~= "table" then
		return count
	end

	for _, debuff in ipairs(Status.DEBUFFS) do
		if count >= max_count then
			break
		end

		local value = 1

		for _, stat in ipairs(debuff.stats) do
			local stat_value = stat_buffs[stat]

			if type(stat_value) == "number" then
				value = value * stat_value
			end
		end

		value = value - 1

		if value >= MIN_DEBUFF then
			count = count + 1

			local entry = out[count]

			entry.dot = debuff
			entry.stacks = 0
			entry.label = string.format(debuff.plus and "+%d%%" or "%d%%", math.floor(value * 100 + 0.5))
		end
	end

	return count
end

-- Есть ли на враге периодический урон (по ключевым словам эффектов).
function Status.has_dot(unit)
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

-- Раненый: потерял здоровье или горит/кровоточит.
function Status.is_wounded(unit, health_extension)
	return Status.health_fraction(health_extension) < 1 or Status.has_dot(unit)
end

return Status
