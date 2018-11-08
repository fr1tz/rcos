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

onready var mIOPorts = get_node("io_ports")
onready var mMainGui = get_node("main_gui")
 
func _ready():
	mIOPorts.initialize(mMainGui)
	mMainGui.initialize(mIOPorts)

func get_main_gui():
	return get_node("main_gui")

func get_config_gui():
	return get_node("config_canvas/config_gui")

#-------------------------------------------------------------------------------
# Common Widget API
#-------------------------------------------------------------------------------

func load_widget_config_string(config_string):
	return true

func create_widget_config_string():
	return ""
