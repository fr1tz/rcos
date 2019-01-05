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
var mFilter = null

func _ready():
	var task_properties = {
		"name": "Logger",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos_tasks.add_task(task_properties)
	rcos_log.connect("new_log_entry3", self, "_on_new_log_entry")

func _on_new_log_entry(source_node, level, content):
	var source_path = str(source_node.get_path())
	if source_path.begins_with("/root/rcos"):
		source_path = source_path.right(6)
	source_path = "[color=grey]" + source_path + "[/color]"
	content = str(content)
	if level == "error":
		content = "[color=red]"+content+"[/color]"
	elif level == "notice":
		content = "[color=orange]"+content+"[/color]"
	var entry = source_path + "\n" + content + "\n"
	if mFilter != null:
		if entry.find(mFilter) == -1:
			return
		entry = content + "\n"
	get_node("canvas/logger_gui/log").add_entry(entry)

func kill():
	rcos_log.debug(self, ["kill()"])
	rcos_tasks.remove_task(mTaskId)
	queue_free()

func set_filter(expr):
	mFilter = expr
