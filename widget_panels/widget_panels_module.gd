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

onready var mMainGuiTaskNode = get_node("main_gui_task")
onready var mWidgetPanelTaskNodes = get_node("widget_panel_tasks")

func _ready():
	get_node("main_gui_task").show()
	get_node("main_gui_task").get_gui().initialize(self)

func show_widget_panel(id, label):
	var panel_task = rlib.instance_scene("res://widget_panels/widget_panel/widget_panel_task.tscn")
	mWidgetPanelTaskNodes.add_child(panel_task)
	panel_task.initialize(id, label, mMainGuiTaskNode.get_task_id())

func hide_widget_panel(id):
	var panel_task_name = "widget_panel_"+str(id)+"_task"
	if mWidgetPanelTaskNodes.has_node(panel_task_name):
		var panel_task_node = mWidgetPanelTaskNodes.get_node(panel_task_name)
		mWidgetPanelTaskNodes.remove_child(panel_task_node)
		panel_task_node.free()
