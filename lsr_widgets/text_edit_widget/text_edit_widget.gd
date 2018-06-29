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

onready var mTextEditor = get_node("main_canvas/gui/frame/text_editor")

func _ready():
	var port_path_prefix = "local/text_edit_widget"+str(get_meta("widget_id"))
	mInputPorts["text"] = data_router.add_input_port(port_path_prefix+"/text")
	for port in mInputPorts.values():
		port.connect("data_changed", self, "_on_input_data_changed")
	mOutputPorts["text"] = data_router.add_output_port(port_path_prefix+"/text")
	mTextEditor.connect("text_changed", self, "_on_text_changed")

func _exit_tree():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)

func _on_text_changed():
	mOutputPorts["text"].put_data(mTextEditor.get_text())

func _on_input_data_changed(old_data, new_data):
	if new_data != null:
		mTextEditor.set_text(str(new_data))

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
	mTextEditor.set_text(widget_config.text)
	return true

func create_widget_config_string():
	var widget_config = {
		"text": mTextEditor.get_text()
	}
	return widget_config.to_json()

