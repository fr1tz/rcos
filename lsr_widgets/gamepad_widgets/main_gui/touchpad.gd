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

export(String, "Stick", "DPad", "Button") var mode
export(int) var radius = 64
export(int) var threshold = 0
export(Color) var hi_color = Color(1, 1, 1)
export(Color) var fg_color = Color(0, 0, 1)
export(Color) var bg_color = Color(0, 0, 0.5)

var mWidgetHost = null

var mOutputPorts = {}
var mTouchpadConfig = null
var mOn = false
var mCentroid = null
var mIncenter = null
var mFrameVertices = null
var mIndex = -1
var mGizmo = {
	"center": Vector2(0, 0),
	"target": Vector2(0, 0)
}
 
func _init():
	pass

func _ready():
	mWidgetHost = get_meta("widget_host_api")

func _exit_tree():
	for output_port in mOutputPorts.values():
		data_router.remove_port(output_port)

func _get_fg_color():
	if mOn:
		return fg_color
	else:
		return Color(0.3, 0.3, 0.3)

func _get_bg_color():
	if mOn:
		return bg_color
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

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if index == mIndex:
		if touch && !event.pressed:
			mIndex = -1
			mOutputPorts["pressed"].put_data(false)
			mWidgetHost.disable_overlay_draw(self)
		else:
			mGizmo.target = event.pos
			var vec = mGizmo.center - mGizmo.target
			if vec.length() > radius:
				mGizmo.center = mGizmo.target + vec.normalized() * radius
	elif touch && event.pressed && has_point(event.pos):
		mIndex = index
		mGizmo.center = event.pos
		mGizmo.target = mGizmo.center
		mOutputPorts["pressed"].put_data(true)
		mWidgetHost.enable_overlay_draw(self)
	mWidgetHost.update_overlay_draw()
	if mode == "Stick" || mode == "DPad":
		var vec = get_vec()
		mOutputPorts["x"].put_data(vec.x)
		mOutputPorts["y"].put_data(vec.y)


func _draw():
	_draw_frame()

func _draw_frame():
	var vertices = mFrameVertices
	if mOn:
		var color = _get_bg_color()
		color.a = 0.5
		draw_colored_polygon(vertices, color)
	vertices.push_back(vertices[0])
	for i in range(0, vertices.size()-1):
		draw_line(vertices[i], vertices[i+1], _get_bg_color(), 2)

func _overlay_draw(overlay):
	if !is_active():
		return
	overlay.draw_line(get_global_pos()+get_center(), mGizmo.center, _get_fg_color(), 4)
	overlay.draw_circle(mGizmo.center, radius, hi_color)
	overlay.draw_circle(mGizmo.center, radius-2, _get_fg_color())
	if mode == "DPad":
		var v = Vector2(0, radius).rotated(PI/8)
		for i in range(0, 8):
			v = v.rotated(PI/4 * i)
			overlay.draw_line(mGizmo.center, mGizmo.center+v, hi_color, 2)
	if threshold > 0:
		overlay.draw_circle(mGizmo.center, threshold, hi_color)
		overlay.draw_circle(mGizmo.center, threshold-1, _get_fg_color())
	var vec = Vector2(0, 0)
	if mode == "Stick" || mode == "DPad":
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
	if mode == "Stick":
		if vec.length() > radius:
			vec = vec.normalized() * radius
		vec = vec / radius
		return vec
	elif mode == "DPad":
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

func load_touchpad_config(touchpad_config):
	for output_port in mOutputPorts.values():
		data_router.remove_port(output_port)
	var widget_id = str(get_meta("widget_id"))
	var port_path_prefix = "local/gamepad_widget"+widget_id+"/"+get_parent().get_name()
	mTouchpadConfig = touchpad_config
	if mTouchpadConfig.mode == "stick":
		mode = "Stick"
		radius = mTouchpadConfig.stick_config.radius
		threshold = mTouchpadConfig.stick_config.threshold
		mOutputPorts["x"] = data_router.add_output_port(port_path_prefix+"/x")
		mOutputPorts["y"] = data_router.add_output_port(port_path_prefix+"/y")
	elif mTouchpadConfig.mode == "dpad":
		mode = "DPad"
		radius = mTouchpadConfig.dpad_config.radius
		threshold = mTouchpadConfig.dpad_config.threshold
		mOutputPorts["x"] = data_router.add_output_port(port_path_prefix+"/x")
		mOutputPorts["y"] = data_router.add_output_port(port_path_prefix+"/y")
	else:
		mode = "Button"
		radius = 16
		threshold = 0
	mOutputPorts["pressed"] = data_router.add_output_port(port_path_prefix+"/pressed")

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
	mWidgetHost.enable_canvas_input(self)
	update()

func turn_off():
	if mOn == false:
		return
	mOn = false
	mWidgetHost.disable_canvas_input(self)
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
	var poly_pos = get_global_pos() # global position of polygon
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
