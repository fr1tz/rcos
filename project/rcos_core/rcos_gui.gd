# Copyright © 2017, 2018 Michael Goldener <mg@wasted.ch>
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

extends ColorFrame

var __ActiveCanvas = null 
var _isquare_size = 40
var _default_mouse_cursor_texture = null
var _default_mouse_cursor_hotspot = Vector2(0, 0)
var _dangling_controls = {}

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_escape()

func _escape():
	if __ActiveCanvas == null:
		return
	var task = rcos.get_task_from_canvas(__ActiveCanvas)
	if task == null:
		return
	if task.properties.has("ops") && task.properties.ops.has("go_back"):
		var ret = task.properties.ops["go_back"].call_func()
		if ret:
			return
	get_tree().quit()

func _init():
	add_user_signal("active_canvas_changed")

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var color = Globals.get("application/boot_bg_color")
	set_frame_color(color)

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if !_dangling_controls.has(index):
		return
	var dangling_control = _dangling_controls[index]
	dangling_control.set_pos(event.pos - dangling_control.get_size()/2)
	if touch && !event.pressed:
		get_node("dangling_controls").remove_child(dangling_control)
		dangling_control.free()
		_dangling_controls.erase(index)
		if _dangling_controls.size() == 0:
			rcos.disable_canvas_input(self)

func _clear_active_canvas():
	__ActiveCanvas = null
	emit_signal("active_canvas_changed", null)

func get_isquare_size():
	return _isquare_size

func get_isquare():
	return Vector2(_isquare_size, _isquare_size)

func set_isquare_size(size):
	_isquare_size = size

func set_active_canvas(canvas):
	if canvas == __ActiveCanvas:
		return
	if __ActiveCanvas != null:
		__ActiveCanvas.disconnect("exit_tree", self, "_clear_active_canvas")
	__ActiveCanvas = canvas
	if __ActiveCanvas != null:
		__ActiveCanvas.connect("exit_tree", self, "_clear_active_canvas")
	emit_signal("active_canvas_changed", __ActiveCanvas)

func get_active_canvas():
	return __ActiveCanvas

func get_default_mouse_cursor():
	return [_default_mouse_cursor_texture, _default_mouse_cursor_hotspot]

func set_default_mouse_cursor(tex, hotspot):
	if tex == _default_mouse_cursor_texture && hotspot == _default_mouse_cursor_hotspot:
		return
	_default_mouse_cursor_texture = tex
	_default_mouse_cursor_hotspot = hotspot
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, hotspot)

func change_mouse_cursor(tex, hotspot):
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, hotspot)

func reset_mouse_cursor():
	Input.set_custom_mouse_cursor(_default_mouse_cursor_texture, Input.CURSOR_ARROW, _default_mouse_cursor_hotspot)

func pick_up_control(control, index): # deprecated
	set_dangling_control(index, control)

func set_dangling_control(index, control):
	if control == null:
		return
	# Don't "pick up" the control if the screen isn't touched.
	var pos = get_viewport().get_screen_touch_pos(index)
	if pos == null:
		control.queue_free()
		return
	if _dangling_controls.has(index):
		var old_control = _dangling_controls[index]
		get_node("dangling_controls").remove_child(old_control)
		old_control.queue_free()
		_dangling_controls.erase(index)
	control.get_parent().remove_child(control)
	get_node("dangling_controls").add_child(control)
	control.set_pos(pos - control.get_size()/2)
	_dangling_controls[index] = control
	if _dangling_controls.size() > 0:
		rcos.enable_canvas_input(self)
	else:
		rcos.disable_canvas_input(self)

func get_dangling_control(index):
	if _dangling_controls.has(index):
		return _dangling_controls[index]
	else:
		return null
