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

extends Node

var mTaskId = -1

func _exit_tree():
	hide()

func show():
	if mTaskId != -1:
		return
	var task_properties = {
		"name": "Widget Panels",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos.add_task(task_properties)

func hide():
	if mTaskId == -1:
		return
	rcos.remove_task(mTaskId)
	mTaskId = -1

func get_task_id():
	return mTaskId

func get_gui():
	return get_node("canvas").get_child(0)
