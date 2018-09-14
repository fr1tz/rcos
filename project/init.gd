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

var mModuleNodes = {}

func _spawn_module(module_name):
	var module_node = rcos.spawn_module(module_name)
	mModuleNodes[module_name] = module_node

func _ready():
	_spawn_module("host_clipboard_io_ports")
	_spawn_module("host_sensors_io_ports")
	_spawn_module("host_joysticks_io_ports")
	_spawn_module("pointer_io_ports")
	_spawn_module("ffa_widgets")
	_spawn_module("remote_connector")
	_spawn_module("io_ports_connector")
	_spawn_module("widget_panels")
	_spawn_module("virtual_gamepads")
	mModuleNodes["remote_connector"].request_focus()
	queue_free()
