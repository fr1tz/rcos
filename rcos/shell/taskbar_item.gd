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

func _init():
	add_user_signal("selected")

func _ready():
	get_node("button").connect("pressed", self, "emit_signal", ["selected"])

func get_task_id():
	return mTaskId

func set_task_id(task_id):
	mTaskId = task_id

func set_title(string):
	get_node("title").set_text(string)

func set_icon(texture):
	if texture == null:
		return
	get_node("icon").set_texture(texture)

func show_title():
	get_node("title").show()

func hide_title():
	get_node("title").hide()

func mark_active():
	get_node("button_down").show()

func mark_inactive():
	get_node("button_down").hide()
