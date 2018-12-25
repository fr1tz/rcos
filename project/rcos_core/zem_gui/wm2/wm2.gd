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

extends ReferenceFrame

onready var _windows_group = "wm2_windows_"+str(get_instance_ID())
onready var _windows = get_node("windows")
onready var _reshape_hud = get_node("reshape_hud")

var _zem = null
var _windows_by_canvas = {}
var _index_to_control = []

func _ready():
	for i in range(0, 8):
		_index_to_control.push_back(null)
	rcos.connect("task_added", self, "_on_task_added")
	rcos.connect("task_removed", self, "_on_task_removed")
	rcos_gui.connect("active_canvas_changed", self, "_active_canvas_changed")
	rcos.enable_canvas_input(self)

func _canvas_input(event):
	if !_reshape_hud.is_hidden():
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	var input_control = null
	if touch:
		if event.pressed:
			var n = _windows.get_child_count() - 1
			while n >= 0:
				var win = _windows.get_child(n)
				if !win.is_hidden() && win.get_global_rect().has_point(event.pos):
					rcos_gui.set_active_canvas(win._task.properties.canvas)
					if win._canvas_display.get_global_rect().has_point(event.pos):
						input_control = win._canvas_display
					else:
						input_control = win
					_index_to_control[index] = input_control
					break
				n -= 1
		else:
			input_control = _index_to_control[index]
			_index_to_control[index] = null
	else:
		input_control = _index_to_control[index]
	if input_control:
		input_control._canvas_input(event)

func _active_canvas_changed(canvas):
	get_tree().call_group(SceneTree.GROUP_CALL_REALTIME, _windows_group, "__mark_inactive")
	if canvas != null:
		var active_window = _windows_by_canvas[canvas]
		active_window.__mark_active()

func _on_task_added(task):
	if task.properties.has("canvas"):
		var win = rlib.instance_scene("res://rcos_core/zem_gui/wm2/decorated_window.tscn")
		get_node("windows").add_child(win)
		win.add_to_group(_windows_group)
		win.initialize(self, task)
		_windows_by_canvas[task.properties.canvas] = win

func _on_task_removed(task):
	if task.properties.has("canvas"):
		var win = _windows_by_canvas[task.properties.canvas]
		get_node("windows").remove_child(win)
		_windows_by_canvas.erase(win)
		win.free()

func _reshape_window_begin(win):
	var cursor = load("res://rcos_core/zem_gui/graphics/cursor_reshape.png")
	rcos_gui.change_mouse_cursor(cursor, Vector2(14, 14))
	win.set_hidden(true)
	var isquare_size = rcos.get_isquare_size()
	var screen_size = get_size()
	var num_columns = int(floor(screen_size.x/isquare_size))
	var num_rows = int(floor(screen_size.y/isquare_size))
	_reshape_hud.set_grid(num_columns, num_rows)
	_reshape_hud.clear_painted_rect()
	_reshape_hud.connect("finished", self, "_reshape_window_finish", [win])
	_reshape_hud.set_hidden(false)

func _reshape_window_finish(win):
	rcos_gui.reset_mouse_cursor()
	_reshape_hud.disconnect("finished", self, "_reshape_window_finish")
	_reshape_hud.set_hidden(true)
	var rect = _reshape_hud.get_painted_rect()
	win.set_pos(rect.pos)
	win.set_size(rect.size)
	win.set_hidden(false)
	raise_window(win)

func raise_window(win):
	_windows.move_child(win, _windows.get_child_count()-1)

func reshape_window(win):
	_reshape_window_begin(win)
