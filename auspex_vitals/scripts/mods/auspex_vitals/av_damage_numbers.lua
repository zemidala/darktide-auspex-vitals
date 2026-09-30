-- Цифры урона игрока.
-- Источник — отчёты об атаках (AttackReportManager.add_attack_result): точный урон, крит, слабое место, тип атаки.
-- Рисуем пулом из POOL_SIZE маркеров по позиции: маркеры не создаются на каждое попадание,
-- а переиспользуются.
-- Стили (настройка damage_numbers_style):
--   floating      — у точки попадания, всплывают вверх (у добивающего удара юнит врага может не прийти);
--   column_right / column_left — столбцом сбоку от врага: новое число у врага, старые сдвигаются вверх;
--   screen_right / screen_left — одна лента сбоку от прицела, не привязана к врагам.

local mod = get_mod("auspex_vitals")
local Status = mod.av_status

local UIWidget = require("scripts/managers/ui/ui_widget")

local POOL_SIZE = 16
local DURATION = 1.1
local DURATION_COLUMN = 1.8 -- в столбце числа живут дольше: их читают как ленту
local ROW_SPACING = 1.1 -- высота строки столбца в размерах шрифта
local TEXT_BOX_WIDTH = 240
local TEXT_BOX_HEIGHT = 60
-- для ленты у прицела маркер держим в этой точке перед камерой, чтобы движок его рисовал
local SCREEN_ANCHOR_DISTANCE = 5

local STYLE_KINDS = {
	floating = "floating",
	column_right = "column",
	column_left = "column",
	screen_right = "screen",
	screen_left = "screen",
}
local RIGHT_STYLES = {
	column_right = true,
	screen_right = true,
}
local FADE_START = 0.6 -- доля времени жизни, после которой цифра гаснет
local RISE = 45 -- на сколько пикселей цифра поднимается за время жизни
local JITTER = 25 -- случайный сдвиг по горизонтали, чтобы цифры не слипались
-- попадания по одному врагу в пределах этого окна складываются в одно число
local MERGE_HIT = 0.12
local MERGE_DOT = 1
local FONT_TYPE = "proxima_nova_bold"
local FONT_SIZE = 24
local CRIT_FONT_SIZE = 30
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
		index = i,
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
				offset = { -TEXT_BOX_WIDTH * 0.5, -TEXT_BOX_HEIGHT * 0.5, 10 },
				size = { TEXT_BOX_WIDTH, TEXT_BOX_HEIGHT },
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

local function _head_position(unit)
	return Unit.world_position(unit, 1) + Vector3(0, 0, HEAD_HEIGHT)
end

-- Номер строки: сколько чисел новее этого — у того же врага (столбец) или вообще (лента у прицела).
local function _column_row(slot, any_unit)
	local row = 0

	for i = 1, POOL_SIZE do
		local other = _slots[i]

		if other ~= slot and other.active and (any_unit or other.anchor_unit ~= nil and other.anchor_unit == slot.anchor_unit) then
			if other.start_t > slot.start_t or (other.start_t == slot.start_t and other.index > slot.index) then
				row = row + 1
			end
		end
	end

	return row
end

template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
	local slot = marker.data.slot
	local content = widget.content

	if not slot.active then
		content.text = ""

		return
	end

	local cfg = mod.cfg
	local style_name = cfg and cfg.damage_numbers_style or "floating"
	local kind = STYLE_KINDS[style_name] or "floating"
	local is_column = kind ~= "floating"
	local duration = is_column and DURATION_COLUMN or DURATION
	local age = t - slot.start_t

	if age > duration then
		slot.active = false
		content.text = ""

		return
	end

	local progress = age / duration
	local scale = (cfg and cfg.damage_numbers_scale or 100) / 100
	local style = widget.style.text
	local color = _color_for(slot)
	local text_color = style.text_color
	local offset = style.offset

	text_color[2], text_color[3], text_color[4] = color[2], color[3], color[4]
	style.font_size = (slot.crit and CRIT_FONT_SIZE or FONT_SIZE) * scale

	if kind == "screen" then
		local camera = parent._player_camera

		if not camera then
			content.text = ""

			return
		end

		-- точка на оси взгляда проецируется в центр экрана: считаем её сами в этом кадре
		-- (так же, как движок в _calculate_markers), чтобы лента не дёргалась при повороте
		local anchor = Camera.local_position(camera) + Quaternion.forward(Camera.local_rotation(camera)) * SCREEN_ANCHOR_DISTANCE
		local x, y = parent:_convert_world_to_screen_position(camera, anchor)
		local screen_x, screen_y = parent:_get_screen_offset(ui_renderer.scale)
		local widget_offset = widget.offset

		widget_offset[1] = (x - screen_x) * ui_renderer.inverse_scale
		widget_offset[2] = (y - screen_y) * ui_renderer.inverse_scale
		marker.world_position:store(anchor)
	end

	if is_column then
		local unit = slot.anchor_unit

		-- столбец едет за врагом
		if kind == "column" and unit and ALIVE[unit] then
			marker.world_position:store(_head_position(unit))
		end

		local row = (kind == "screen" or unit) and _column_row(slot, kind == "screen") or 0
		local is_right = RIGHT_STYLES[style_name] == true
		-- отступ от центра врага или прицела — настройка, чтобы модель не закрывала цифры
		local gap = cfg.damage_numbers_column_offset or 120

		style.text_horizontal_alignment = is_right and "left" or "right"
		offset[1] = is_right and gap or -gap - TEXT_BOX_WIDTH
		offset[2] = -TEXT_BOX_HEIGHT * 0.5 - row * FONT_SIZE * scale * ROW_SPACING
	else
		style.text_horizontal_alignment = "center"
		offset[1] = -TEXT_BOX_WIDTH * 0.5 + slot.jitter * scale
		offset[2] = -TEXT_BOX_HEIGHT * 0.5 - progress * RISE * scale
	end

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
	slot.anchor_unit = unit and ALIVE[unit] and unit or nil

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
	local kind = STYLE_KINDS[cfg.damage_numbers_style] or "floating"
	local unit_alive = attacked_unit and ALIVE[attacked_unit]
	local camera = kind == "screen" and _element and _element._player_camera

	if camera then
		-- лента у прицела: позицию каждый кадр задаёт шаблон, здесь нужна любая видимая точка
		position = Camera.local_position(camera) + Quaternion.forward(Camera.local_rotation(camera)) * SCREEN_ANCHOR_DISTANCE
	elseif is_dot or kind == "column" or not position then
		-- у эффектов нет точки попадания; в столбце числа стоят у врага
		if unit_alive then
			position = _head_position(attacked_unit)
		elseif is_dot or not position then
			return
		end
	end

	_add(attacked_unit, position, damage, is_critical_strike == true, hit_weakspot == true, is_dot)
end

return DamageNumbers
