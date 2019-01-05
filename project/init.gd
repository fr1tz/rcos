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

extends ColorFrame

onready var mInitMessages = get_node("PanelContainer/init_messages")

var mRoutines = []

func _ready():
	set_process(true)
	var color = Globals.get("application/boot_bg_color")
	set_frame_color(color)
	get_node("PanelContainer/background").set_frame_color(color)
	mInitMessages.set_text("")
	mInitMessages.set_scroll_active(false)
	mInitMessages.set_scroll_follow(true)
	rcos.connect("init_finished", self, "_spawn_modules")
	_init_rcos()

func _print_init_msg(text):
	mInitMessages.add_text(text)

func _process(delta):
	for i in range(0, mRoutines.size()):
		if mRoutines[i] != null:
			mRoutines[i] = mRoutines[i].resume()

func _spawn_module(module_name):
	_print_init_msg("* Spawning module " + module_name + "...")
	var module = rcos_modules.spawn_module(module_name)
	if module == null:
		_print_init_msg(" FAILED\n")
		_print_init_msg(" *** INIT FAILED! UNABLE TO SPAWN MODULE " + module_name)
		return null
	_print_init_msg(" DONE\n")
	return module

func _init_rcos():
	var print_init_msg_func = funcref(self, "_print_init_msg")
	var rcos_init_routine = rcos.initialize(print_init_msg_func)
	mRoutines.push_back(rcos_init_routine)
	
func _spawn_modules():
	var spawn_modules_routine = _spawn_modules_routine()
	mRoutines.push_back(spawn_modules_routine)

func _spawn_modules_routine():
	var module_names = [
		"host_clipboard_io_ports",
		"host_sensors_io_ports",
		"host_joysticks_io_ports",
		"pointer_io_ports",
		"ffa_widgets",
		"remote_connector",
		"io_ports_connector",
		"widget_panels",
		"virtual_gamepads"
	]
	var modules = {}
	for module_name in module_names:
		var module = _spawn_module(module_name)
		if module == null:
			return null
		modules[module_name] = module
		yield()
	modules["remote_connector"].request_focus()
	#rcos.get_node("services/network_scanner_service").start_scan()
	queue_free()
	return null
