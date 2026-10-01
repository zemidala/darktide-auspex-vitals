-- Шаблон маркера для HudElementWorldMarkers: здоровье врага (полоса или сфера) и до MAX_DOTS
-- меток периодического урона со стаками. Анимацию «призрачного» урона даёт HudHealthBarLogic из игры.
--
-- Раскладка каждый кадр, всё строится ВВЕРХ от точки маркера (она над головой врага), чтобы ничего
-- не закрывало модель: внизу фигура или полоса, над ней строка эффектов, сверху имя; число здоровья —
-- справа от фигуры. Все размеры умножаются на масштаб по расстоянию (_distance_scale).

local mod = get_mod("auspex_vitals")
local Status = mod.av_status

local HudHealthBarLogic = require("scripts/ui/hud/elements/hud_health_bar_logic")
local UIWidget = require("scripts/managers/ui/ui_widget")

local MAX_DOTS = 3
-- иконки периодического урона рисуем материалом иконок баффов игры (как в её панели баффов)
local ICON_MATERIAL = Status.ICON_MATERIAL
local ICON_GRADIENT = Status.ICON_GRADIENT
local ICON_SIZE = 18
local DOT_UPDATE_INTERVAL = 0.2
local BAR_HEIGHT = 7
-- запас для определения виджета: ширина полосы с учётом настройки масштаба не больше этой
local MAX_WIDTH = 400
local TICK_WIDTH = 2
local FONT_TYPE = "proxima_nova_bold"
local SMALL_FONT_SIZE = 14
local MIN_FONT_SIZE = 9
local GAP = 3 -- зазор между строками раскладки, пикселей при масштабе 1
local TEXT_BOX_HEIGHT = 20
local DOT_TEXT_WIDTH = 30

-- Масштаб по расстоянию: полный до SCALE_NEAR метров, дальше линейно до SCALE_FAR_MIN на пределе дальности.
local SCALE_NEAR = 6
local SCALE_FAR_MIN = 0.55

-- Видимость — своими лучами от камеры к маркеру, раз в OCCLUSION_INTERVAL:
--   стены — фильтр статики стрельбы игрока (только неподвижная геометрия): полоса скрывается;
--   другие враги — фильтр динамики стрельбы (тела): полоса гаснет до OCCLUDED_ALPHA.
-- Проверку движка (check_line_of_sight) не используем: она считает помехой всё, что не сам юнит врага,
-- в том числе его оружие и броню — вплотную полоса гасла без причины.
local WALL_FILTER = "filter_player_character_shooting_raycast_statics"
local OCCLUSION_FILTER = "filter_player_character_shooting_raycast_dynamics"
local VISIBILITY_SPEED = 3
-- ВРЕМЕННО: диагностика видимости в лог (что закрывает маркер), не чаще раза в DEBUG_INTERVAL на маркер
local DEBUG_VISIBILITY = true
local DEBUG_INTERVAL = 2
local OCCLUSION_INTERVAL = 0.15
local OCCLUSION_MARGIN = 0.3 -- метров до полосы, где попадание уже не считается перекрытием
local OCCLUSION_START = 1 -- луч начинается перед камерой, чтобы не задеть своего персонажа
local OCCLUSION_MAX_HITS = 16
local HIT_INDEX_ACTOR = 4 -- формат результата PhysicsWorld.raycast "all", как в hit_scan.lua
local OCCLUDED_ALPHA = 0.1
local OCCLUSION_SPEED = 6
local HEAD_NODE = "j_head"
local HEAD_MARGIN = 0.3 -- метров над костью головы
local DEFAULT_BASE_HEIGHT = 2
local NUM_TICKS = 3 -- деления на 25, 50 и 75 %

-- Сфера (bar_style = "sphere"): залитый круг игры (материал сканера), здоровье налито снизу вверх, как
-- жидкость. Уровень — обрезка по UV (проход texture_uv), поэтому край круга гладкий. Контур — круг колеса
-- команд, если загружен. Делений нет: на маленьком круге они выглядят как штриховка.
local SPHERE_MATERIAL = "content/ui/materials/backgrounds/scanner/scanner_drill_circle_filled"
local SPHERE_RIM_MATERIAL = "content/ui/materials/hud/communication_wheel/middle_circle"
local SPHERE_BACKGROUND_COLOR = { 170, 25, 25, 25 }
local SPHERE_GHOST_COLOR = { 230, 240, 200, 200 }
local SPHERE_RIM_COLOR = { 220, 0, 0, 0 }
-- диаметр при масштабе 100 %
local SPHERE_BY_CATEGORY = {
	horde = 22,
	elite = 30,
	special = 30,
	boss = 40,
}
local SHAPE_MAX_DIAMETER = 160

-- доля диаметра под значок эффекта в центре фигуры; значок белый с тёмной обводкой, чтобы не сливался
-- с заливкой сферы того же цвета (цвет эффекта остаётся у числа стаков)
local CENTER_ICON_FRACTION = 0.55
local CENTER_ICON_COLOR = { 255, 255, 255, 255 }
local CENTER_SHADOW_COLOR = { 220, 0, 0, 0 }
local CENTER_SHADOW_GROW = 3 -- на сколько пикселей обводка больше значка

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
-- Высота точки маркера считается каждый кадр в _update_anchor: от корня юнита (node 1) до большего из
-- «голова + HEAD_MARGIN» и «рост породы × размер врага», плюс сдвиг из настроек.
-- Шаблон клонируется на каждый маркер, поэтому position_offset у каждого свой.
template.unit_node = nil
template.position_offset = { 0, 0, 2 }
template.check_line_of_sight = false
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
	template.fade_settings.distance_max = cfg.max_distance
	template.fade_settings.distance_min = cfg.max_distance * 0.8
end

local function _rect(style_id, color)
	return {
		pass_type = "rect",
		style_id = style_id,
		style = {
			offset = { 0, 0, 3 },
			size = { 0, 0 },
			color = color,
		},
	}
end

local function _text(style_id, width, h_align, v_align)
	return {
		pass_type = "text",
		style_id = style_id,
		value_id = style_id,
		value = "",
		style = {
			offset = { 0, 0, 6 },
			size = { width, TEXT_BOX_HEIGHT },
			font_type = FONT_TYPE,
			font_size = SMALL_FONT_SIZE,
			drop_shadow = true,
			text_horizontal_alignment = h_align,
			text_vertical_alignment = v_align,
			text_color = { 255, 255, 255, 255 },
		},
	}
end

local function _texture(style_id, material, pass_type, z)
	return {
		pass_type = pass_type or "texture",
		style_id = style_id,
		value = material,
		style = {
			offset = { 0, 0, z or 3 },
			size = { 0, 0 },
			color = { 255, 255, 255, 255 },
			uvs = pass_type == "texture_uv" and {
				{ 0, 0 },
				{ 1, 1 },
			} or nil,
		},
	}
end

-- Вид фигуры для этого маркера: выбранный в настройках, если его материал загружен, иначе полоса.
local function _shape_kind()
	local style = mod.cfg and mod.cfg.bar_style or "bar"

	if style == "sphere" and Status.resource_available("material", SPHERE_MATERIAL) then
		return "sphere"
	end

	return "bar"
end

-- Проходы создаются только для выбранного вида: маркеры пересоздаются при смене настроек.
template.create_widget_defintion = function (template, scenegraph_id)
	local kind = _shape_kind()
	local passes = {
		_text("name_text", MAX_WIDTH * 2, "center", "bottom"),
		_text("health_text", 80, "left", "center"),
	}

	if kind == "bar" then
		passes[#passes + 1] = _rect("background", { 160, 20, 20, 20 })
		passes[#passes + 1] = _rect("ghost_bar", { 255, 240, 200, 200 })
		passes[#passes + 1] = _rect("bar", { 255, 200, 40, 40 })

		for i = 1, NUM_TICKS do
			local tick = _rect("tick_" .. i, { 255, 0, 0, 0 })

			tick.style.offset[3] = 5
			passes[#passes + 1] = tick
		end
	elseif kind == "sphere" then
		local background = _texture("sphere_background", SPHERE_MATERIAL, "texture", 1)

		background.style.color = table.clone(SPHERE_BACKGROUND_COLOR)
		passes[#passes + 1] = background
		passes[#passes + 1] = _texture("sphere_ghost", SPHERE_MATERIAL, "texture_uv", 2)
		passes[#passes + 1] = _texture("sphere_fill", SPHERE_MATERIAL, "texture_uv", 3)

		if Status.resource_available("material", SPHERE_RIM_MATERIAL) then
			local rim = _texture("sphere_rim", SPHERE_RIM_MATERIAL, "texture", 4)

			rim.style.color = table.clone(SPHERE_RIM_COLOR)
			passes[#passes + 1] = rim
		end
	end

	-- обводка значка главного эффекта в центре сферы: тот же плоский материал, чёрный и чуть крупнее
	if kind == "sphere" and mod.cfg and mod.cfg.dot_center then
		passes[#passes + 1] = {
			pass_type = "texture",
			style_id = "center_shadow",
			value_id = "center_shadow",
			style = {
				offset = { 0, 0, 5 },
				size = { 0, 0 },
				color = table.clone(CENTER_SHADOW_COLOR),
			},
			visibility_function = function (content, style)
				return content.center_shadow_on == true
			end,
		}
	end

	local icons_available = Status.resource_available("material", ICON_MATERIAL)

	for i = 1, MAX_DOTS do
		local flat_id = "dot_flat_" .. i
		local chip = _rect("dot_chip_" .. i, { 255, 255, 255, 255 })

		chip.style.offset[3] = 5
		passes[#passes + 1] = chip
		passes[#passes + 1] = _text("dot_text_" .. i, DOT_TEXT_WIDTH, "left", "center")
		-- плоский значок: материал задаётся через content[flat_id], цвет — цвет эффекта
		passes[#passes + 1] = {
			pass_type = "texture",
			style_id = flat_id,
			value_id = flat_id,
			style = {
				offset = { 0, 0, 6 },
				size = { ICON_SIZE, ICON_SIZE },
				color = { 255, 255, 255, 255 },
			},
			visibility_function = function (content, style)
				return content[flat_id .. "_on"] == true
			end,
		}

		if icons_available then
			local visible_id = "dot_icon_visible_" .. i

			passes[#passes + 1] = {
				pass_type = "texture",
				style_id = "dot_icon_" .. i,
				value = ICON_MATERIAL,
				style = {
					offset = { 0, 0, 5 },
					size = { ICON_SIZE, ICON_SIZE },
					color = { 255, 255, 255, 255 },
					material_values = {
						opacity = 1,
						progress = 1,
					},
				},
				visibility_function = function (content, style)
					return content[visible_id] == true
				end,
			}
		end
	end

	return UIWidget.create_definition(passes, scenegraph_id)
end

template.on_enter = function (widget, marker, template)
	local data = marker.data or {}
	local category = data.category or "horde"
	local style = widget.style
	local cfg = mod.cfg

	marker.bar_logic = HudHealthBarLogic:new(template.bar_settings)

	local unit = marker.unit

	marker.head_node = Unit.has_node(unit, HEAD_NODE) and Unit.node(unit, HEAD_NODE) or nil
	marker.spine_node = Unit.has_node(unit, "j_spine1") and Unit.node(unit, "j_spine1") or Unit.has_node(unit, "j_spine") and Unit.node(unit, "j_spine") or nil

	-- рост породы с учётом размера этого врага (у миньонов он немного разный)
	local breed = Status.breed(unit)
	local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
	local size = unit_data and unit_data.breed_size_variation and unit_data:breed_size_variation() or 1

	marker.base_height = (breed and breed.base_height or DEFAULT_BASE_HEIGHT) * (size or 1)

	-- базовые размеры фигуры (без масштаба по расстоянию); вид определяем по созданным проходам
	local width_scale = (cfg and cfg.bar_width or 100) / 100

	if style.sphere_fill then
		marker.kind = "sphere"
		marker.shape_width = math.min((SPHERE_BY_CATEGORY[category] or SPHERE_BY_CATEGORY.horde) * width_scale, SHAPE_MAX_DIAMETER)
	else
		marker.kind = "bar"
		marker.shape_width = math.min((WIDTH_BY_CATEGORY[category] or WIDTH_BY_CATEGORY.horde) * width_scale, MAX_WIDTH)
	end

	marker.shape_height = marker.kind == "bar" and (cfg and cfg.bar_thickness or BAR_HEIGHT) or marker.shape_width
	-- значок главного эффекта в центре сферы
	marker.center_dot = marker.kind ~= "bar" and cfg and cfg.dot_center or false
	marker.dots = {}
	marker.dot_count = 0
	marker.dot_timer = 0
	-- разнести проверки маркеров по кадрам
	marker.occlusion_timer = math.random() * OCCLUSION_INTERVAL
	marker.occlusion = 0
	marker.visibility = cfg and cfg.line_of_sight and 0 or 1

	for i = 1, MAX_DOTS do
		marker.dots[i] = {}
	end

	local bar_color = BAR_COLOR_BY_CATEGORY[category] or BAR_COLOR_BY_CATEGORY.horde

	marker.bar_color = bar_color

	if style.bar then
		local color = style.bar.color

		color[1], color[2], color[3], color[4] = bar_color[1], bar_color[2], bar_color[3], bar_color[4]
	end

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

-- Масштаб по расстоянию до врага (content.distance ставит движок до update_function).
local function _distance_scale(content, cfg)
	if cfg and cfg.shrink_with_distance == false then
		return 1
	end

	local distance = content.distance or 0
	local far = cfg and cfg.max_distance or 25

	if distance <= SCALE_NEAR or far <= SCALE_NEAR then
		return 1
	end

	local t = math.min((distance - SCALE_NEAR) / (far - SCALE_NEAR), 1)

	return 1 - t * (1 - SCALE_FAR_MIN)
end

-- Полоса: нижний край — на точке маркера.
local function _layout_bar(style, width, height, health_fraction, ghost_fraction, spacing)
	local left = -width * 0.5
	local top = -height
	local health_width = width * health_fraction
	local ghost_width = math.max(width * ghost_fraction - health_width, 0)
	local background_width = math.max(width - health_width - ghost_width - spacing, 0)

	for _, id in ipairs({ "bar", "ghost_bar", "background" }) do
		style[id].offset[2] = top
		style[id].size[2] = height
	end

	style.bar.offset[1] = left
	style.bar.size[1] = health_width

	style.ghost_bar.offset[1] = left + health_width
	style.ghost_bar.size[1] = ghost_width

	style.background.offset[1] = left + width - background_width
	style.background.size[1] = background_width

	for i = 1, NUM_TICKS do
		local tick_style = style["tick_" .. i]

		tick_style.offset[1] = math.floor(left + width * i / (NUM_TICKS + 1) - TICK_WIDTH * 0.5)
		tick_style.offset[2] = top
		tick_style.size[1] = TICK_WIDTH
		tick_style.size[2] = height
	end
end

-- Сфера: слой обрезан по высоте — нижняя доля fraction круга. UV v идёт сверху вниз.
local function _layout_sphere_layer(layer_style, diameter, fraction)
	local height = diameter * fraction
	local uvs = layer_style.uvs

	layer_style.offset[1] = -diameter * 0.5
	layer_style.offset[2] = -height
	layer_style.size[1] = diameter
	layer_style.size[2] = height
	uvs[1][2] = 1 - fraction
	uvs[2][2] = 1
end

local function _layout_sphere(style, marker, diameter, health_fraction, ghost_fraction)
	local fill_color = style.sphere_fill.color
	local bar_color = marker.bar_color
	local ghost_color = style.sphere_ghost.color
	local background = style.sphere_background

	fill_color[1], fill_color[2], fill_color[3], fill_color[4] = bar_color[1], bar_color[2], bar_color[3], bar_color[4]
	ghost_color[1], ghost_color[2], ghost_color[3], ghost_color[4] = SPHERE_GHOST_COLOR[1], SPHERE_GHOST_COLOR[2], SPHERE_GHOST_COLOR[3], SPHERE_GHOST_COLOR[4]
	background.offset[1] = -diameter * 0.5
	background.offset[2] = -diameter
	background.size[1] = diameter
	background.size[2] = diameter
	_layout_sphere_layer(style.sphere_fill, diameter, math.clamp(health_fraction, 0, 1))
	_layout_sphere_layer(style.sphere_ghost, diameter, math.clamp(math.max(ghost_fraction, health_fraction), 0, 1))

	local rim = style.sphere_rim

	if rim then
		rim.offset[1] = -diameter * 0.5 - 1
		rim.offset[2] = -diameter - 1
		rim.size[1] = diameter + 2
		rim.size[2] = diameter + 2
	end
end

-- Значок эффекта: плоский материал или картинка баффа (если есть проход для неё).
local function _dot_visual(style, i, dot)
	local kind, path = Status.dot_visual(dot)

	if kind == "buff" and not style["dot_icon_" .. i] then
		return nil
	end

	return kind, path
end

-- Одна ячейка эффекта: значок (плоский / баффа / цветная метка) в точке (x, y) размера icon_size.
local function _layout_dot_icon(widget, i, dot, x, y, icon_size, gradient, is_center)
	local style = widget.style
	local content = widget.content
	local chip_style = style["dot_chip_" .. i]
	local icon_style = style["dot_icon_" .. i]
	local flat_id = "dot_flat_" .. i
	local flat_style = style[flat_id]
	local visible_id = "dot_icon_visible_" .. i
	local color = dot.color
	local kind, path = _dot_visual(style, i, dot)

	local shadow = style.center_shadow

	if shadow and is_center then
		content.center_shadow_on = kind == "flat"
	end

	if kind == "flat" then
		local flat_color = flat_style.color
		local icon_color = is_center and CENTER_ICON_COLOR or color

		flat_color[2], flat_color[3], flat_color[4] = icon_color[2], icon_color[3], icon_color[4]

		if shadow and is_center then
			local grow = CENTER_SHADOW_GROW

			content.center_shadow = path
			shadow.offset[1] = x - grow
			shadow.offset[2] = y - grow
			shadow.size[1] = icon_size + grow * 2
			shadow.size[2] = icon_size + grow * 2
		end

		flat_style.offset[1] = x
		flat_style.offset[2] = y
		flat_style.size[1] = icon_size
		flat_style.size[2] = icon_size
		content[flat_id] = path
		content[flat_id .. "_on"] = true
		content[visible_id] = false
		chip_style.size[1] = 0

		return
	elseif kind == "buff" then
		local material_values = icon_style.material_values

		-- текстуру меняем только при смене эффекта в этой ячейке
		if material_values.talent_icon ~= path then
			material_values.talent_icon = path
			material_values.gradient_map = gradient
		end

		icon_style.offset[1] = x
		icon_style.offset[2] = y
		icon_style.size[1] = icon_size
		icon_style.size[2] = icon_size
		content[visible_id] = true
		content[flat_id .. "_on"] = false
		chip_style.size[1] = 0

		return
	end

	local chip_color = chip_style.color
	local chip_size = math.max(math.floor(icon_size / 3), 3)

	chip_color[1], chip_color[2], chip_color[3], chip_color[4] = color[1], color[2], color[3], color[4]
	chip_style.size[1] = chip_size
	chip_style.size[2] = chip_size
	chip_style.offset[1] = x + (icon_size - chip_size) * 0.5
	chip_style.offset[2] = y + (icon_size - chip_size) * 0.5
	content[visible_id] = false
	content[flat_id .. "_on"] = false
end

local function _hide_dot(widget, i)
	local content = widget.content

	if i == 1 then
		content.center_shadow_on = false
	end

	widget.style["dot_chip_" .. i].size[1] = 0
	content["dot_text_" .. i] = ""
	content["dot_icon_visible_" .. i] = false
	content["dot_flat_" .. i .. "_on"] = false
end

-- ширина числа стаков в строке эффектов (при масштабе 1)
local function _stacks_width(stacks)
	return stacks > 9 and 20 or stacks > 0 and 12 or 0
end

-- Эффекты: строкой по центру над фигурой (row_y — верх строки). С «главным эффектом в центре» (сфера) первый
-- эффект — внутри фигуры, его стаки — слева от неё, остальные — строкой.
local function _layout_dots(widget, marker, count, scale, shape_width, shape_height, row_y)
	local style = widget.style
	local content = widget.content
	local gradient = Status.resource_available("texture", ICON_GRADIENT) and ICON_GRADIENT or nil
	local icon_size = math.floor(ICON_SIZE * scale + 0.5)
	local font_size = math.max(SMALL_FONT_SIZE * scale, MIN_FONT_SIZE)
	local first_in_row = marker.center_dot and 2 or 1

	-- ширина строки, чтобы поставить её по центру
	local row_width = 0

	for i = first_in_row, count do
		row_width = row_width + icon_size + (2 + _stacks_width(marker.dots[i].stacks)) * scale
	end

	local x = -row_width * 0.5

	for i = 1, MAX_DOTS do
		if i > count then
			_hide_dot(widget, i)
		else
			local entry = marker.dots[i]
			local dot = entry.dot
			local color = dot.color
			local text_style = style["dot_text_" .. i]
			local text_color = text_style.text_color

			text_color[2], text_color[3], text_color[4] = color[2], color[3], color[4]
			text_style.font_size = font_size
			content["dot_text_" .. i] = entry.stacks > 0 and tostring(entry.stacks) or ""

			if i < first_in_row then
				local size = math.floor(shape_width * CENTER_ICON_FRACTION * scale + 0.5)
				local center_y = -shape_height * 0.5

				_layout_dot_icon(widget, i, dot, -size * 0.5, center_y - size * 0.5, size, gradient, true)

				-- стаки главного эффекта — слева от фигуры (справа — число здоровья)
				text_style.text_horizontal_alignment = "right"
				text_style.offset[1] = -shape_width * 0.5 - 4 * scale - DOT_TEXT_WIDTH
				text_style.offset[2] = center_y - TEXT_BOX_HEIGHT * 0.5
			else
				_layout_dot_icon(widget, i, dot, x, row_y, icon_size, gradient)

				text_style.text_horizontal_alignment = "left"
				text_style.offset[1] = x + icon_size + 2 * scale
				text_style.offset[2] = row_y + icon_size * 0.5 - TEXT_BOX_HEIGHT * 0.5
				x = x + icon_size + (2 + _stacks_width(entry.stacks)) * scale
			end
		end
	end
end

-- Что закрывает луч от камеры к точке target на теле врага: "wall", "enemy" или nil.
local function _ray_blocker(physics_world, camera_position, target, marker, cfg)
	local to_target = target - camera_position
	local direction = Vector3.normalize(to_target)
	local distance = Vector3.length(to_target) - OCCLUSION_MARGIN - OCCLUSION_START

	if distance <= 0 then
		return nil
	end

	local from = camera_position + direction * OCCLUSION_START

	-- стены: только статика, снаряжение врагов (динамика) сюда не попадает
	if cfg.line_of_sight and PhysicsWorld.raycast(physics_world, from, direction, distance, "any", "types", "statics", "collision_filter", WALL_FILTER) then
		if DEBUG_VISIBILITY then
			marker.debug_blocker = string.format("wall on %.1f m ray", distance)
		end

		return "wall"
	end

	if not cfg.hide_behind_enemies then
		return nil
	end

	-- "types", "both": тела врагов — динамические акторы, без этого луч видит только статику
	local hits, num_hits = PhysicsWorld.raycast(physics_world, from, direction, distance, "all", "types", "both", "max_hits", OCCLUSION_MAX_HITS, "collision_filter", OCCLUSION_FILTER)

	if not hits then
		return nil
	end

	for i = 1, num_hits or #hits do
		local hit = hits[i]
		local actor = hit and hit[HIT_INDEX_ACTOR]
		local hit_unit = actor and Actor.unit(actor)

		-- закрыть может только другой ЖИВОЙ враг (трупы и снаряжение не считаются)
		if hit_unit and hit_unit ~= marker.unit and HEALTH_ALIVE[hit_unit] then
			local breed = Status.breed(hit_unit)

			if breed and breed.breed_type == "minion" then
				if DEBUG_VISIBILITY then
					marker.debug_blocker = string.format("enemy %s, hit %d/%d", breed.name, i, num_hits or #hits)
				end

				return "enemy"
			end
		end
	end

	return nil
end

-- Что закрывает врага: "wall", "enemy" или nil. Как у Enemies Improved, целимся в тело (голову и грудь),
-- а не в маркер над головой: враг закрыт, только если закрыты обе точки. Стена важнее врага.
local function _blocker(parent, marker, cfg)
	local camera = parent._player_camera
	local physics_world = camera and parent:_physics_world()
	local unit = marker.unit

	if not physics_world or not ALIVE[unit] then
		return nil
	end

	local camera_position = Camera.local_position(camera)
	local head = Unit.world_position(unit, marker.head_node or 1)
	local head_blocker = _ray_blocker(physics_world, camera_position, head, marker, cfg)

	if not head_blocker then
		return nil
	end

	local spine_node = marker.spine_node

	if not spine_node then
		return head_blocker
	end

	local spine_blocker = _ray_blocker(physics_world, camera_position, Unit.world_position(unit, spine_node), marker, cfg)

	if not spine_blocker then
		return nil
	end

	return (head_blocker == "wall" or spine_blocker == "wall") and "wall" or "enemy"
end

-- Прозрачность маркера по видимости: за стеной — плавно в ноль, за другим врагом — до OCCLUDED_ALPHA.
local function _visibility_alpha(parent, marker, cfg, dt)
	if not cfg or (not cfg.line_of_sight and not cfg.hide_behind_enemies) then
		return 1
	end

	marker.occlusion_timer = marker.occlusion_timer - dt

	if marker.occlusion_timer <= 0 then
		marker.occlusion_timer = OCCLUSION_INTERVAL
		marker.blocker = _blocker(parent, marker, cfg)
	end

	local blocker = marker.blocker
	local visibility = marker.visibility or 1
	local occlusion = marker.occlusion

	if blocker == "wall" then
		visibility = math.max(visibility - dt * VISIBILITY_SPEED, 0)
	else
		visibility = math.min(visibility + dt * VISIBILITY_SPEED, 1)
	end

	if blocker == "enemy" then
		occlusion = math.min(occlusion + dt * OCCLUSION_SPEED, 1)
	else
		occlusion = math.max(occlusion - dt * OCCLUSION_SPEED, 0)
	end

	marker.visibility = visibility
	marker.occlusion = occlusion

	if DEBUG_VISIBILITY and blocker then
		local now = Managers.time and Managers.time:time("main") or 0

		if now >= (marker.debug_next_t or 0) then
			marker.debug_next_t = now + DEBUG_INTERVAL

			local own = Status.breed(marker.unit)

			mod:info("visibility %s: %s, alpha %.2f", own and own.name or "?", marker.debug_blocker or blocker, visibility * (1 - occlusion * (1 - OCCLUDED_ALPHA)))
		end
	end

	return visibility * (1 - occlusion * (1 - OCCLUDED_ALPHA))
end

-- Высота точки маркера над корнем юнита на следующий кадр: движок прибавляет position_offset к корню.
local function _update_anchor(marker, template, cfg)
	local unit = marker.unit

	if not ALIVE[unit] then
		return
	end

	local height = marker.base_height
	local head_node = marker.head_node

	if head_node then
		-- голова выше роста породы (наклон, прыжок, крупная модель) — точка над головой
		local head_height = Unit.world_position(unit, head_node).z - Unit.world_position(unit, 1).z + HEAD_MARGIN

		if head_height > height then
			height = head_height
		end
	end

	template.position_offset[3] = height + (cfg and cfg.bar_height_offset or 0) / 100
end

template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
	local unit = marker.unit
	local content = widget.content
	local style = widget.style
	local cfg = mod.cfg

	_update_anchor(marker, template, cfg)

	local health_extension = HEALTH_ALIVE[unit] and Status.health_extension(unit)
	local health_percent = health_extension and Status.health_fraction(health_extension) or 0
	local bar_logic = marker.bar_logic

	bar_logic:update(dt, t, health_percent)

	local health_fraction, ghost_fraction = bar_logic:animated_health_fractions()

	if health_fraction and ghost_fraction then
		marker.health_fraction = health_fraction
		marker.ghost_fraction = ghost_fraction
	end

	-- полоса дошла до нуля после смерти — маркер больше не нужен
	if not HEALTH_ALIVE[unit] and (not marker.health_fraction or marker.health_fraction <= 0) then
		marker.remove = true

		return
	end

	if not marker.draw or not marker.health_fraction then
		return
	end

	-- размеры этого кадра с учётом расстояния
	local scale = _distance_scale(content, cfg)
	local shape_width = marker.shape_width * scale
	local shape_height = marker.shape_height * scale
	local kind = marker.kind

	health_fraction = marker.health_fraction
	ghost_fraction = marker.ghost_fraction

	if kind == "sphere" then
		_layout_sphere(style, marker, shape_width, health_fraction, ghost_fraction)
	else
		_layout_bar(style, shape_width, math.max(shape_height, 2), health_fraction, ghost_fraction, template.bar_settings.bar_spacing)
	end

	-- эффекты
	local show_dots = cfg and cfg.show_dots

	if show_dots then
		marker.dot_timer = marker.dot_timer - dt

		if marker.dot_timer <= 0 then
			marker.dot_timer = DOT_UPDATE_INTERVAL
			marker.dot_count = HEALTH_ALIVE[unit] and Status.collect_dots(unit, marker.dots, MAX_DOTS) or 0
		end
	end

	local dot_count = show_dots and marker.dot_count or 0
	local gap = GAP * scale
	-- строка эффектов над фигурой; место под неё держим всегда, когда эффекты включены, чтобы имя не прыгало
	local row_height = show_dots and math.floor(ICON_SIZE * scale + 0.5) or 0
	local row_y = -shape_height - gap - row_height

	_layout_dots(widget, marker, dot_count, scale, shape_width, shape_height, row_y)

	-- имя — над строкой эффектов
	local font_size = math.max(SMALL_FONT_SIZE * scale, MIN_FONT_SIZE)
	local name_style = style.name_text
	local name_bottom = (show_dots and row_y or -shape_height) - gap

	name_style.font_size = font_size
	name_style.offset[1] = -MAX_WIDTH
	name_style.offset[2] = name_bottom - TEXT_BOX_HEIGHT

	-- число здоровья — справа от фигуры, по её центру
	local health_style = style.health_text

	health_style.font_size = font_size
	health_style.offset[1] = shape_width * 0.5 + 4 * scale
	health_style.offset[2] = -shape_height * 0.5 - TEXT_BOX_HEIGHT * 0.5

	if cfg and cfg.show_health_number and health_extension then
		local health = Status.current_health(health_extension)

		content.health_text = health and string.format("%d", math.ceil(health)) or ""
	else
		content.health_text = ""
	end

	widget.alpha_multiplier = _visibility_alpha(parent, marker, cfg, dt)
end

return template
