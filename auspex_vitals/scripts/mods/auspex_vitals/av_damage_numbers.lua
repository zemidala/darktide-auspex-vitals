-- Цифры урона игрока.
-- Источник — отчёты об атаках (AttackReportManager.add_attack_result): точный урон, крит, слабое место, тип атаки.
-- Рисуем пулом из POOL_SIZE маркеров по позиции: маркеры не создаются на каждое попадание,
-- а переиспользуются. Цифры привязаны к точке попадания: у добивающего удара юнит врага может не прийти.

local mod = get_mod("auspex_vitals")
local Status = mod.av_status

local UIWidget = require("scripts/managers/ui/ui_widget")

local POOL_SIZE = 16
local DURATION = 1.1
local FADE_START = 0.6 -- доля времени жизни, после которой цифра гаснет
local RISE = 45 -- на сколько пикселей цифра поднимается за время жизни
local JITTER = 25 -- случайный сдвиг по горизонтали, чтобы цифры не слипались
-- попадания по одному врагу в пределах этого окна складываются в одно число
local MERGE_HIT = 0.12
local MERGE_DOT = 1
local FONT_TYPE = "proxima_nova_bold"
local FONT_SIZE = 20
local CRIT_FONT_SIZE = 26
local HEAD_HEIGHT = 1.6

local COLOR_NORMAL = { 255, 255, 255, 255 }
local COLOR_WEAKSPOT = { 255, 255, 220, 60 }
local COLOR_CRIT = { 255, 255, 140, 30 }
local COLOR_DOT = { 255, 200, 160, 120 }

local DamageNumbers = {}

DamageNumbers.now = 0

local _element = nil
local _slots = {}

for i = 1, POOL_SIZE do
	_slots[i] = {
		active = false,
	}
end

-- Шаблон маркера одной цифры --------------------------------------------------------------

local template = {}

template.name = "auspex_vitals_damage_number"
template.max_distance = 100
template.check_line_of_sight = false
template.screen_clamp = false

template.create_widget_defintion = function (template, scenegraph_id)
	return UIWidget.create_definition({
		{
			pass_type = "text",
			style_id = "text",
			value_id = "text",
			value = "",
			style = {
				offset = { -100, -20, 10 },
				size = { 200, 40 },
				font_type = FONT_TYPE,
				font_size = FONT_SIZE,
				drop_shadow = true,
				text_horizontal_alignment = "center",
				text_vertical_alignment = "center",
				text_color = { 255, 255, 255, 255 },
			},
		},
	}, scenegraph_id)
end

template.on_enter = function (widget, marker, template)
	marker.data.slot.marker = marker
end

template.on_exit = function (widget, marker, template)
	local slot = marker.data.slot

	slot.marker = nil
	slot.active = false
end

local function _color_for(slot)
	if slot.is_dot then
		return COLOR_DOT
	elseif slot.crit then
		return COLOR_CRIT
	elseif slot.weakspot then
		return COLOR_WEAKSPOT
	end

	return COLOR_NORMAL
end

template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
	local slot = marker.data.slot
	local content = widget.content

	if not slot.active then
		content.text = ""

		return
	end

	local age = t - slot.start_t

	if age > DURATION then
		slot.active = false
		content.text = ""

		return
	end

	local progress = age / DURATION
	local style = widget.style.text
	local color = _color_for(slot)
	local text_color = style.text_color

	text_color[2], text_color[3], text_color[4] = color[2], color[3], color[4]
	style.font_size = slot.crit and CRIT_FONT_SIZE or FONT_SIZE
	style.offset[1] = -100 + slot.jitter
	style.offset[2] = -20 - progress * RISE
	content.text = string.format("%d", math.floor(slot.value + 0.5))
	widget.alpha_multiplier = progress < FADE_START and 1 or 1 - (progress - FADE_START) / (1 - FADE_START)
end

DamageNumbers.template = template

-- Пул ---------------------------------------------------------------------------------

function DamageNumbers.attach(element)
	_element = element

	for i = 1, POOL_SIZE do
		local slot = _slots[i]

		slot.marker = nil
		slot.active = false
	end
end

function DamageNumbers.detach(element)
	if _element == element then
		_element = nil
	end
end

function DamageNumbers.clear()
	for i = 1, POOL_SIZE do
		_slots[i].active = false
	end
end

local function _find_slot(unit, is_dot, now)
	local merge_window = is_dot and MERGE_DOT or MERGE_HIT
	local free, oldest

	for i = 1, POOL_SIZE do
		local slot = _slots[i]

		if slot.active then
			if unit and slot.unit == unit and slot.is_dot == is_dot and now - slot.last_t <= merge_window then
				return slot, true
			end

			if not oldest or slot.start_t < oldest.start_t then
				oldest = slot
			end
		elseif not free or (slot.marker and not free.marker) then
			-- свободный слот с готовым маркером лучше, чем без маркера
			free = slot
		end
	end

	return free or oldest, false
end

local function _add(unit, position, damage, is_crit, is_weakspot, is_dot)
	local element = _element

	if not element then
		return
	end

	local now = DamageNumbers.now
	local slot, merged = _find_slot(unit, is_dot, now)

	if merged then
		slot.value = slot.value + damage
		slot.crit = slot.crit or is_crit
		slot.weakspot = slot.weakspot or is_weakspot
		slot.last_t = now

		if is_dot then
			slot.start_t = now
		end

		return
	end

	slot.active = true
	slot.unit = unit
	slot.is_dot = is_dot
	slot.value = damage
	slot.crit = is_crit
	slot.weakspot = is_weakspot
	slot.start_t = now
	slot.last_t = now
	slot.jitter = (math.random() * 2 - 1) * JITTER

	if slot.marker then
		slot.marker.world_position:store(position)
	else
		element:event_add_world_marker_position(template.name, position, nil, {
			slot = slot,
		})
	end
end

local function _local_player_unit()
	local player = Managers.player and Managers.player:local_player(1)

	return player and player.player_unit
end

-- Вызывается из хука AttackReportManager.add_attack_result.
function DamageNumbers.on_attack_result(attacked_unit, attacking_unit, hit_world_position, hit_weakspot, damage, attack_type, is_critical_strike)
	local cfg = mod.cfg

	if not cfg or not cfg.show_damage_numbers or not damage or damage <= 0 then
		return
	end

	if not attacking_unit or attacking_unit ~= _local_player_unit() then
		return
	end

	local is_dot = attack_type == "buff"

	if is_dot and not cfg.damage_numbers_dots then
		return
	end

	if attacked_unit then
		local breed = Status.breed(attacked_unit)

		-- только враги-миньоны: не игроки и не предметы уровня
		if not breed or breed.breed_type ~= "minion" then
			return
		end
	end

	local position = hit_world_position

	if not position or is_dot then
		if not attacked_unit or not ALIVE[attacked_unit] then
			return
		end

		position = Unit.world_position(attacked_unit, 1) + Vector3(0, 0, HEAD_HEIGHT)
	end

	_add(attacked_unit, position, damage, is_critical_strike == true, hit_weakspot == true, is_dot)
end

return DamageNumbers
