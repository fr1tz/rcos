# Copyright © 2018 Michael Goldener <mg@wasted.ch>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends Polygon2D

export(String, "Stick", "DPad", "Touchpad", "Button") var emulate
export(int) var radius = 64
export(int) var threshold = 0
export(int) var button_mode = 0
export(Color) var hi_color = Color(1, 1, 1)
export(Color) var pad_color = Color(0, 0, 1)
export(Color) var outline_color_dark = Color(0, 0, 1)
export(Color) var outline_color_light = Color(0.5, 0.5, 1)
export(Color) var fill_color_dark = Color(0, 0, 0.5)
export(Color) var fill_color_light = Color(0, 0, 1)

# Common output ports
const OUTPUT_PORT_PAD_ACTIVE = 0
const OUTPUT_PORT_XY = 1
const OUTPUT_PORT_X = 2
const OUTPUT_PORT_Y = 3
# DPad specific output ports
const OUTPUT_PORT_AREA_ACTIVE_START = 4
const OUTPUT_PORT_AREA_C_ACTIVE = 4
const OUTPUT_PORT_AREA_N_ACTIVE = 5
const OUTPUT_PORT_AREA_NE_ACTIVE = 6
const OUTPUT_PORT_AREA_E_ACTIVE = 7
const OUTPUT_PORT_AREA_SE_ACTIVE = 8
const OUTPUT_PORT_AREA_S_ACTIVE = 9
const OUTPUT_PORT_AREA_SW_ACTIVE = 10
const OUTPUT_PORT_AREA_W_ACTIVE = 11
const OUTPUT_PORT_AREA_NW_ACTIVE = 12
const OUTPUT_PORT_AREA_SELECTED_START = 13
const OUTPUT_PORT_AREA_C_SELECTED = 13
const OUTPUT_PORT_AREA_N_SELECTED = 14
const OUTPUT_PORT_AREA_NE_SELECTED = 15
const OUTPUT_PORT_AREA_E_SELECTED = 16
const OUTPUT_PORT_AREA_SE_SELECTED = 17
const OUTPUT_PORT_AREA_S_SELECTED = 18
const OUTPUT_PORT_AREA_SW_SELECTED = 19
const OUTPUT_PORT_AREA_W_SELECTED = 20
const OUTPUT_PORT_AREA_NW_SELECTED = 21
const NUM_OUTPUT_PORTS = 22

var mWidgetHost = null

var mOutputPorts = []
var mOutputPortsMeta = {}
var mEmupadConfig = null
var mOn = false
var mPressed = false
var mDPadActiveArea = -1
var mCentroid = null
var mIncenter = null
var mFrameVertices = null
var mIndex = -1
var mGizmo = {
	"center": Vector2(0, 0),
	"target": Vector2(0, 0)
}
 
func _init():
	add_user_signal("pad_pressed")
	add_user_signal("pad_released")
	mOutputPorts.resize(NUM_OUTPUT_PORTS)
	mOutputPortsMeta["pad_active"] = {
		"idx": OUTPUT_PORT_PAD_ACTIVE
	}
	mOutputPortsMeta["xy"] = {
		"idx": OUTPUT_PORT_XY
	}
	mOutputPortsMeta["x"] = {
		"idx": OUTPUT_PORT_X
	}
	mOutputPortsMeta["y"] = {
		"idx": OUTPUT_PORT_Y
	}
	var areas = ["c", "n", "ne", "e", "se", "s", "sw", "w", "nw"]
	for i in range(0, 9):
		mOutputPortsMeta["areas/"+areas[i]+"/active"] = {
			"idx": OUTPUT_PORT_AREA_C_ACTIVE + i
		}
		mOutputPortsMeta["areas/"+areas[i]+"/selected"] = {
			"idx": OUTPUT_PORT_AREA_C_SELECTED + i
		}

func _ready():
	mWidgetHost = get_meta("widget_host_api")

func _exit_tree():
	for output_port in mOutputPorts:
		if output_port != null:
			data_router.remove_port(output_port)

func _create_output_port(port_name):
	var prefix = get_meta("io_ports_path_prefix")
	if prefix == null || !mOutputPortsMeta.has(port_name):
		return
	var port_meta = mOutputPortsMeta[port_name]
	var port_path = prefix+"/"+port_name
	var port = data_router.add_output_port(port_path)
	mOutputPorts[port_meta.idx] = port
	return port

func get_outline_color():
	if mOn:
		if mPressed:
			return pad_color
		else:
			return pad_color.linear_interpolate(Color(0, 0, 0), 0.4)
#			var c = color
#			c.a = 0.8
#			return c
#			return outline_color_dark
	else:
		return Color(0.3, 0.3, 0.3)

func get_fill_color():
	if mOn:
		if mPressed:
			return pad_color.linear_interpolate(Color(0, 0, 0), 0.4)
#			var c = color
#			c.a = 0.8
#			return c
#			return fill_color_light
		else:
			return pad_color.linear_interpolate(Color(0, 0, 0), 0.8)
#			var c = color
#			c.a = 0.6
#			return c
#			return fill_color_dark
	else:
		return Color(0.3, 0.3, 0.3)

func _compute_centroid():
	var centroid = Vector2(0, 0)
	var signed_area = 0.0
	var vertices = get_polygon()
	vertices.push_back(vertices[0])
	for i in range(0, vertices.size() - 1):
		var x0 = vertices[i].x
		var y0 = vertices[i].y
		var x1 = vertices[i+1].x
		var y1 = vertices[i+1].y
		var a = x0*y1 - x1*y0
		signed_area += a
		centroid.x += (x0+x1) * a
		centroid.y += (y0+y1) * a
	signed_area *= 0.5
	centroid.x /= 6.0*signed_area
	centroid.y /= 6.0*signed_area
	return centroid

func _compute_incenter():
	var vertices = get_polygon()
	if vertices.size() != 3:
		return null
	var Ax = vertices[0].x
	var Ay = vertices[0].y
	var Bx = vertices[1].x
	var By = vertices[1].y
	var Cx = vertices[2].x
	var Cy = vertices[2].y
	var a = (vertices[2]-vertices[1]).length()
	var b = (vertices[0]-vertices[2]).length()
	var c = (vertices[1]-vertices[0]).length()
	var p = a + b + c
	var Ox = (a*Ax + b*Bx + c*Cx) / p
	var Oy = (a*Ay + b*By + c*Cy) / p
	return Vector2(Ox, Oy)

func _widget_frame_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	var old_gizmo_target = mGizmo.target
	var old_dpad_active_area = mDPadActiveArea
	if index == mIndex:
		if touch && !event.pressed:
			mIndex = -1
			if mDPadActiveArea >= 0:
				mOutputPorts[OUTPUT_PORT_AREA_SELECTED_START+mDPadActiveArea].put_data(true)
				mOutputPorts[OUTPUT_PORT_AREA_SELECTED_START+mDPadActiveArea].put_data(false)
				mOutputPorts[OUTPUT_PORT_AREA_ACTIVE_START+mDPadActiveArea].put_data(false)
			mDPadActiveArea = -1
			if emulate != "Button" || button_mode == 0:
				mPressed = false
				mOutputPorts[OUTPUT_PORT_PAD_ACTIVE].put_data(false)
				update()
				mWidgetHost.disable_overlay_draw(self)
				emit_signal("pad_released")
		else:
			mGizmo.target = event.pos
			if emulate == "Touchpad":
				mGizmo.center = mGizmo.target
			else:
				var vec = mGizmo.center - mGizmo.target
				if vec.length() > radius:
					mGizmo.center = mGizmo.target + vec.normalized() * radius
	elif touch && event.pressed && has_point(event.pos):
		mIndex = index
		mGizmo.center = event.pos
		mGizmo.target = event.pos
		old_gizmo_target = event.pos
		if emulate == "Button" && button_mode == 1:
			mPressed = !mPressed
		else:
			mPressed = true
		mOutputPorts[OUTPUT_PORT_PAD_ACTIVE].put_data(mPressed)
		if emulate == "DPad":
			mDPadActiveArea = 0
			mOutputPorts[OUTPUT_PORT_AREA_C_ACTIVE].put_data(true)
		update()
		mWidgetHost.enable_overlay_draw(self)
		if mPressed:
			emit_signal("pad_pressed")
		else:
			emit_signal("pad_released")
	mWidgetHost.update_overlay_draw()
	if emulate == "Stick":
		var vec = get_vec()
		mOutputPorts[OUTPUT_PORT_XY].put_data(vec)
		mOutputPorts[OUTPUT_PORT_X].put_data(vec.x)
		mOutputPorts[OUTPUT_PORT_Y].put_data(vec.y)
	elif emulate == "DPad":
		var vec
		if !is_active():
			vec = Vector2(0, 0)
			mDPadActiveArea = -1
		else:
			vec = mGizmo.target - mGizmo.center
			if vec.length() <= threshold:
				vec = Vector2(0, 0)
				mDPadActiveArea = 0
			else:
				var angle = get_vec_angle() + 22.5
				if angle > 360:
					angle = 0
				if angle <= 45:
					vec = Vector2(0, -1)
					mDPadActiveArea = 1
				elif angle <= 90:
					vec = Vector2(1, -1)
					mDPadActiveArea = 2
				elif angle <= 135:
					vec = Vector2(1, 0)
					mDPadActiveArea = 3
				elif angle <= 180:
					vec = Vector2(1, 1)
					mDPadActiveArea = 4
				elif angle <= 225:
					vec = Vector2(0, 1)
					mDPadActiveArea = 5
				elif angle <= 270:
					vec = Vector2(-1, 1)
					mDPadActiveArea = 6
				elif angle <= 325:
					vec = Vector2(-1, 0)
					mDPadActiveArea = 7
				else:
					vec = Vector2(-1, -1)
					mDPadActiveArea = 8
		if mDPadActiveArea != old_dpad_active_area:
			if old_dpad_active_area >= 0:
				mOutputPorts[OUTPUT_PORT_AREA_ACTIVE_START+old_dpad_active_area].put_data(false)
			if mDPadActiveArea >= 0:
				mOutputPorts[OUTPUT_PORT_AREA_ACTIVE_START+mDPadActiveArea].put_data(true)
		mOutputPorts[OUTPUT_PORT_XY].put_data(vec)
		mOutputPorts[OUTPUT_PORT_X].put_data(vec.x)
		mOutputPorts[OUTPUT_PORT_Y].put_data(vec.y)
	elif emulate == "Touchpad":
		var vec = mGizmo.target - old_gizmo_target
		mOutputPorts[OUTPUT_PORT_XY].put_data(vec)
		mOutputPorts[OUTPUT_PORT_X].put_data(vec.x)
		mOutputPorts[OUTPUT_PORT_Y].put_data(vec.y)

func _draw():
	var vertices = Vector2Array()
	vertices.append_array(mFrameVertices)
	var fill_color = get_fill_color()
	draw_colored_polygon(vertices, fill_color)
	vertices.push_back(vertices[0])
	for i in range(0, vertices.size()-1):
		draw_line(vertices[i], vertices[i+1], get_outline_color(), 2)

func _overlay_draw(overlay):
	if !is_active():
		return
	if emulate != "Touchpad":
		overlay.draw_line(get_pos()+get_center(), mGizmo.center, get_outline_color(), 4)
	overlay.draw_circle(mGizmo.center, radius, hi_color)
	overlay.draw_circle(mGizmo.center, radius-2, get_outline_color())
	if emulate == "DPad":
		var v = Vector2(0, radius).rotated(PI/8)
		for i in range(0, 8):
			v = v.rotated(PI/4 * i)
			overlay.draw_line(mGizmo.center, mGizmo.center+v, hi_color, 2)
	if threshold > 0:
		overlay.draw_circle(mGizmo.center, threshold, hi_color)
		overlay.draw_circle(mGizmo.center, threshold-1, get_outline_color())
	var vec = Vector2(0, 0)
	if emulate == "Stick" || emulate == "DPad":
		vec = mGizmo.target - mGizmo.center
		if vec.length() > radius:
			vec = vec.normalized() * radius
	var p = mGizmo.center+vec
	overlay.draw_line(mGizmo.center, p, hi_color, 4)
	overlay.draw_circle(mGizmo.center, 4, hi_color)
	overlay.draw_circle(p, 12, hi_color)

func is_active():
	return mIndex >= 0

func get_center():
	if mIncenter != null:
		return mIncenter
	else:
		return mCentroid

func get_vec_angle():
	var up = Vector2(0, 1)
	var dir = (mGizmo.target - mGizmo.center).normalized()
	var angle = (PI + dir.angle_to(up)) / 2 / PI
	return 360 * angle

func get_vec():
	if !is_active():
		return Vector2(0, 0)
	var vec = mGizmo.target - mGizmo.center
	if vec.length() <= threshold:
		return Vector2(0, 0)
	if emulate == "Stick":
		if vec.length() > radius:
			vec = vec.normalized() * radius
		vec = vec / radius
		return vec
	elif emulate == "DPad":
		var ret 
		var angle = get_vec_angle() + 22.5
		if angle > 360:
			angle = 0
		if angle <= 45:
			ret = Vector2(0, -1)
		elif angle <= 90:
			ret = Vector2(1, -1)
		elif angle <= 135:
			ret = Vector2(1, 0)
		elif angle <= 180:
			ret = Vector2(1, 1)
		elif angle <= 225:
			ret = Vector2(0, 1)
		elif angle <= 270:
			ret = Vector2(-1, 1)
		elif angle <= 325:
			ret = Vector2(-1, 0)
		else:
			ret = Vector2(-1, -1)
		return ret

func load_emupad_config(emupad_config):
	for output_port in mOutputPorts:
		if output_port != null:
			data_router.remove_port(output_port)
	var port
	mEmupadConfig = emupad_config
	button_mode = 0
	if mEmupadConfig.emulate == "stick":
		emulate = "Stick"
		radius = mEmupadConfig.stick_config.radius
		threshold = mEmupadConfig.stick_config.threshold
		for port_name in ["xy", "x", "y"]:
			_create_output_port(port_name)
	elif mEmupadConfig.emulate == "dpad":
		emulate = "DPad"
		radius = mEmupadConfig.dpad_config.radius
		threshold = mEmupadConfig.dpad_config.threshold
		for port_name in ["xy", "x", "y"]:
			_create_output_port(port_name)
		var prefix = get_meta("io_ports_path_prefix")
		for area in ["c", "n", "ne", "e", "se", "s", "sw", "w", "nw"]:
			_create_output_port("areas/"+area+"/active")
			_create_output_port("areas/"+area+"/selected")
			var area_node = data_router.get_output_port(prefix+"/areas/"+area)
			var icon_path = "res://modules/virtual_gamepads/emupad/graphics/icon.dpad.area."+area+".png"
			area_node.set_meta("icon32", load(icon_path))
		var areas_node = data_router.get_output_port(prefix+"/areas")
		var icon_path = "res://modules/virtual_gamepads/emupad/graphics/icon.dpad.areas.png"
		areas_node.set_meta("icon32", load(icon_path))
	elif mEmupadConfig.emulate == "touchpad":
		emulate = "Touchpad"
		radius = 16
		threshold = 0
		for port_name in ["xy", "x", "y"]:
			_create_output_port(port_name)
	else:
		emulate = "Button"
		radius = 16
		threshold = 0
		button_mode = mEmupadConfig.button_config.mode
	_create_output_port("pad_active")

func set_polygon(verts):
	.set_polygon(verts)
	mCentroid = _compute_centroid()
	mIncenter = _compute_incenter()
	mFrameVertices = get_node("polygon_util").shrink_polygon(get_polygon(), 5)
	inic()

func turn_on():
	if mOn == true:
		return
	mOn = true
	mWidgetHost.enable_widget_frame_input(self)
	update()

func turn_off():
	if mOn == false:
		return
	mOn = false
	mWidgetHost.disable_widget_frame_input(self)
	mWidgetHost.disable_overlay_draw(self)
	update()

#-------------------------------------------------------------------------------
# Code below was copied from a post by user "lukas" (https://godotengine.org/qa/user/lukas)
# https://godotengine.org/qa/3160/how-test-whether-point-lies-inside-sprite-collisionobject2d

var poly_corners  =  0 # how many corners the polygon has (no repeats)
var poly_x = [] # horizontal coordinates of corners
var poly_y = [] # vertical coordinates of corners
var constant = [] # storage for precalculated constants (same size as poly_x)
var multiple = [] # storage for precalculated multipliers (same size as poly_x)
var vertices_pos = [] # storage for global coordinates of polygon's vertices

func inic():
	var poly_pos = get_pos() # position of polygon
	var vertices = get_polygon() # local coordiantes of vertices
	poly_corners = vertices.size()
	poly_x.resize(poly_corners)
	poly_y.resize(poly_corners)
	constant.resize(poly_corners)
	multiple.resize(poly_corners)
	vertices_pos.resize(poly_corners)
	for i in range(poly_corners): 
		vertices_pos[i] = poly_pos + vertices[i]
		poly_x[i] = vertices_pos[i].x
		poly_y[i] = vertices_pos[i].y
	precalc_values_has_point(poly_x, poly_y)

func precalc_values_has_point(poly_x, poly_y): # precalculation of constant and multiple
	var j = poly_corners - 1
	for i in range(poly_corners): 
		if poly_y[j] == poly_x[i]:
			constant[i] = poly_y[i]
			multiple[i] = 0.0
		else:
			constant[i] = poly_x[i] - poly_y[i] * poly_x[j] / (poly_y[j] - poly_y[i]) + poly_y[i] * poly_x[i] / (poly_y[j] - poly_y[i])
			multiple[i] = (poly_x[j] - poly_x[i]) / (poly_y[j] - poly_y[i])
		j = i

func has_point(point):
	var x = point.x
	var y = point.y
	var j = poly_corners - 1
	var odd_nodes = 0
	for i in range(poly_corners): 
		if (poly_y[i] < y and poly_y[j] >= y) or (poly_y[j] < y and poly_y[i] >= y):
			if y * multiple[i] + constant[i] < x:
				odd_nodes += 1
		j = i
	if odd_nodes % 2 == 0:
		return false
	else:
		return true
