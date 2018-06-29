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

var mOutputPorts = {}
var mInputPorts = {}

func _ready():
	var port_path_prefix = "localhost/sys"
	mInputPorts["clipboard"] = data_router.add_input_port(port_path_prefix+"/clipboard")
	for port in mInputPorts.values():
		port.connect("data_changed", self, "_on_input_data_changed", [port])
	mOutputPorts["clipboard"] = data_router.add_output_port(port_path_prefix+"/clipboard")
	set_fixed_process(true)

func _exit_tree():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)

func _fixed_process(delta):
	mOutputPorts["clipboard"].put_data(OS.get_clipboard())

func _on_input_data_changed(old_data, new_data, port):
	if port.get_name() == "clipboard":
		if new_data == null:
			new_data = ""
		else:
			new_data = str(new_data)
		OS.set_clipboard(new_data)
