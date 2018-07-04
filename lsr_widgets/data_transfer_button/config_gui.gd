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

extends Panel

onready var mOutputPortButton = get_node("output_port_button")
onready var mInputPortButton = get_node("input_port_button")
onready var mTransferButton = get_node("transfer_button")
onready var mPortSelectors = {
	"output": get_node("output_port_selector"),
	"input": get_node("input_port_selector"),
}

func _ready():
	mOutputPortButton.connect("pressed", self, "_show_output_port_selector")
	mInputPortButton.connect("pressed", self, "_show_input_port_selector")
	mTransferButton.connect("pressed", get_meta("widget_root_node"), "transfer")
	mPortSelectors.output.connect("canceled", self, "_show_buttons")
	mPortSelectors.output.connect("node_selected", self, "_output_port_selected")
	mPortSelectors.input.connect("canceled", self, "_show_buttons")
	mPortSelectors.input.connect("node_selected", self, "_input_port_selected")

func _show_buttons():
	mPortSelectors.output.set_hidden(true)
	mPortSelectors.input.set_hidden(true)

func _show_output_port_selector():
	mPortSelectors.output.set_hidden(false)
	mPortSelectors.input.set_hidden(true)

func _show_input_port_selector():
	mPortSelectors.output.set_hidden(true)
	mPortSelectors.input.set_hidden(false)

func _output_port_selected(node):
	mOutputPortButton.set_text(node.get_port_path())
	_show_buttons()

func _input_port_selected(node):
	mInputPortButton.set_text(node.get_port_path())
	_show_buttons()

func get_output_port_path():
	return mOutputPortButton.get_text()

func get_input_port_path():
	return mInputPortButton.get_text()

func load_widget_config(widget_config):
	mOutputPortButton.set_text(widget_config.output_port_path)
	mInputPortButton.set_text(widget_config.input_port_path)
	