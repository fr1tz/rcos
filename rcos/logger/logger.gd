# Copyright © 2017 Michael Goldener <mg@wasted.ch>
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

func _ready():
	mTaskId = rcos.add_task()
	var task_name = "Logger"
	var task_icon = get_node("icon").get_texture()
	var task_canvas = get_node("canvas")
	var task_ops = [
		[ "kill", funcref(self, "kill") ]
	]
	rcos.set_task_name(mTaskId, task_name)
	rcos.set_task_icon(mTaskId, task_icon)
	rcos.set_task_canvas(mTaskId, task_canvas)
	rcos.set_task_ops(mTaskId, task_ops)
	rcos.connect("new_log_entry3", self, "_on_new_log_entry")

func _on_new_log_entry(source_node, level, content):
	var source_path = str(source_node.get_path())
	if source_path.begins_with("/root/rcos"):
		source_path = source_path.right(6)
	content = str(content).replace("\n", "\n  ")
	var entry = level + " " + source_path + "\n  " + content + "\n"

func kill():
	rcos.log_debug(self, ["kill()"])
	rcos.remove_task(mTaskId)
	queue_free()
