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

extends Panel

onready var _desktop = get_node("hsplit/desktop")
onready var _taskbar = get_node("vsplit/hsplit2/taskbar")

func _ready():
	var isquare_size = rcos.get_isquare_size()
	var isquare = Vector2(isquare_size, isquare_size)
	get_node("hsplit/sidebar").set_custom_minimum_size(isquare)
	get_node("vsplit/hsplit1").set_custom_minimum_size(isquare)
	get_node("vsplit/hsplit1/rcos_panel").set_custom_minimum_size(isquare)
	get_node("vsplit/hsplit2/taskbar").set_custom_minimum_size(isquare)
	var wm
	if true || OS.get_model_name() == "GenericDevice":
		OS.set_screen_orientation(OS.SCREEN_ORIENTATION_LANDSCAPE)
		wm = rlib.instance_scene("res://rcos_core/zem_gui/wm2/wm2.tscn")
	else:
		var num_isquares_x = get_size().x / isquare_size
		var num_isquares_y = get_size().y / isquare_size
		if num_isquares_x >= 10 && num_isquares_y >= 10:
			wm = rlib.instance_scene("res://rcos_core/zem_gui/wm2/wm2.tscn")
		else:
			wm = rlib.instance_scene("res://rcos_core/zem_gui/wm1/wm1.tscn")
	_desktop.get_node("wm").add_child(wm)
	wm.initialize(self)
	rcos.enable_canvas_input(self)

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	var dangling_control = rcos_gui.get_dangling_control(index)
	if dangling_control == null:
		return
	dangling_control.set_pos(event.pos - dangling_control.get_size()/2)
	if _taskbar.get_rect().has_point(event.pos):
		_taskbar.activate_task_by_pos(event.pos)
