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

var mInputPorts = {}

onready var mMainGui = get_node("main_canvas/main_gui")
onready var mConfigGui = get_node("config_canvas/config_gui")

func _ready():
	var port_path_prefix = "local/text_display_widget"+str(get_meta("widget_id"))
#	mInputPort = data_router.add_input_port(port_path_prefix+"/text")
#	mInputPort.connect("data_changed", self, "_on_input_data_changed")

func _exit_tree():
	for port in mInputPorts.values():
		data_router.remove_port(port)

#func _on_input_data_changed(old_data, new_data):
#	if new_data != null:
#		set_text(new_data)
#
#func set_text(data):
#	var string = str(data)
#	get_node("main_canvas/gui/Panel/Label").set_text(string)

func transfer():
	var output_port_path = mConfigGui.get_output_port_path()
	var output_port = data_router.get_output_port(output_port_path)
	if output_port == null:
		return
	var input_port_path = mConfigGui.get_input_port_path()
	var input_port = data_router.get_input_port(input_port_path)
	if input_port == null:
		return
	input_port.put_data(output_port.get_data())

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
