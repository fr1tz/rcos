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

var gui = null

var mTaskId = -1

func _ready():
	gui = get_node("canvas/widget_panel_gui")

func _exit_tree():
	rcos.remove_task(mTaskId)

func initialize(panel_id, panel_label, parent_task_id):
	set_name("widget_panel_"+str(panel_id)+"_task")
	var task_properties = {
		"name": panel_label,
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
		"ops": {
			"kill": funcref(gui, "kill"),
			"go_back": funcref(gui, "go_back")
		}
	}
	mTaskId = rcos.add_task(task_properties, parent_task_id)
	var io_ports_path_prefix = "rcos/"+panel_label
	data_router.set_node_icon(io_ports_path_prefix, load("res://widget_panels/graphics/icons/widget_panel.png"), 32)
	gui.init(panel_id, mTaskId, io_ports_path_prefix+"/")
	gui._load_from_file()
