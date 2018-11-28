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

const CONFIG_DIR = "user://etc/widget_panels"

onready var mMainWindow = get_node("main_window")
onready var mWidgetPanelWindows = get_node("widget_panel_windows")

func _ready():
	var dir = Directory.new()
	if !dir.dir_exists(CONFIG_DIR):
		dir.make_dir_recursive(CONFIG_DIR)
	mMainWindow.initialize(self)
	mMainWindow.show()
	mMainWindow.content.load_config_file()

func create_widget_panel_window(widget_panel_id):
	var panel_window = rlib.instance_scene("res://modules/widget_panels/panel_window/widget_panel_window.tscn")
	mWidgetPanelWindows.add_child(panel_window)
	panel_window.initialize(self, widget_panel_id, mMainWindow.get_task_id())
	return panel_window

func destroy_widget_panel_window(panel_window):
	if panel_window.get_parent() == mWidgetPanelWindows:
		mWidgetPanelWindows.remove_child(panel_window)
		panel_window.free()
