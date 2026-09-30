-- Просмотр значков эффектов: команда чата /av_icons показывает у центра экрана сетку значков-кандидатов
-- с номерами, чтобы выбрать самые читаемые. Значки берутся из пакетов игры; незагруженные помечены.

local mod = get_mod("auspex_vitals")
local Status = mod.av_status

local UIWidget = require("scripts/managers/ui/ui_widget")

local ICON_SIZE = 56
local CELL_WIDTH = 130
local ROW_HEIGHT = 96
local LABEL_WIDTH = 170
local ANCHOR_DISTANCE = 5
local BUFFS = "content/ui/textures/icons/buffs/hud/"
local FLAT = "content/ui/materials/icons/"
local MAX_ICONS = 5

-- Первый в строке — плоский значок-материал (его мод использует сейчас, красит в цвет эффекта),
-- дальше — картинки баффов (запасной вариант).
local function flat(path)
	return {
		flat = FLAT .. path,
	}
end

local ROWS = {
	{
		label = "icon_preview_burning",
		color = { 255, 255, 140, 30 },
		icons = {
			flat("presets/preset_20"),
			BUFFS .. "states_fire_buff_hud",
			BUFFS .. "horde_buffs/buff_families/hordes_buff_family_fire",
			BUFFS .. "horde_buffs/small_buffs/hordes_buff_burning_on_melee_hit",
			BUFFS .. "horde_buffs/small_buffs/hordes_buff_damage_vs_burning",
		},
	},
	{
		label = "icon_preview_warpfire",
		color = { 255, 170, 110, 255 },
		icons = {
			flat("circumstances/havoc/havoc_mutator_ember"),
			BUFFS .. "psyker/psyker_ranged_shots_soulblaze",
			BUFFS .. "psyker/psyker_blocking_soulblaze",
			BUFFS .. "psyker/psyker_soulblaze_reduces_damage_taken",
		},
	},
	{
		label = "icon_preview_electrocuted",
		color = { 255, 120, 200, 255 },
		icons = {
			flat("presets/preset_11"),
			BUFFS .. "states_electric_buff_hud",
			BUFFS .. "horde_buffs/buff_families/hordes_buff_family_electric",
		},
	},
	{
		label = "icon_preview_bleeding",
		color = { 255, 220, 30, 30 },
		icons = {
			flat("presets/preset_13"),
			BUFFS .. "zealot/zealot_crits_apply_bleed",
			BUFFS .. "ogryn/ogryn_nearby_bleeds_reduce_damage_taken",
		},
	},
	{
		label = "icon_preview_toxin",
		color = { 255, 120, 220, 60 },
		icons = {
			flat("circumstances/havoc/havoc_mutator_nurgle"),
			BUFFS .. "states_toxic_cloud_buff_hud",
			BUFFS .. "broker/broker_damage_after_toxined_enemies",
			BUFFS .. "broker/broker_toughness_on_toxined_kill",
		},
	},
}

local Preview = {}

local _marker_id = nil

local template = {}

template.name = "auspex_vitals_icon_preview"
template.max_distance = 100
template.check_line_of_sight = false
template.screen_clamp = false

local function _grid_origin()
	return -(LABEL_WIDTH + CELL_WIDTH * MAX_ICONS) * 0.5, -(ROW_HEIGHT * #ROWS) * 0.5
end

template.create_widget_defintion = function (template, scenegraph_id)
	local passes = {}
	local material_available = Status.resource_available("material", Status.ICON_MATERIAL)
	local x0, y0 = _grid_origin()

	passes[#passes + 1] = {
		pass_type = "rect",
		style = {
			offset = { x0 - 20, y0 - 20, 0 },
			size = { LABEL_WIDTH + CELL_WIDTH * MAX_ICONS + 40, ROW_HEIGHT * #ROWS + 40 },
			color = { 200, 10, 10, 10 },
		},
	}

	for row_index, row in ipairs(ROWS) do
		local y = y0 + (row_index - 1) * ROW_HEIGHT

		passes[#passes + 1] = {
			pass_type = "text",
			value = mod:localize(row.label),
			style = {
				offset = { x0, y, 2 },
				size = { LABEL_WIDTH, ICON_SIZE },
				font_type = "proxima_nova_bold",
				font_size = 20,
				text_vertical_alignment = "center",
				text_color = { 255, 255, 255, 255 },
			},
		}

		for icon_index, icon in ipairs(row.icons) do
			local x = x0 + LABEL_WIDTH + (icon_index - 1) * CELL_WIDTH
			local loaded

			if type(icon) == "table" then
				loaded = Status.resource_available("material", icon.flat)

				if loaded then
					passes[#passes + 1] = {
						pass_type = "texture",
						value = icon.flat,
						style = {
							offset = { x, y, 2 },
							size = { ICON_SIZE, ICON_SIZE },
							color = table.clone(row.color),
						},
					}
				end
			else
				loaded = material_available and Status.resource_available("texture", icon)
			end

			if loaded and type(icon) ~= "table" then
				passes[#passes + 1] = {
					pass_type = "texture",
					value = Status.ICON_MATERIAL,
					style = {
						offset = { x, y, 2 },
						size = { ICON_SIZE, ICON_SIZE },
						color = { 255, 255, 255, 255 },
						material_values = {
							opacity = 1,
							progress = 1,
							talent_icon = icon,
							gradient_map = Status.resource_available("texture", Status.ICON_GRADIENT) and Status.ICON_GRADIENT or nil,
						},
					},
				}
			end

			-- номер значка; у незагруженных — пометка вместо картинки
			passes[#passes + 1] = {
				pass_type = "text",
				value = loaded and string.format("%d.%d", row_index, icon_index) or string.format("%d.%d %s", row_index, icon_index, mod:localize("icon_preview_not_loaded")),
				style = {
					offset = { x, y + ICON_SIZE + 2, 2 },
					size = { CELL_WIDTH - 6, 24 },
					font_type = "proxima_nova_bold",
					font_size = 16,
					text_color = loaded and { 255, 220, 220, 220 } or { 255, 230, 90, 90 },
				},
			}
		end
	end

	return UIWidget.create_definition(passes, scenegraph_id)
end

local function _anchor(camera)
	return Camera.local_position(camera) + Quaternion.forward(Camera.local_rotation(camera)) * ANCHOR_DISTANCE
end

-- держим панель в центре экрана, как ленту урона
local function _to_screen_center(parent, ui_renderer, widget, marker)
	local camera = parent._player_camera

	if not camera then
		return
	end

	local anchor = _anchor(camera)
	local x, y = parent:_convert_world_to_screen_position(camera, anchor)
	local screen_x, screen_y = parent:_get_screen_offset(ui_renderer.scale)

	widget.offset[1] = (x - screen_x) * ui_renderer.inverse_scale
	widget.offset[2] = (y - screen_y) * ui_renderer.inverse_scale
	marker.world_position:store(anchor)
end

template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
	_to_screen_center(parent, ui_renderer, widget, marker)
end

template.on_exit = function (widget, marker, template)
	if _marker_id == marker.id then
		_marker_id = nil
	end
end

Preview.template = template

-- Просмотр круглых материалов для кольца здоровья (/av_rings) ----------------------------------
-- Кандидаты — материалы игры с круговым прогрессом; параметры — ровно те, что им передаёт сама игра.
-- Прогресс крутится 0 → 1 за RING_CYCLE секунд, чтобы было видно форму, гладкость и направление.

local RING_SIZE = 72
local RING_CELL = 150
local RING_COLUMNS = 4
local RING_CYCLE = 3
local MATERIALS = "content/ui/materials/"

local RING_CANDIDATES = {
	{ path = MATERIALS .. "icons/abilities/frames/background_progress", kind = "progress" },
	{ path = MATERIALS .. "icons/abilities/frames/inner_line_thick_progress", kind = "progress" },
	{ path = MATERIALS .. "icons/abilities/frames/outer_line_progress", kind = "progress" },
	{ path = MATERIALS .. "icons/items/salvage_circle", kind = "progress" },
	{ path = MATERIALS .. "icons/buffs/hud/buff_container_with_background", kind = "progress" },
	{ path = MATERIALS .. "effects/forcesword_bar", kind = "arc" },
	{ path = MATERIALS .. "hud/communication_wheel/middle_circle", kind = "static" },
	{ path = MATERIALS .. "backgrounds/scanner/scanner_drill_circle_filled", kind = "static" },
}

local _ring_marker_id = nil

local ring_template = {}

ring_template.name = "auspex_vitals_ring_preview"
ring_template.max_distance = 100
ring_template.check_line_of_sight = false
ring_template.screen_clamp = false

local function _ring_material_values(kind)
	if kind == "progress" then
		return {
			progress = 0.65,
		}
	elseif kind == "arc" then
		-- как заряды у прицела (weapon_counter_template_block_charges.lua)
		return {
			amount = 0.65,
			glow_on_off = 0,
			lightning_opacity = 0,
			arc_top_bottom = { 1, 0 },
			fill_outline_opacity = { 1.3, 1 },
		}
	end

	return nil
end

ring_template.create_widget_defintion = function (template, scenegraph_id)
	local rows = math.ceil(#RING_CANDIDATES / RING_COLUMNS)
	local width = RING_CELL * RING_COLUMNS
	local height = (RING_SIZE + 40) * rows
	local x0, y0 = -width * 0.5, -height * 0.5
	local passes = {
		{
			pass_type = "rect",
			style = {
				offset = { x0 - 20, y0 - 20, 0 },
				size = { width + 40, height + 40 },
				color = { 200, 10, 10, 10 },
			},
		},
	}

	for index, candidate in ipairs(RING_CANDIDATES) do
		local column = (index - 1) % RING_COLUMNS
		local row = math.floor((index - 1) / RING_COLUMNS)
		local x = x0 + column * RING_CELL + (RING_CELL - RING_SIZE) * 0.5
		local y = y0 + row * (RING_SIZE + 40)
		local loaded = Status.resource_available("material", candidate.path)

		if loaded then
			passes[#passes + 1] = {
				pass_type = "texture",
				style_id = "ring_" .. index,
				value = candidate.path,
				style = {
					offset = { x, y, 2 },
					size = { RING_SIZE, RING_SIZE },
					color = { 255, 230, 70, 40 },
					material_values = _ring_material_values(candidate.kind),
				},
			}
		end

		passes[#passes + 1] = {
			pass_type = "text",
			value = loaded and tostring(index) or string.format("%d %s", index, mod:localize("icon_preview_not_loaded")),
			style = {
				offset = { x - (RING_CELL - RING_SIZE) * 0.5, y + RING_SIZE + 4, 2 },
				size = { RING_CELL, 24 },
				font_type = "proxima_nova_bold",
				font_size = 18,
				text_horizontal_alignment = "center",
				text_color = loaded and { 255, 220, 220, 220 } or { 255, 230, 90, 90 },
			},
		}
	end

	return UIWidget.create_definition(passes, scenegraph_id)
end

ring_template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
	_to_screen_center(parent, ui_renderer, widget, marker)

	local progress = (t % RING_CYCLE) / RING_CYCLE

	for index, candidate in ipairs(RING_CANDIDATES) do
		local style = widget.style["ring_" .. index]
		local material_values = style and style.material_values

		if material_values then
			if candidate.kind == "progress" then
				material_values.progress = progress
			elseif candidate.kind == "arc" then
				material_values.amount = progress
				material_values.arc_top_bottom[1] = progress
			end
		end
	end
end

ring_template.on_exit = function (widget, marker, template)
	if _ring_marker_id == marker.id then
		_ring_marker_id = nil
	end
end

Preview.ring_template = ring_template

-- Показать/скрыть панель: общая логика для /av_icons и /av_rings.
local function _toggle(element, template_name, get_id, set_id)
	if not element then
		mod:echo(mod:localize("icon_preview_no_hud"))

		return
	end

	local id = get_id()

	if id then
		element:event_remove_world_marker(id)
		set_id(nil)

		return
	end

	local camera = element._player_camera

	if not camera then
		mod:echo(mod:localize("icon_preview_no_hud"))

		return
	end

	element:event_add_world_marker_position(template_name, _anchor(camera), function (new_id)
		set_id(new_id)
	end)
end

function Preview.toggle(element)
	_toggle(element, template.name, function ()
		return _marker_id
	end, function (id)
		_marker_id = id
	end)
end

function Preview.toggle_rings(element)
	_toggle(element, ring_template.name, function ()
		return _ring_marker_id
	end, function (id)
		_ring_marker_id = id
	end)
end

function Preview.detach()
	_marker_id = nil
	_ring_marker_id = nil
end

return Preview
