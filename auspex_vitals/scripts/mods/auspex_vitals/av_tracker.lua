-- Планировщик маркеров: раз в SELECT_INTERVAL выбирает до max_markers ближайших подходящих врагов
-- (с поправкой на угол от центра экрана, если включено),
-- новым ставит маркер, выбывшим снимает. Так виджеты есть только у K врагов, а не у всей орды.

local mod = get_mod("auspex_vitals")
local Status = mod.av_status
local Template = mod.av_marker_template

local SELECT_INTERVAL = 0.15
-- уже отмеченный враг считается чуть ближе, чтобы полосы не мигали на границе отбора
local KEEP_BONUS = 0.8
-- приоритет по прицелу: враг на краю экрана «дальше» центрального в (1 + AIM_WEIGHT * (1 - cos угла)) раз
local AIM_WEIGHT = 1.5
-- направление берём на грудь врага, а не на ноги
local AIM_HEIGHT = 1

local Tracker = {}

-- режим "recent": когда враг последний раз терял здоровье (по своим часам планировщика)
local _clock = 0
local _last_health = {} -- unit -> доля здоровья на прошлой проверке
local _last_hit = {} -- unit -> _clock последнего урона

local _element = nil
local _markers = {} -- unit -> marker id
local _timer = 0

local _candidates = {}
local _distances = {} -- unit -> оценка для сортировки (квадрат расстояния с поправками)
local _wanted = {}

local function _sort_by_distance(a, b)
	return _distances[a] < _distances[b]
end

local function _on_marker_exit(unit, id)
	if _markers[unit] == id then
		_markers[unit] = nil
	end
end

local function _add_marker(element, unit, category)
	local data = {
		category = category,
		on_exit = _on_marker_exit,
	}

	element:event_add_world_marker_unit(Template.name, unit, function (id)
		_markers[unit] = id
	end, data)
end

local function _remove_marker(element, unit)
	local id = _markers[unit]

	_markers[unit] = nil

	if id then
		element:event_remove_world_marker(id)
	end
end

function Tracker.element()
	return _element
end

function Tracker.attach(element)
	_element = element
	_timer = 0
	table.clear(_markers)
end

function Tracker.detach(element)
	if _element == element then
		_element = nil
		table.clear(_markers)
		table.clear(_last_health)
		table.clear(_last_hit)
	end
end

function Tracker.remove_all()
	local element = _element

	if not element then
		table.clear(_markers)

		return
	end

	for unit in pairs(_markers) do
		_remove_marker(element, unit)
	end
end

local function _enemy_minions(player_unit)
	local extension_manager = Managers.state and Managers.state.extension
	local side_system = extension_manager and extension_manager:has_system("side_system") and extension_manager:system("side_system")
	local side = side_system and side_system.side_by_unit and side_system.side_by_unit[player_unit]

	return side and side.alive_units_by_tag and side:alive_units_by_tag("enemy", "minion")
end

-- Недавно раненый: терял здоровье за последние recent_seconds или горит/кровоточит сейчас.
local function _is_recent(unit, cfg)
	local fraction = Status.health_fraction(Status.health_extension(unit))
	local previous = _last_health[unit]

	if previous and fraction < previous - 0.0001 then
		_last_hit[unit] = _clock
	end

	_last_health[unit] = fraction

	local last_hit = _last_hit[unit]

	return last_hit and _clock - last_hit <= (cfg.recent_seconds or 10) or Status.has_dot(unit)
end

local function _forget_dead()
	for unit in pairs(_last_health) do
		if not HEALTH_ALIVE[unit] then
			_last_health[unit] = nil
			_last_hit[unit] = nil
		end
	end
end

-- Система меток (пинги отряда); nil, если её нет или метод пропал после патча.
local function _smart_tag_system()
	local extension_manager = Managers.state and Managers.state.extension
	local system = extension_manager and extension_manager:has_system("smart_tag_system") and extension_manager:system("smart_tag_system")

	return system and system.is_unit_tagged and system or nil
end

local function _select(element, cfg)
	local player = element._parent and element._parent:player()
	local player_unit = player and player.player_unit

	if not player_unit or not ALIVE[player_unit] then
		return
	end

	local units = _enemy_minions(player_unit)

	if not units then
		return
	end

	local origin = POSITION_LOOKUP[player_unit] or Unit.world_position(player_unit, 1)
	local camera = cfg.prioritize_aim and element._player_camera
	local camera_position = camera and Camera.local_position(camera)
	local camera_forward = camera and Quaternion.forward(Camera.local_rotation(camera))
	local aim_offset = Vector3(0, 0, AIM_HEIGHT)
	local max_distance_sq = cfg.max_distance * cfg.max_distance
	local modes = cfg.modes
	local num_candidates = 0
	local smart_tags = _smart_tag_system()

	for i = 1, units.size or 0 do
		local unit = units[i]

		if HEALTH_ALIVE[unit] then
			local position = POSITION_LOOKUP[unit]
			local distance_sq = position and Vector3.distance_squared(origin, position)

			if distance_sq and distance_sq <= max_distance_sq then
				local category = Status.category(unit)
				local mode = category and modes[category]
				local accepted = mode == "always"

				if mode == "wounded" then
					accepted = Status.is_wounded(unit, Status.health_extension(unit))
				elseif mode == "recent" then
					accepted = _is_recent(unit, cfg)
				elseif mode == "tagged" then
					accepted = smart_tags ~= nil and smart_tags:is_unit_tagged(unit) == true
				end

				if accepted then
					if camera then
						local to_unit = position + aim_offset - camera_position
						local length = Vector3.length(to_unit)
						local cos_angle = length > 0 and Vector3.dot(camera_forward, to_unit) / length or 1
						local factor = 1 + AIM_WEIGHT * (1 - cos_angle)

						distance_sq = distance_sq * factor * factor
					end

					if _markers[unit] then
						distance_sq = distance_sq * KEEP_BONUS
					end

					num_candidates = num_candidates + 1
					_candidates[num_candidates] = unit
					_distances[unit] = distance_sq
				end
			end
		end
	end

	for i = num_candidates + 1, #_candidates do
		_candidates[i] = nil
	end

	table.sort(_candidates, _sort_by_distance)

	local limit = math.min(num_candidates, cfg.max_markers)

	for i = 1, limit do
		_wanted[_candidates[i]] = true
	end

	-- снять выбывших; умершим не мешаем: шаблон сам уберёт маркер, когда полоса догорит
	for unit in pairs(_markers) do
		if not _wanted[unit] and HEALTH_ALIVE[unit] then
			_remove_marker(element, unit)
		end
	end

	for i = 1, limit do
		local unit = _candidates[i]

		if not _markers[unit] then
			_add_marker(element, unit, Status.category(unit))
		end
	end

	table.clear(_wanted)
	table.clear(_candidates)
	table.clear(_distances)
end

function Tracker.update(element, dt)
	if element ~= _element then
		return
	end

	_timer = _timer - dt
	_clock = _clock + dt

	if _timer > 0 then
		return
	end

	_timer = SELECT_INTERVAL

	local cfg = mod.cfg

	if not cfg or not mod:is_enabled() then
		return
	end

	_select(element, cfg)
	_forget_dead()
end

return Tracker
