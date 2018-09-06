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

onready var mPortIcon = get_node("port_icon")
onready var mPortPathLabel = get_node("port_path_label")
onready var mOutputPortSelectorButton = get_node("output_port_selector_button")
onready var mInputPortSelectorButton = get_node("input_port_selector_button")
onready var mPortSelector = null

func _ready():
	mOutputPortSelectorButton.connect("pressed", self, "_select_output_port")
	mInputPortSelectorButton.connect("pressed", self, "_select_input_port")

func _select_output_port():
	_show_port_selector("/root/data_router/output_ports")

func _select_input_port():
	_show_port_selector("/root/data_router/input_ports")

func _show_port_selector(root_path):
	mPortSelector = rlib.instance_scene("res://rcos/lib/node_selector.tscn")
	mPortSelector.root_path = root_path
	add_child(mPortSelector)
	mPortSelector.connect("canceled", self, "_hide_port_selector")
	mPortSelector.connect("node_selected", self, "_port_selected")

func _hide_port_selector():
	if mPortSelector == null:
		return
	remove_child(mPortSelector)
	mPortSelector.queue_free()
	mPortSelector = null

func _port_selected(node):
	_hide_port_selector()
	var port_type = node.get_port_type()
	var port_path = node.get_port_path()
	var icon_path = data_router.get_node_icon(node, 32).get_path()
	configure(port_type, port_path, icon_path)

func configure(port_type, port_path, icon_path):
	mPortIcon.set_texture(load(icon_path))
	get_node("port_type_input").set_hidden(port_type == data_router.PORT_TYPE_OUTPUT)
	get_node("port_type_output").set_hidden(port_type == data_router.PORT_TYPE_INPUT)
	if port_type == data_router.PORT_TYPE_INPUT:
		mPortPathLabel.set_text("input_ports/" + port_path)
	else:
		mPortPathLabel.set_text("output_ports/" + port_path)
	get_meta("widget_root_node").configure(port_type, port_path, icon_path)
	

func load_widget_config(widget_config):
	mPortPathLabel.set_text(widget_config.port_path)

func load_widget_config_string(config_string):
	if config_string == null || config_string == "":
		return false
	var widget_config = Dictionary()
	if widget_config.parse_json(config_string) != OK:
		return false
	if !widget_config.has("port_type"): return false
	if !widget_config.has("port_path"): return false
	if !widget_config.has("icon_path"): return false
	var port_type = widget_config.port_type
	var port_path = widget_config.port_path
	var icon_path = widget_config.icon_path
	configure(port_type, port_path, icon_path)
	return true
