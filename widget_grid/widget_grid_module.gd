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

var mWidgetGridGuis = []
var mWidgetFactoryTasks = []

func _ready():
	_log_debug("_ready()")
	create_widget_grid()
	rcos.connect("task_added", self, "_on_task_added")
	rcos.connect("task_removed", self, "_on_task_removed")
#	var modules = rcos.get_modules()
#	for module_id in modules.keys():
#		var module = modules[module_id]
#		prints(module_id, module.get_name())
	var task_list = rcos.get_task_list()
	for task in task_list:
		_on_task_added(task)
	_log_notice("Ready")

func _log_debug(content):
	rcos.log_debug(self, content)

func _log_notice(content):
	rcos.log_notice(self, content)

func _log_error(content):
	rcos.log_error(self, content)

func _on_task_changed(task):
	return

func _on_task_added(task):
	if !task.has("type") || task.type != "widget_factory":
		return
	if mWidgetFactoryTasks.has(task):
		return
	mWidgetFactoryTasks.push_back(task)
	for grid_widget_gui in mWidgetGridGuis:
		grid_widget_gui.update_available_widgets(mWidgetFactoryTasks)

func _on_task_removed():
	pass

func create_widget_grid():
	var canvas = rlib.instance_scene("res://rcos/lib/canvas.tscn")
	canvas.min_size = Vector2(200, 80)
	get_node("canvases").add_child(canvas)
	var gui = rlib.instance_scene("res://widget_grid/gui.tscn")
	canvas.add_child(gui)
	gui.init(self)
	var task_properties = {
		"name": "Widget Grid",
		"icon": get_node("icon").get_texture(),
		"canvas": canvas,
		"ops": {
			"kill": funcref(gui, "kill"),
			"go_back": funcref(gui, "go_back")
		}
	}
	rcos.add_task(task_properties)
	mWidgetGridGuis.push_back(gui)

func get_widget_tasks():
	return mWidgetFactoryTasks
