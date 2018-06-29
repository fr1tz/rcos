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

onready var mTextLabel = get_node("main_canvas/gui/Panel/Label")

func _ready():
	var port_path_prefix = "local/text_display_widget"+str(get_meta("widget_id"))
	mInputPorts["text"] = data_router.add_input_port(port_path_prefix+"/text")
	for port in mInputPorts.values():
		port.connect("data_changed", self, "_on_input_data_changed")
	mOutputPorts["text"] = data_router.add_output_port(port_path_prefix+"/text")
	mOutputPorts["on_pressed(text)"] = data_router.add_output_port(port_path_prefix+"/on_pressed(text)")
	get_node("main_canvas/gui/invisible_button").connect("pressed", self, "_on_widget_pressed")

func _exit_tree():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)

func _on_input_data_changed(old_data, new_data):
	if new_data != null:
		set_text(new_data)

func _on_widget_pressed():
	mOutputPorts["on_pressed(text)"].put_data(mTextLabel.get_text())

func set_text(data):
	var string = str(data)
	mTextLabel.set_text(string)
	mOutputPorts["text"].put_data(mTextLabel.get_text())

#-------------------------------------------------------------------------------
# Common Widget API
#-------------------------------------------------------------------------------

func get_main_gui():
	return get_node("main_canvas/gui")

func get_config_gui():
	return null

func load_widget_config_string(config_string):
	var widget_config = Dictionary()
	if widget_config.parse_json(config_string) != OK:
		return false
	mTextLabel.set_text(widget_config.text)
	return true

func create_widget_config_string():
	var widget_config = {
		"text": mTextLabel.get_text()
	}
	return widget_config.to_json()