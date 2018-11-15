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

var mTaskId = -1
var mParentTaskId = -1

func _init():
	add_user_signal("selected")

func _ready():
	get_node("square/button").connect("pressed", self, "emit_signal", ["selected"])

func get_task_id():
	return mTaskId

func get_parent_task_id():
	return mParentTaskId

func set_task_id(task_id):
	mTaskId = task_id

func set_parent_task_id(parent_task_id):
	mParentTaskId = parent_task_id

func set_title(string):
	get_node("title").set_text(string)

func show_title():
	get_node("title").show()

func hide_title():
	get_node("title").hide()

func set_task_color(color):
	if color == null: color = Color(0, 0, 0, 0)
	get_node("square/task_color").set_frame_color(color)

func set_icon(texture):
	if texture == null:
		return
	get_node("square/center/icon").set_texture(texture)

func set_icon_frame_color(color):
	if color == null: color = Color(0, 0, 0, 0)
	get_node("square/icon_frame").set_modulate(color)

func set_icon_label(text):
	if text == null: text = ""
	get_node("square/icon_label").set_text(text)

func set_icon_spin_speed(speed):
	get_node("square/center/icon").set_spin_speed(speed)

func mark_active():
	get_node("square/button_down").show()

func mark_inactive():
	get_node("square/button_down").hide()
