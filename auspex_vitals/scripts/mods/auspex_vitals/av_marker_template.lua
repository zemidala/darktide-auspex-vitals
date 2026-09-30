-- Шаблон маркера для HudElementWorldMarkers: тонкая полоса здоровья над врагом,
-- под ней до MAX_DOTS меток периодического урона со стаками.
-- Анимацию «призрачного» урона даёт HudHealthBarLogic из самой игры.

local mod = get_mod("auspex_vitals")
local Status = mod.av_status

local HudHealthBarLogic = require("scripts/ui/hud/elements/hud_health_bar_logic")
local UIWidget = require("scripts/managers/ui/ui_widget")

local MAX_DOTS = 3
local DOT_UPDATE_INTERVAL = 0.2
local BAR_HEIGHT = 7
-- запас для определения виджета: ширина полосы с учётом настройки масштаба не больше этой
local MAX_WIDTH = 400
local TICK_WIDTH = 2
local FONT_TYPE = "proxima_nova_bold"
local SMALL_FONT_SIZE = 14
local NUM_TICKS = 3 -- деления на 25, 50 и 75 %

-- ширина полосы при масштабе 100 %
local WIDTH_BY_CATEGORY = {
	horde = 100,
	elite = 140,
	special = 140,
	boss = 190,
}

local BAR_COLOR_BY_CATEGORY = {
	horde = { 255, 200, 40, 40 },
	elite = { 255, 230, 70, 40 },
	special = { 255, 230, 70, 40 },
	boss = { 255, 240, 110, 30 },
}

local template = {}

template.name = "auspex_vitals_bar"
template.unit_node = "j_head"
template.position_offset = { 0, 0, 0.45 }
template.check_line_of_sight = true
template.max_distance = 25
template.screen_clamp = false
template.bar_settings = {
	alpha_fade_delay = 2.6,
	alpha_fade_duration = 0.6,
	alpha_fade_min_value = 50,
	animate_on_health_increase = true,
	bar_spacing = 1,
	duration_health = 0.4,
	duration_health_ghost = 1.2,
	health_animation_threshold = 0.05,
}
template.fade_settings = {
	default_fade = 1,
	fade_from = 0,
	fade_to = 1,
	distance_max = 25,
	distance_min = 20,
	easing_function = math.ease_exp,
}

-- Дальность и проверка видимости — из настроек мода; шаблон клонируется при создании маркера.
function template.apply_settings(cfg)
	template.max_distance = cfg.max_distance
	template.check_line_of_sight = cfg.line_of_sight
	template.fade_settings.distance_max = cfg.max_distance
	template.fade_settings.distance_min = cfg.max_distance * 0.8
end

local function _rect(style_id, offset, size, color)
	return {
		pass_type = "rect",
		style_id = style_id,
		style = {
			offset = offset,
			size = size,
			color = color,
		},
	}
end

local function _text(style_id, offset, size, font_size, h_align, v_align)
	return {
		pass_type = "text",
		style_id = style_id,
		value_id = style_id,
		value = "",
		style = {
			offset = offset,
			size = size,
			font_type = FONT_TYPE,
			font_size = font_size,
			drop_shadow = true,
			text_horizontal_alignment = h_align,
			text_vertical_alignment = v_align,
			text_color = { 255, 255, 255, 255 },
		},
	}
end

-- Смещения задаются от точки маркера; ширину полосы и положение меток ставит update_function.
template.create_widget_defintion = function (template, scenegraph_id)
	local passes = {
		_rect("background", { 0, 0, 1 }, { MAX_WIDTH, BAR_HEIGHT }, { 160, 20, 20, 20 }),
		_rect("ghost_bar", { 0, 0, 2 }, { 0, BAR_HEIGHT }, { 255, 240, 200, 200 }),
		_rect("bar", { 0, 0, 3 }, { 0, BAR_HEIGHT }, { 255, 200, 40, 40 }),
		_rect("tick_1", { 0, 0, 5 }, { TICK_WIDTH, BAR_HEIGHT }, { 255, 0, 0, 0 }),
		_rect("tick_2", { 0, 0, 5 }, { TICK_WIDTH, BAR_HEIGHT }, { 255, 0, 0, 0 }),
		_rect("tick_3", { 0, 0, 5 }, { TICK_WIDTH, BAR_HEIGHT }, { 255, 0, 0, 0 }),
		_text("name_text", { -MAX_WIDTH, -22, 4 }, { MAX_WIDTH * 2, 20 }, SMALL_FONT_SIZE, "center", "bottom"),
		_text("health_text", { 0, BAR_HEIGHT * 0.5 - 10, 4 }, { 80, 20 }, SMALL_FONT_SIZE, "left", "center"),
	}

	for i = 1, MAX_DOTS do
		passes[#passes + 1] = _rect("dot_chip_" .. i, { 0, 0, 4 }, { 0, 6 }, { 255, 255, 255, 255 })
		passes[#passes + 1] = _text("dot_text_" .. i, { 0, 0, 4 }, { 30, 16 }, SMALL_FONT_SIZE, "left", "center")
	end

	return UIWidget.create_definition(passes, scenegraph_id)
end

template.on_enter = function (widget, marker, template)
	local data = marker.data or {}
	local category = data.category or "horde"

	marker.bar_logic = HudHealthBarLogic:new(template.bar_settings)
	local width_scale = (mod.cfg and mod.cfg.bar_width or 100) / 100

	marker.width = math.min(math.floor((WIDTH_BY_CATEGORY[category] or WIDTH_BY_CATEGORY.horde) * width_scale), MAX_WIDTH)
	marker.dots = {}
	marker.dot_count = 0
	marker.dot_timer = 0

	for i = 1, MAX_DOTS do
		marker.dots[i] = {}
	end

	local bar_color = BAR_COLOR_BY_CATEGORY[category] or BAR_COLOR_BY_CATEGORY.horde
	local color = widget.style.bar.color

	color[1], color[2], color[3], color[4] = bar_color[1], bar_color[2], bar_color[3], bar_color[4]

	local cfg = mod.cfg

	if cfg and cfg.show_name then
		widget.content.name_text = Status.display_name(marker.unit) or ""
	end
end

template.on_exit = function (widget, marker, template)
	local data = marker.data

	if data and data.on_exit then
		data.on_exit(marker.unit, marker.id)
	end
end

local function _layout_bar(style, width, health_fraction, ghost_fraction, spacing)
	local left = -width * 0.5
	local health_width = width * health_fraction
	local ghost_width = math.max(width * ghost_fraction - health_width, 0)
	local background_width = math.max(width - health_width - ghost_width - spacing, 0)

	style.bar.offset[1] = left
	style.bar.size[1] = health_width

	style.ghost_bar.offset[1] = left + health_width
	style.ghost_bar.size[1] = ghost_width

	style.background.offset[1] = left + width - background_width
	style.background.size[1] = background_width

	for i = 1, NUM_TICKS do
		style["tick_" .. i].offset[1] = math.floor(left + width * i / (NUM_TICKS + 1) - TICK_WIDTH * 0.5)
	end
end

local function _layout_dots(widget, marker, show)
	local style = widget.style
	local content = widget.content
	local left = -marker.width * 0.5
	local count = show and marker.dot_count or 0
	local x = left

	for i = 1, MAX_DOTS do
		local chip_id = "dot_chip_" .. i
		local text_id = "dot_text_" .. i
		local chip_style = style[chip_id]
		local text_style = style[text_id]

		if i <= count then
			local entry = marker.dots[i]
			local color = entry.dot.color
			local chip_color = chip_style.color

			chip_color[1], chip_color[2], chip_color[3], chip_color[4] = color[1], color[2], color[3], color[4]
			chip_style.size[1] = 6
			chip_style.offset[1] = x
			chip_style.offset[2] = BAR_HEIGHT + 4

			local text_color = text_style.text_color

			text_color[2], text_color[3], text_color[4] = color[2], color[3], color[4]
			text_style.offset[1] = x + 8
			text_style.offset[2] = BAR_HEIGHT + 4 - 5
			content[text_id] = entry.stacks > 0 and tostring(entry.stacks) or ""

			x = x + (entry.stacks > 9 and 30 or 22)
		else
			chip_style.size[1] = 0
			content[text_id] = ""
		end
	end
end

template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
	local unit = marker.unit
	local content = widget.content
	local style = widget.style
	local cfg = mod.cfg
	local health_extension = HEALTH_ALIVE[unit] and Status.health_extension(unit)
	local health_percent = health_extension and Status.health_fraction(health_extension) or 0
	local bar_logic = marker.bar_logic

	bar_logic:update(dt, t, health_percent)

	local health_fraction, ghost_fraction = bar_logic:animated_health_fractions()

	if health_fraction and ghost_fraction then
		_layout_bar(style, marker.width, health_fraction, ghost_fraction, template.bar_settings.bar_spacing)
		marker.health_fraction = health_fraction
	end

	-- полоса дошла до нуля после смерти — маркер больше не нужен
	if not HEALTH_ALIVE[unit] and (not marker.health_fraction or marker.health_fraction <= 0) then
		marker.remove = true

		return
	end

	if not marker.draw then
		return
	end

	local show_dots = cfg and cfg.show_dots

	if show_dots then
		marker.dot_timer = marker.dot_timer - dt

		if marker.dot_timer <= 0 then
			marker.dot_timer = DOT_UPDATE_INTERVAL
			marker.dot_count = HEALTH_ALIVE[unit] and Status.collect_dots(unit, marker.dots, MAX_DOTS) or 0
		end
	end

	_layout_dots(widget, marker, show_dots)

	if cfg and cfg.show_health_number and health_extension then
		local health = Status.current_health(health_extension)

		style.health_text.offset[1] = marker.width * 0.5 + 4
		content.health_text = health and string.format("%d", math.ceil(health)) or ""
	else
		content.health_text = ""
	end

	-- плавное появление/скрытие по проверке видимости, как у полос игры
	local visibility = content.line_of_sight_progress or (template.check_line_of_sight and 0 or 1)

	if template.check_line_of_sight and marker.raycast_initialized then
		local speed = 3

		if marker.raycast_result then
			visibility = math.max(visibility - dt * speed, 0)
		else
			visibility = math.min(visibility + dt * speed, 1)
		end
	elseif not template.check_line_of_sight then
		visibility = 1
	end

	content.line_of_sight_progress = visibility
	widget.alpha_multiplier = visibility
end

return template
