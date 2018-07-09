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

var mOutputPorts = []
var mInputPorts = []

onready var mTextEditor = get_node("main_canvas/main_gui/frame/text_editor")

func _ready():
	var port_path_prefix = "local/text_edit_widget"+str(get_meta("widget_id"))
	mInputPorts.push_back(data_router.add_input_port(port_path_prefix+"/text"))
	mInputPorts.push_back(data_router.add_input_port(port_path_prefix+"/append(line)"))
	for port in mInputPorts:
		port.connect("data_changed", self, "_on_input_port_data_changed", [port])
	mOutputPorts.push_back(data_router.add_output_port(port_path_prefix+"/text"))
	mTextEditor.connect("text_changed", self, "_on_text_changed")
	get_main_gui().connect("dangling_control_dropped", self, "_dangling_control_dropped")

func _exit_tree():
	for port in mOutputPorts:
		data_router.remove_port(port)
	for port in mInputPorts:
		data_router.remove_port(port)

func _on_text_changed():
	mOutputPorts[0].put_data(mTextEditor.get_text())

func _on_input_port_data_changed(old_data, new_data, port):
	if port.get_name() == "text":
		if new_data != null:
			mTextEditor.set_text(str(new_data))
	elif port.get_name() == "append(line)":
		if new_data != null:
			var line = str(new_data)
			if !line.ends_with("\n"):
				line += "\n"
			mTextEditor.set_text(mTextEditor.get_text()+line)
			mTextEditor.cursor_set_line(mTextEditor.get_line_count(), true)

func _dangling_control_dropped(control):
	if !control.has_meta("data"):
		return
	var data = control.get_meta("data")
	if data == null:
		mTextEditor.set_text("")
	else:
		mTextEditor.set_text(str(data))

#-------------------------------------------------------------------------------
# Common Widget API
#-------------------------------------------------------------------------------

func get_main_gui():
	return get_node("main_canvas/main_gui")

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

