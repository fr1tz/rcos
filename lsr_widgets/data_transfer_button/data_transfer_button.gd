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

var mInputPorts = []

onready var mMainGui = get_node("main_canvas/main_gui")
onready var mConfigGui = get_node("config_canvas/config_gui")

func _ready():
	_add_io_ports()

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var port_path_prefix = "local/data_transfer_button"+str(get_meta("widget_id"))
	var input_port_names = [
		"pressed"
	]
	for port_name in input_port_names:
		var port_path = port_path_prefix+"/"+port_name
		var port = data_router.add_input_port(port_path)
		port.connect("data_changed", self, "_on_input_port_data_changed", [port])
		mInputPorts.push_back(port)

func _remove_io_ports():
	for port in mInputPorts:
		data_router.remove_port(port)

func _on_input_port_data_changed(old_data, new_data, port):
	if port.get_name() == "pressed":
		if new_data != null:
			get_node("main_canvas/main_gui").set_pressed(bool(new_data))

func transfer():
	var output_port_path = mConfigGui.get_output_port_path()
	var output_port = data_router.get_output_port(output_port_path)
	if output_port == null:
		return
	var input_port_path = mConfigGui.get_input_port_path()
	var input_port = data_router.get_input_port(input_port_path)
	if input_port == null:
		return
	input_port.put_data(output_port.access_data())

#-------------------------------------------------------------------------------
# Common Widget API
#-------------------------------------------------------------------------------

func get_main_gui():
	return mMainGui

func get_config_gui():
	return mConfigGui

func load_widget_config_string(config_string):
	var widget_config = Dictionary()
	if widget_config.parse_json(config_string) != OK:
		return false
	mConfigGui.load_widget_config(widget_config)
	return true

func create_widget_config_string():
	var widget_config = {
		"output_port_path": mConfigGui.get_output_port_path(),
		"input_port_path": mConfigGui.get_input_port_path()
	}
	return widget_config.to_json()
