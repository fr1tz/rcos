# Copyright © 2018 Michael Goldener <mg@wasted.ch>
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

onready var content = get_node("canvas").get_child(0)

var mModule = null
var mPanelId = -1
var mTaskId = -1
var mMainWindowTaskId = -1
var mWindowTitle = "Widget Panel"

func _exit_tree():
	rcos.remove_task(mTaskId)

func show():
	if mTaskId != -1:
		return
	var task_properties = {
		"name": mWindowTitle,
		"icon": get_node("icon").get_texture(),
		"icon_label": str(mPanelId),
		"canvas": get_node("canvas"),
		"ops": {
			"kill": funcref(mModule, "kill"),
			"go_back": funcref(content, "go_back")
		}
	}
	mTaskId = rcos.add_task(task_properties, mMainWindowTaskId)

func hide():
	if mTaskId == -1:
		return
	rcos.remove_task(mTaskId)
	mTaskId = -1

func set_title(title):
	mWindowTitle = title
	if mTaskId == -1:
		var new_task_properties = {
			"name": mWindowTitle
		}
		rcos.change_task(mTaskId, new_task_properties)

func set_fullscreen(fullscreen):
	if fullscreen:
		var new_task_properties = {
			#"canvas_region": get_node("grid_area").get_global_rect(),
			"fullscreen": true
		}
		rcos.change_task(mTaskId, new_task_properties)
		return true
	else:
		var properties = rcos.get_task_properties(mTaskId)
		if properties.has("fullscreen") && properties.fullscreen:
			var new_task_properties = {
				"canvas_region": null,
				"fullscreen": false
			}
			rcos.change_task(mTaskId, new_task_properties)
			return true
	return false

func get_task_id():
	return mTaskId

func initialize(module, panel_id, main_window_task_id):
	set_name("widget_panel_"+str(panel_id)+"_window")
	mModule = module
	mPanelId = panel_id
	mMainWindowTaskId = main_window_task_id
	content.initialize(module, self, panel_id)
