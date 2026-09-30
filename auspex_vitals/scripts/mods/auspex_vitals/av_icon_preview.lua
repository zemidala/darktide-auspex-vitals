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

-- Первый в строке — значок, который мод использует сейчас.
local ROWS = {
	{
		label = "icon_preview_burning",
		icons = {
			BUFFS .. "states_fire_buff_hud",
			BUFFS .. "horde_buffs/buff_families/hordes_buff_family_fire",
			BUFFS .. "horde_buffs/small_buffs/hordes_buff_burning_on_melee_hit",
			BUFFS .. "horde_buffs/small_buffs/hordes_buff_damage_vs_burning",
		},
	},
	{
		label = "icon_preview_warpfire",
		icons = {
			BUFFS .. "psyker/psyker_ranged_shots_soulblaze",
			BUFFS .. "psyker/psyker_blocking_soulblaze",
			BUFFS .. "psyker/psyker_soulblaze_reduces_damage_taken",
			BUFFS .. "states_green_fire_buff_hud",
		},
	},
	{
		label = "icon_preview_electrocuted",
		icons = {
			BUFFS .. "states_electric_buff_hud",
			BUFFS .. "horde_buffs/buff_families/hordes_buff_family_electric",
		},
	},
	{
		label = "icon_preview_bleeding",
		icons = {
			BUFFS .. "zealot/zealot_crits_apply_bleed",
			BUFFS .. "ogryn/ogryn_nearby_bleeds_reduce_damage_taken",
		},
	},
	{
		label = "icon_preview_toxin",
		icons = {
			BUFFS .. "states_toxic_cloud_buff_hud",
			BUFFS .. "broker/broker_damage_after_toxined_enemies",
			BUFFS .. "broker/broker_toughness_on_toxined_kill",
		},
	},
}

local MAX_ICONS = 4

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
			local loaded = material_available and Status.resource_available("texture", icon)

			if loaded then
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

-- держим сетку в центре экрана, как ленту урона
template.update_function = function (parent, ui_renderer, widget, marker, template, dt, t)
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

template.on_exit = function (widget, marker, template)
	if _marker_id == marker.id then
		_marker_id = nil
	end
end

Preview.template = template

function Preview.toggle(element)
	if not element then
		mod:echo(mod:localize("icon_preview_no_hud"))

		return
	end

	if _marker_id then
		element:event_remove_world_marker(_marker_id)
		_marker_id = nil

		return
	end

	local camera = element._player_camera

	if not camera then
		mod:echo(mod:localize("icon_preview_no_hud"))

		return
	end

	element:event_add_world_marker_position(template.name, _anchor(camera), function (id)
		_marker_id = id
	end)
end

function Preview.detach()
	_marker_id = nil
end

return Preview
