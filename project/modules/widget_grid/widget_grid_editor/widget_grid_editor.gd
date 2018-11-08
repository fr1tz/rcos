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
	gui = get_node("canvas/widget_grid_editor_gui")
	var task_properties = {
		"name": "Widget Grid "+get_name(),
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
		"ops": {
			"kill": funcref(gui, "kill"),
			"go_back": funcref(gui, "go_back")
		}
	}
	mTaskId = rcos.add_task(task_properties)
	var io_ports_path_prefix = "rcos/widget_grid_"+get_name()
	data_router.set_node_icon(io_ports_path_prefix, load("res://modules/widget_grid/graphics/icons/widget_grid.png"), 32)
	gui.init(get_name(), mTaskId, io_ports_path_prefix+"/")
	gui._load_from_file()
