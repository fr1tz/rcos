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

extends ColorFrame

const MODE_NONE = -1
const MODE_CHECK_MOVE = 1
const MODE_MOVE = 2
const MODE_RESHAPE = 3
const MODE_TOGGLE_MAXIMIZED = 4
const MODE_RESIZE = 5
const MODE_HIDE = 6

const ICON_MAXIMIZE = "" # Unicode character #f31e between quotes
const ICON_UNMAXIMIZE = "" # Unicode character #f78c between quotes

var _cursor_move = load("res://rcos_core/zem_gui/graphics/cursor_move.png")

onready var _margins = get_node("margins")
onready var _canvas_display = _margins.get_node("vbox/canvas_display")
onready var _title_bar = _margins.get_node("vbox/titlebar")
onready var _icon = _title_bar.get_node("hbox/icon_box/icon")
onready var _icon_frame = _title_bar.get_node("hbox/icon_box/frame")
onready var _icon_label = _title_bar.get_node("hbox/icon_box/label")
onready var _title_label = _title_bar.get_node("hbox/title_label")
onready var _reshape_button = _title_bar.get_node("hbox/reshape_button")
onready var _resize_button = _title_bar.get_node("hbox/resize_button")
onready var _hide_button = _title_bar.get_node("hbox/hide_button")

var _wm = null
var _task = null
var _taskId = -1
var _task_color = Color(1, 1, 1, 0)
var _active = false
var _unmaximized_pos = null
var _unmaximized_size = null
var _active_index = -1
var _mode = MODE_NONE
var _initial_touch_pos = null

func _init():
	add_user_signal("hide_button_pressed")
	add_user_signal("reshape_button_pressed")
	add_user_signal("close_button_pressed")

func _ready():
	var isquare = rcos_gui.get_isquare()
	_title_bar.set_custom_minimum_size(isquare)
	for c in _title_bar.get_node("hbox").get_children():
		c.set_custom_minimum_size(isquare)

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if _active_index == -1:
		if touch && event.pressed:
			_active_index = index
			_initial_touch_pos = event.pos
			raise_window()
			if _reshape_button.get_global_rect().has_point(event.pos):
				_mode = MODE_RESHAPE
			elif _resize_button.get_global_rect().has_point(event.pos):
				_mode = MODE_TOGGLE_MAXIMIZED
			elif _hide_button.get_global_rect().has_point(event.pos):
				_mode = MODE_HIDE
			elif _title_bar.get_global_rect().has_point(event.pos):
				_mode = MODE_CHECK_MOVE
			else:
				_mode = MODE_RESIZE
	elif index == _active_index:
		if _mode == MODE_CHECK_MOVE:
			if (event.pos - _initial_touch_pos).length() > 4:
				_mode = MODE_MOVE
				if index == 0:
					rcos_gui.change_mouse_cursor(_cursor_move, Vector2(16, 16))
		elif _mode == MODE_RESHAPE:
			if _reshape_button.get_global_rect().has_point(event.pos):
				if touch && !event.pressed:
					reshape_window()
		elif _mode == MODE_TOGGLE_MAXIMIZED:
			if _resize_button.get_global_rect().has_point(event.pos):
				if touch && !event.pressed:
					toggle_window_maximized()
			else:
				_mode = MODE_RESIZE
				if index == 0:
					rcos_gui.change_mouse_cursor(_cursor_move, Vector2(16, 16))
		elif _mode == MODE_HIDE:
			if _hide_button.get_global_rect().has_point(event.pos):
				if touch && !event.pressed:
					hide_window()
		elif _mode == MODE_MOVE:
			if drag:
				set_pos(get_pos() + event.relative_pos)
			elif touch && !event.pressed:
				if index == 0:
					rcos_gui.reset_mouse_cursor()
		if touch && !event.pressed:
			_active_index = -1

func _update_decoration():
	set_frame_color(Color(1, 1, 1))
	_icon_frame.set_modulate(_task_color)
	if _active:
		_title_bar.set_frame_color(Color(0.0, 0.0, 0.0))
		var c = Color(1, 1, 1)
		_title_label.set("custom_colors/font_color", c)
		_reshape_button.set("custom_colors/font_color", c)
		_resize_button.set("custom_colors/font_color", c)
		_hide_button.set("custom_colors/font_color", c)
	else:
		_title_bar.set_frame_color(Color(0.25, 0.25, 0.25))
		var c = Color(0.5, 0.5, 0.5)
		_title_label.set("custom_colors/font_color", c)
		_reshape_button.set("custom_colors/font_color", c)
		_resize_button.set("custom_colors/font_color", c)
		_hide_button.set("custom_colors/font_color", c)

func _set_border_width(width):
	for margin in ["right", "left", "top", "bottom"]:
		_margins.set("custom_constants/margin_"+margin, width)

func _task_properties_changed(new_properties):
	#print(_task.properties)
	if new_properties.has("name"):
		_title_label.set_text(" "+new_properties.name)
	if new_properties.has("task_color"):
		_task_color = _task.properties.task_color
		_update_decoration()
	if new_properties.has("icon"):
		_icon.set_texture(new_properties.icon)
	if new_properties.has("icon_label"):
		_icon_label.set_text(new_properties.icon_label)
	if new_properties.has("window_hidden"):
		set_hidden(_task.properties.window_hidden)
	if new_properties.has("window_maximized"):
		if new_properties.window_maximized:
			set_pos(_wm.get_pos())
			set_size(_wm.get_size())
			_resize_button.set_text(ICON_UNMAXIMIZE)
			_set_border_width(0)
		else:
			set_pos(_unmaximized_pos)
			set_size(_unmaximized_size)
			_resize_button.set_text(ICON_MAXIMIZE)
			_set_border_width(2)
	# Actions
	if new_properties.has("/raise_window"):
		_task.properties.erase("/raise_window")
		raise_window()
	if new_properties.has("/maximize_window"):
		_task.properties.erase("/maximize_window")
		maximize_window()
	if new_properties.has("/unmaximize_window"):
		_task.properties.erase("/unmaximize_window")
		unmaximize_window()
	if new_properties.has("/toggle_window_maximized"):
		_task.properties.erase("/toggle_window_maximized")
		toggle_window_maximized()
	if new_properties.has("/hide_window"):
		_task.properties.erase("/hide_window")
		hide_window()
	if new_properties.has("/focus_window"):
		_task.properties.erase("/focus_window")
		focus_window()

func _canvas_display_resized():
	var properties = rcos.get_task_properties(_taskId)
	var canvas = properties.canvas
	if !canvas.resizable:
		return
	var win_size = _canvas_display.get_size()
	var isquare_size = rcos_gui.get_isquare_size()
	var canvas_min_size_x = canvas.min_size_isquares.x * isquare_size
	var canvas_min_size_y = canvas.min_size_isquares.y * isquare_size
	var new_canvas_size = Vector2(0, 0)
	new_canvas_size.x = max(win_size.x, canvas_min_size_x)
	new_canvas_size.y = max(win_size.y, canvas_min_size_y)
	canvas.resize(new_canvas_size)

func __mark_active():
	_active = true
	_update_decoration()

func __mark_inactive():
	_active = false
	_update_decoration()

func get_task():
	return _task

func raise_window():
	_wm.raise_window(self)

func reshape_window():
	if is_maximized():
		unmaximize_window()
	_wm.reshape_window(self)

func is_maximized():
	return _task.properties.has("window_maximized") && _task.properties.window_maximized

func maximize_window():
	_unmaximized_pos = get_pos()
	_unmaximized_size = get_size()
	_task.change_properties({"window_maximized": true})

func unmaximize_window():
	_task.change_properties({"window_maximized": false})

func toggle_window_maximized():
	if is_maximized():
		unmaximize_window()
	else:
		maximize_window()

func hide_window():
	if rcos_gui.get_active_canvas() == _task.properties.canvas:
		rcos_gui.set_active_canvas(null)
	_task.change_properties({"window_hidden": true})

func focus_window():
	_task.change_properties({"window_hidden": false})
	_wm.raise_window(self)
	rcos_gui.set_active_canvas(_task.properties.canvas)

func initialize(wm, task):
	_wm = wm
	_task = task
	_taskId = task.get_id()
#	var color = Color(randf(), randf(), randf())
#	set_frame_color(color)
#	_title_label.set("custom_colors/font_color", color)
	var border_width = 3
	_set_border_width(3)
	_update_decoration()
	var canvas = _task.properties.canvas
	var isquare_size = rcos.get_isquare_size()
	var canvas_min_size_x = canvas.min_size_isquares.x * isquare_size
	var canvas_min_size_y = canvas.min_size_isquares.y * isquare_size
	var min_size = Vector2(canvas_min_size_x+border_width*2, canvas_min_size_y+isquare_size+border_width*2)
	set_custom_minimum_size(min_size)
	var canvas_default_size_x = canvas.default_size_isquares.x * isquare_size
	var canvas_default_size_y = canvas.default_size_isquares.y * isquare_size
	var size = Vector2(canvas_default_size_x+border_width*2, canvas_default_size_y+isquare_size+border_width*2)
	_unmaximized_size = size
	set_size(size)
	_task_properties_changed(_task.properties)
	_task.connect("properties_changed", self, "_task_properties_changed")
	if canvas == rcos_gui.get_active_canvas():
		__mark_active()
	else:
		__mark_inactive()
	_canvas_display.connect("resized", self, "_canvas_display_resized")
	_canvas_display.show_canvas(canvas)
