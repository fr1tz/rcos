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

extends ReferenceFrame

var _task = null
var _parent_task_id = -1

func _ready():
	get_node("square/button").connect("pressed", self, "_pressed")

func _pressed():
#	print(_task.properties.name)
	var new_properties
	if rcos_gui.get_active_canvas() != _task.properties.canvas:
		_task.change_properties({"/focus_window": null})
	else:
		if _task.properties.has("window_hidden") && _task.properties.window_hidden:
			_task.change_properties({"/focus_window": null})
		else:
			rcos_gui.set_active_canvas(null)
			_task.change_properties({"/hide_window": null})

func _task_properties_changed(new_properties):
	if new_properties.has("name"):
		_set_title(new_properties.name)
	if new_properties.has("task_color"):
		_set_task_color(new_properties.task_color)
	if new_properties.has("icon"):
		_set_icon(new_properties.icon)
	if new_properties.has("icon_label"):
		_set_icon_label(new_properties.icon_label)
	if new_properties.has("icon_frame_color"):
		_set_icon_frame_color(new_properties.icon_frame_color)
	if new_properties.has("icon_spin_speed"):
		_set_icon_spin_speed(new_properties.icon_spin_speed)
	if new_properties.has("window_hidden"):
		if new_properties.window_hidden:
			get_node("square").set_opacity(0.5)
		else:
			get_node("square").set_opacity(1.0)

func _set_title(string):
	get_node("title").set_text(string)

func _set_task_color(color):
	if color == null: color = Color(0, 0, 0, 0)
	get_node("square/task_color").set_frame_color(color)

func _set_icon(texture):
	if texture == null:
		return
	get_node("square/icon_box/icon").set_texture(texture)

func _set_icon_frame_color(color):
	if color == null: color = Color(0, 0, 0, 0)
	get_node("square/icon_box/frame").set_modulate(color)

func _set_icon_label(text):
	if text == null: text = ""
	get_node("square/icon_box/label").set_text(text)

func _set_icon_spin_speed(speed):
	return

func show_title():
	get_node("title").show()

func hide_title():
	get_node("title").hide()

func mark_active():
	get_node("square/button_down").show()

func mark_inactive():
	get_node("square/button_down").hide()

func get_task_id():
	return _task.get_id()

func get_parent_task_id():
	return _task.get_parent_task_id()

func initialize(task):
	_task = task
	_set_title("Unnamed Task")
	_set_task_color(null)
	_set_icon(null)
	_set_icon_label(null)
	_set_icon_frame_color(null)
	_set_icon_spin_speed(0)
	_task_properties_changed(_task.properties)
	_task.connect("properties_changed", self, "_task_properties_changed")
