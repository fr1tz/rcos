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

export(Color) var color_disabled = Color(1, 1, 1)
export(Color) var color_output = Color(1, 1, 1)
export(Color) var color_input = Color(1, 1, 1)

onready var mConfigGui = get_node("config_canvas/config_gui")

var mWidgetHost = null
var mPortType = -1
var mPortPath = ""
var mIconPath = ""

func _ready():
	mWidgetHost = get_meta("widget_host_api")
	mWidgetHost.enable_widget_frame_input(self)

func _widget_frame_input(event):
	if mPortType == -1:
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if mPortType == data_router.PORT_TYPE_INPUT:
		if touch && !event.pressed:
			var dangling_control = rcos.gui.get_dangling_control(index)
			if dangling_control != null:
				_dangling_control_dropped(dangling_control)
	else:
		if touch && event.pressed:
			_create_dangling_control(index)

func _create_dangling_control(index):
	var output_port = data_router.get_output_port(mPortPath)
	if output_port == null:
		return
	var data_control = rlib.instance_scene("res://ffa_widgets/io_port_widget/data_control.tscn")
	add_child(data_control)
	data_control.set_icon(get_node("icon").get_texture())
	data_control.set_label(mPortPath)
	data_control.set_meta("data", output_port.access_data())
	rcos.gui.pick_up_control(data_control, index)

func _dangling_control_dropped(control):
	if !control.has_meta("data"):
		return
	var input_port = data_router.get_input_port(mPortPath)
	if input_port == null:
		return
	var data = control.get_meta("data")
	input_port.put_data(data)

func configure(port_type, port_path, icon_path):
	mPortType = port_type
	mPortPath = port_path
	mIconPath = icon_path
	if port_type == data_router.PORT_TYPE_INPUT:
		get_node("color_frame").set_frame_color(color_input)
		get_node("raised_panel").set_hidden(true)
	else:
		get_node("color_frame").set_frame_color(color_output)
		get_node("raised_panel").set_hidden(false)
	get_node("icon").set_texture(load(icon_path))

#-------------------------------------------------------------------------------
# Common Widget API
#-------------------------------------------------------------------------------

func load_widget_config_string(config_string):
	return mConfigGui.load_widget_config_string(config_string)

func create_widget_config_string():
	if mPortType == -1:
		return
	var widget_config = {
		"port_type": mPortType,
		"port_path": mPortPath,
		"icon_path": mIconPath
	}
	return widget_config.to_json()
