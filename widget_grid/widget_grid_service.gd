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

var _module = null

var mWidgetFactoryTasks = []

func _init():
	add_user_signal("widget_factory_tasks_changed")

func _ready():
	rcos.connect("task_added", self, "_on_task_added")
	rcos.connect("task_removed", self, "_on_task_removed")
	var task_list = rcos.get_task_list()
	for task in task_list.values():
		_on_task_added(task)

func _on_task_changed(task):
	return

func _on_task_added(task):
	if !task.properties.has("type") || task.properties.type != "widget_factory":
		return
	if mWidgetFactoryTasks.has(task.get_id()):
		return
	mWidgetFactoryTasks.push_back(task.get_id())
	emit_signal("widget_factory_tasks_changed", mWidgetFactoryTasks)

func _on_task_removed():
	return

func get_widget_factory_tasks():
	return mWidgetFactoryTasks

func add_widget_grid_editor():
	_module.add_widget_grid_editor()
