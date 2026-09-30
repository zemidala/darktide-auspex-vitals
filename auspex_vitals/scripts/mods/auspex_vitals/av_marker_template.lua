-- Шаблон маркера для HudElementWorldMarkers: тонкая полоса или кольцо здоровья над врагом,
-- под ними до MAX_DOTS меток периодического урона со стаками.
-- Анимацию «призрачного» урона даёт HudHealthBarLogic из самой игры.

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
local DOT_ROW_Y = BAR_HEIGHT + 3
-- запас для определения виджета: ширина полосы с учётом настройки масштаба не больше этой
local MAX_WIDTH = 400
local TICK_WIDTH = 2
local FONT_TYPE = "proxima_nova_bold"
local SMALL_FONT_SIZE = 14
-- Перекрытие другими врагами: луч от камеры к полосе фильтром стрельбы игрока (попадает по телам).
-- Стены проверяет сам движок (check_line_of_sight), его фильтр тела врагов не видит.
local OCCLUSION_FILTER = "filter_player_character_shooting_raycast_dynamics"
local OCCLUSION_INTERVAL = 0.1
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

-- Кольцо (настройка bar_style = "ring"): RING_SEGMENTS точек-прямоугольников по окружности,
-- по RING_SEGMENTS / 4 на четверть; зазор между четвертями — деления 25/50/75 %.
-- Точки не поворачиваем: при таком размере они сливаются в линию, а материалы не нужны.
local RING_SEGMENTS = 24
local RING_QUARTER_GAP = math.rad(10)
local RING_BACKGROUND_COLOR = { 160, 20, 20, 20 }
local RING_GHOST_COLOR = { 255, 240, 200, 200 }
-- радиус и размер точки при масштабе 100 %
local RING_BY_CATEGORY = {
	horde = { radius = 13, dot = 3 },
	elite = { radius = 17, dot = 4 },
	special = { radius = 17, dot = 4 },
	boss = { radius = 23, dot = 5 },
}
local RING_MAX_DOT = 12

-- Сфера (bar_style = "sphere"): залитый круг игры (материал сканера), здоровье налито снизу вверх, как
-- жидкость. Уровень — обрезка по UV (проход texture_uv), поэтому край круга гладкий. Контур — круг колеса
-- команд, если загружен. Если материал сферы не загружен, маркер остаётся полосой.
local SPHERE_MATERIAL = "content/ui/materials/backgrounds/scanner/scanner_drill_circle_filled"
local SPHERE_RIM_MATERIAL = "content/ui/materials/hud/communication_wheel/middle_circle"
local SPHERE_BACKGROUND_COLOR = { 170, 25, 25, 25 }
local SPHERE_GHOST_COLOR = { 230, 240, 200, 200 }
local SPHERE_RIM_COLOR = { 220, 0, 0, 0 }
local SPHERE_TICK_COLOR = { 200, 0, 0, 0 }
-- диаметр при масштабе 100 %
local SPHERE_BY_CATEGORY = {
	horde = 22,
	elite = 30,
	special = 30,
	boss = 40,
}
local SPHERE_MAX_DIAMETER = 160

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
-- Высота полосы считается каждый кадр в _update_anchor: от корня юнита (node 1) до большего из
-- «голова + HEAD_MARGIN» и «рост породы × размер врага», плюс сдвиг из настроек.
-- Шаблон клонируется на каждый маркер, поэтому position_offset у каждого свой.
template.unit_node = nil
template.position_offset = { 0, 0, 2 }
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

	-- точки кольца создаём, только если выбран вид «кольцо»: маркеры пересоздаются при смене настроек
	if mod.cfg and mod.cfg.bar_style == "ring" then
		for i = 1, RING_SEGMENTS do
			passes[#passes + 1] = _rect("ring_" .. i, { 0, 0, 3 }, { 0, 0 }, { 255, 255, 255, 255 })
		end
	end

	-- сфера: только если выбран этот вид и материал загружен
	if mod.cfg and mod.cfg.bar_style == "sphere" and Status.resource_available("material", SPHERE_MATERIAL) then
		passes[#passes + 1] = {
			pass_type = "texture",
			style_id = "sphere_background",
			value = SPHERE_MATERIAL,
			style = {
				offset = { 0, 0, 1 },
				size = { 0, 0 },
				color = table.clone(SPHERE_BACKGROUND_COLOR),
			},
		}

		for _, layer in ipairs({ "sphere_ghost", "sphere_fill" }) do
			passes[#passes + 1] = {
				pass_type = "texture_uv",
				style_id = layer,
				value = SPHERE_MATERIAL,
				style = {
					offset = { 0, 0, layer == "sphere_fill" and 3 or 2 },
					size = { 0, 0 },
					color = { 255, 255, 255, 255 },
					uvs = {
						{ 0, 0 },
						{ 1, 1 },
					},
				},
			}
		end

		for i = 1, NUM_TICKS do
			passes[#passes + 1] = _rect("sphere_tick_" .. i, { 0, 0, 4 }, { 0, 1 }, table.clone(SPHERE_TICK_COLOR))
		end

		if Status.resource_available("material", SPHERE_RIM_MATERIAL) then
			passes[#passes + 1] = {
				pass_type = "texture",
				style_id = "sphere_rim",
				value = SPHERE_RIM_MATERIAL,
				style = {
					offset = { 0, 0, 5 },
					size = { 0, 0 },
					color = table.clone(SPHERE_RIM_COLOR),
				},
			}
		end
	end

	local icons_available = Status.resource_available("material", ICON_MATERIAL)

	for i = 1, MAX_DOTS do
		local flat_id = "dot_flat_" .. i

		passes[#passes + 1] = _rect("dot_chip_" .. i, { 0, 0, 4 }, { 0, 6 }, { 255, 255, 255, 255 })
		passes[#passes + 1] = _text("dot_text_" .. i, { 0, 0, 4 }, { 30, 16 }, SMALL_FONT_SIZE, "left", "center")
		-- плоский значок: материал задаётся через content[flat_id], цвет — цвет эффекта
		passes[#passes + 1] = {
			pass_type = "texture",
			style_id = flat_id,
			value_id = flat_id,
			style = {
				offset = { 0, DOT_ROW_Y, 5 },
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
					offset = { 0, DOT_ROW_Y, 5 },
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

	marker.bar_logic = HudHealthBarLogic:new(template.bar_settings)

	local unit = marker.unit

	marker.head_node = Unit.has_node(unit, HEAD_NODE) and Unit.node(unit, HEAD_NODE) or nil

	-- рост породы с учётом размера этого врага (у миньонов он немного разный)
	local breed = Status.breed(unit)
	local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
	local size = unit_data and unit_data.breed_size_variation and unit_data:breed_size_variation() or 1

	marker.base_height = (breed and breed.base_height or DEFAULT_BASE_HEIGHT) * (size or 1)
	local width_scale = (mod.cfg and mod.cfg.bar_width or 100) / 100

	marker.width = math.min(math.floor((WIDTH_BY_CATEGORY[category] or WIDTH_BY_CATEGORY.horde) * width_scale), MAX_WIDTH)
	marker.dot_row_y = DOT_ROW_Y

	if widget.style.sphere_fill then
		local diameter = math.min(math.floor((SPHERE_BY_CATEGORY[category] or SPHERE_BY_CATEGORY.horde) * width_scale + 0.5), SPHERE_MAX_DIAMETER)
		local style = widget.style
		local left = -diameter * 0.5

		marker.is_sphere = true
		marker.sphere_diameter = diameter
		marker.width = diameter
		marker.dot_row_y = diameter + 3

		for _, id in ipairs({ "sphere_background", "sphere_ghost", "sphere_fill" }) do
			style[id].offset[1] = left
			style[id].size[1] = diameter
		end

		style.sphere_background.size[2] = diameter

		-- деления: горизонтальные хорды на высоте 25/50/75 %
		local radius = diameter * 0.5

		for i = 1, NUM_TICKS do
			local level = i / (NUM_TICKS + 1)
			local dy = (0.5 - level) * diameter
			local chord = 2 * math.sqrt(math.max(radius * radius - dy * dy, 0))
			local tick_style = style["sphere_tick_" .. i]

			tick_style.offset[1] = math.floor(-chord * 0.5 + 0.5)
			tick_style.offset[2] = math.floor(diameter * (1 - level) + 0.5)
			tick_style.size[1] = math.floor(chord + 0.5)
		end

		if style.sphere_rim then
			style.sphere_rim.offset[1] = left - 1
			style.sphere_rim.offset[2] = -1
			style.sphere_rim.size[1] = diameter + 2
			style.sphere_rim.size[2] = diameter + 2
		end

		style.background.size[1] = 0
		style.ghost_bar.size[1] = 0
		style.bar.size[1] = 0

		for i = 1, NUM_TICKS do
			style["tick_" .. i].size[1] = 0
		end
	end

	if widget.style.ring_1 then
		local ring = RING_BY_CATEGORY[category] or RING_BY_CATEGORY.horde

		marker.is_ring = true
		marker.ring_radius = ring.radius * width_scale
		marker.ring_dot = math.min(math.max(math.floor(ring.dot * width_scale + 0.5), 2), RING_MAX_DOT)
		-- для строки эффектов и числа здоровья кольцо — это «полоса» шириной в диаметр
		marker.width = math.floor(marker.ring_radius * 2 + marker.ring_dot)
		marker.dot_row_y = marker.ring_radius * 2 + marker.ring_dot + 3

		-- части полосы в виде «кольцо» не нужны
		local style = widget.style

		style.background.size[1] = 0
		style.ghost_bar.size[1] = 0
		style.bar.size[1] = 0

		for i = 1, NUM_TICKS do
			style["tick_" .. i].size[1] = 0
		end
	end
	marker.dots = {}
	marker.dot_count = 0
	marker.dot_timer = 0
	-- разнести проверки маркеров по кадрам
	marker.occlusion_timer = math.random() * OCCLUSION_INTERVAL
	marker.occlusion = 0

	for i = 1, MAX_DOTS do
		marker.dots[i] = {}
	end

	local bar_color = BAR_COLOR_BY_CATEGORY[category] or BAR_COLOR_BY_CATEGORY.horde
	local color = widget.style.bar.color

	color[1], color[2], color[3], color[4] = bar_color[1], bar_color[2], bar_color[3], bar_color[4]
	marker.bar_color = bar_color

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

-- Кольцо: точка k закрашена цветом здоровья, если на неё приходится оставшееся здоровье,
-- светлым — если «призрачный» урон, тёмным — если потеряно. Урон «съедает» кольцо по часовой стрелке
-- от 12 часов, как стрелка таймера: оставшееся здоровье — хвост кольца до 12 часов.
local function _layout_ring(style, marker, health_fraction, ghost_fraction)
	local radius = marker.ring_radius
	local dot = marker.ring_dot
	local center_y = radius + dot * 0.5
	local per_quarter = RING_SEGMENTS / 4
	local quarter_arc = math.pi * 0.5 - RING_QUARTER_GAP
	local health_color = marker.bar_color

	for k = 1, RING_SEGMENTS do
		local ring_style = style["ring_" .. k]
		local quarter = math.floor((k - 1) / per_quarter)
		local index_in_quarter = (k - 1) % per_quarter
		local angle = quarter * math.pi * 0.5 + RING_QUARTER_GAP * 0.5 + (index_in_quarter + 0.5) * quarter_arc / per_quarter
		local offset = ring_style.offset
		local size = ring_style.size

		-- угол от 12 часов по часовой стрелке; y экрана растёт вниз
		offset[1] = math.floor(math.sin(angle) * radius - dot * 0.5 + 0.5)
		offset[2] = math.floor(center_y - math.cos(angle) * radius - dot * 0.5 + 0.5)
		size[1] = dot
		size[2] = dot

		local position = 1 - (k - 0.5) / RING_SEGMENTS
		local color = position <= health_fraction and health_color or position <= ghost_fraction and RING_GHOST_COLOR or RING_BACKGROUND_COLOR
		local ring_color = ring_style.color

		ring_color[1], ring_color[2], ring_color[3], ring_color[4] = color[1], color[2], color[3], color[4]
	end
end

-- Сфера: слой обрезан по высоте — нижняя доля fraction круга. UV v идёт сверху вниз.
local function _layout_sphere_layer(layer_style, diameter, fraction)
	local height = diameter * fraction
	local uvs = layer_style.uvs

	layer_style.offset[2] = diameter - height
	layer_style.size[2] = height
	uvs[1][2] = 1 - fraction
	uvs[2][2] = 1
end

local function _layout_sphere(style, marker, health_fraction, ghost_fraction)
	local diameter = marker.sphere_diameter
	local fill_color = style.sphere_fill.color
	local bar_color = marker.bar_color
	local ghost_color = style.sphere_ghost.color

	fill_color[1], fill_color[2], fill_color[3], fill_color[4] = bar_color[1], bar_color[2], bar_color[3], bar_color[4]
	ghost_color[1], ghost_color[2], ghost_color[3], ghost_color[4] = SPHERE_GHOST_COLOR[1], SPHERE_GHOST_COLOR[2], SPHERE_GHOST_COLOR[3], SPHERE_GHOST_COLOR[4]
	_layout_sphere_layer(style.sphere_fill, diameter, math.clamp(health_fraction, 0, 1))
	_layout_sphere_layer(style.sphere_ghost, diameter, math.clamp(math.max(ghost_fraction, health_fraction), 0, 1))
end

-- Значок эффекта: плоский материал или картинка баффа (если есть проход для неё).
local function _dot_visual(style, i, dot)
	local kind, path = Status.dot_visual(dot)

	if kind == "buff" and not style["dot_icon_" .. i] then
		return nil
	end

	return kind, path
end

local function _layout_dots(widget, marker, show)
	local style = widget.style
	local content = widget.content
	local left = -marker.width * 0.5
	local count = show and marker.dot_count or 0
	local x = left
	local row_y = marker.dot_row_y or DOT_ROW_Y
	local gradient = Status.resource_available("texture", ICON_GRADIENT) and ICON_GRADIENT or nil

	for i = 1, MAX_DOTS do
		local chip_id = "dot_chip_" .. i
		local text_id = "dot_text_" .. i
		local icon_id = "dot_icon_" .. i
		local visible_id = "dot_icon_visible_" .. i
		local chip_style = style[chip_id]
		local text_style = style[text_id]
		local icon_style = style[icon_id]
		local flat_id = "dot_flat_" .. i
		local flat_style = style[flat_id]

		if i <= count then
			local entry = marker.dots[i]
			local dot = entry.dot
			local color = dot.color
			local kind, path = _dot_visual(style, i, dot)
			local text_x

			if kind == "flat" then
				local flat_color = flat_style.color

				flat_color[2], flat_color[3], flat_color[4] = color[2], color[3], color[4]
				flat_style.offset[1] = x
				flat_style.offset[2] = row_y
				content[flat_id] = path
				content[flat_id .. "_on"] = true
				content[visible_id] = false
				chip_style.size[1] = 0
				text_x = x + ICON_SIZE + 2
			elseif kind == "buff" then
				local material_values = icon_style.material_values

				-- текстуру меняем только при смене эффекта в этой ячейке
				if material_values.talent_icon ~= path then
					material_values.talent_icon = path
					material_values.gradient_map = gradient
				end

				icon_style.offset[1] = x
				icon_style.offset[2] = row_y
				content[visible_id] = true
				content[flat_id .. "_on"] = false
				chip_style.size[1] = 0
				text_x = x + ICON_SIZE + 2
			else
				content[flat_id .. "_on"] = false
				local chip_color = chip_style.color

				chip_color[1], chip_color[2], chip_color[3], chip_color[4] = color[1], color[2], color[3], color[4]
				chip_style.size[1] = 6
				chip_style.offset[1] = x
				chip_style.offset[2] = row_y + (ICON_SIZE - 6) * 0.5
				content[visible_id] = false
				text_x = x + 8
			end

			local text_color = text_style.text_color

			text_color[2], text_color[3], text_color[4] = color[2], color[3], color[4]
			text_style.offset[1] = text_x
			text_style.offset[2] = row_y + ICON_SIZE * 0.5 - 8
			content[text_id] = entry.stacks > 0 and tostring(entry.stacks) or ""

			x = text_x + (entry.stacks > 9 and 22 or entry.stacks > 0 and 14 or 2)
		else
			chip_style.size[1] = 0
			content[text_id] = ""
			content[visible_id] = false
			content[flat_id .. "_on"] = false
		end
	end
end

-- true, если луч от камеры к полосе раньше упирается в другого врага
local function _is_occluded(parent, marker)
	local camera = parent._player_camera
	local physics_world = camera and parent:_physics_world()

	if not physics_world then
		return false
	end

	local camera_position = Camera.local_position(camera)
	local to_bar = marker.position:unbox() - camera_position
	local direction = Vector3.normalize(to_bar)
	local distance = Vector3.length(to_bar) - OCCLUSION_MARGIN - OCCLUSION_START

	if distance <= 0 then
		return false
	end

	local from = camera_position + direction * OCCLUSION_START
	-- "types", "both": тела врагов — динамические акторы, без этого луч видит только статику
	local hits, num_hits = PhysicsWorld.raycast(physics_world, from, direction, distance, "all", "types", "both", "max_hits", OCCLUSION_MAX_HITS, "collision_filter", OCCLUSION_FILTER)

	if not hits then
		return false
	end

	for i = 1, num_hits or #hits do
		local hit = hits[i]
		local actor = hit and hit[HIT_INDEX_ACTOR]
		local hit_unit = actor and Actor.unit(actor)

		-- закрывать полосу может только другой враг
		if hit_unit and hit_unit ~= marker.unit then
			local breed = Status.breed(hit_unit)

			if breed and breed.breed_type == "minion" then
				return true
			end
		end
	end

	return false
end

local function _occlusion_alpha(parent, marker, cfg, dt)
	if not cfg or not cfg.hide_behind_enemies then
		return 1
	end

	marker.occlusion_timer = marker.occlusion_timer - dt

	if marker.occlusion_timer <= 0 then
		marker.occlusion_timer = OCCLUSION_INTERVAL
		marker.is_occluded = _is_occluded(parent, marker)
	end

	local occlusion = marker.occlusion

	if marker.is_occluded then
		occlusion = math.min(occlusion + dt * OCCLUSION_SPEED, 1)
	else
		occlusion = math.max(occlusion - dt * OCCLUSION_SPEED, 0)
	end

	marker.occlusion = occlusion

	return 1 - occlusion * (1 - OCCLUDED_ALPHA)
end

-- Высота полосы над корнем юнита на следующий кадр: движок прибавляет position_offset к позиции корня.
local function _update_anchor(marker, template, cfg)
	local unit = marker.unit

	if not ALIVE[unit] then
		return
	end

	local height = marker.base_height
	local head_node = marker.head_node

	if head_node then
		-- голова выше роста породы (наклон, прыжок, крупная модель) — полоса над головой
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

	_update_anchor(marker, template, mod.cfg)
	local style = widget.style
	local cfg = mod.cfg
	local health_extension = HEALTH_ALIVE[unit] and Status.health_extension(unit)
	local health_percent = health_extension and Status.health_fraction(health_extension) or 0
	local bar_logic = marker.bar_logic

	bar_logic:update(dt, t, health_percent)

	local health_fraction, ghost_fraction = bar_logic:animated_health_fractions()

	if health_fraction and ghost_fraction then
		if marker.is_sphere then
			_layout_sphere(style, marker, health_fraction, ghost_fraction)
		elseif marker.is_ring then
			_layout_ring(style, marker, health_fraction, ghost_fraction)
		else
			_layout_bar(style, marker.width, health_fraction, ghost_fraction, template.bar_settings.bar_spacing)
		end

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
		-- у кольца число — справа по центру кольца, у полосы — справа от полосы
		style.health_text.offset[2] = marker.is_sphere and marker.sphere_diameter * 0.5 - 10 or marker.is_ring and marker.ring_radius + marker.ring_dot * 0.5 - 10 or BAR_HEIGHT * 0.5 - 10
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
	widget.alpha_multiplier = visibility * _occlusion_alpha(parent, marker, cfg, dt)
end

return template
