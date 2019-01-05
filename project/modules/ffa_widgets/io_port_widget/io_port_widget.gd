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

extends ReferenceFrame

onready var mConfigGui = get_node("config_canvas/config_gui")

var mWidgetHost = null
var mPortType = -1
var mPortPath = ""
var mIconPath = ""
var mPort = null

func _ready():
	connect("resized", self, "_resized")
	mWidgetHost = get_meta("widget_host_api")
	mWidgetHost.enable_widget_frame_input(self)

func _resized():
	var icon_width = 32
	var icon_height = 32
	var tex = get_node("icon").get_texture()
	if tex:
		var image = tex.get_data()
		var icon_width = image.get_width()
		var icon_height = image.get_height()
	if get_size().x < icon_width || get_size().y < icon_height:
		get_node("icon").set_stretch_mode(TextureFrame.STRETCH_KEEP_ASPECT_CENTERED)
	else:
		get_node("icon").set_stretch_mode(TextureFrame.STRETCH_KEEP_CENTERED)

func _widget_frame_input(event):
	if mPort == null:
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if mPortType == rcos_data_router.PORT_TYPE_INPUT:
		if touch && !event.pressed:
			var dangling_control = rcos.gui.get_dangling_control(index)
			if dangling_control != null:
				_dangling_control_dropped(dangling_control)
	else:
		if touch && event.pressed:
			_create_dangling_control(index)

func _create_dangling_control(index):
	var output_port = rcos_data_router.get_output_port(mPortPath)
	if output_port == null:
		return
	var data_control = rlib.instance_scene("res://modules/ffa_widgets/io_port_widget/data_control.tscn")
	add_child(data_control)
	data_control.set_icon(get_node("icon").get_texture())
	data_control.set_label(mPortPath)
	data_control.set_meta("data", output_port.access_data())
	rcos.gui.pick_up_control(data_control, index)

func _dangling_control_dropped(control):
	if !control.has_meta("data"):
		return
	var input_port = rcos_data_router.get_input_port(mPortPath)
	if input_port == null:
		return
	var data = control.get_meta("data")
	input_port.put_data(data)

func configure(port_type, port_path, icon_path):
	mPortType = port_type
	mPortPath = port_path
	mIconPath = icon_path
	mPort = null
	get_node("color_frame").set_frame_color(Color(1,1,1))
	if rcos.has_node("services/host_info_service"):
		var hostname = str(port_path).split("/")[0]
		var host_info_service = rcos.get_node("services/host_info_service")
		var host_info = host_info_service.get_host_info_from_hostname(hostname)
		if host_info:
			get_node("color_frame").set_frame_color(host_info.get_host_color())
	if mPortType == rcos_data_router.PORT_TYPE_INPUT:
		get_node("raised_panel").set_hidden(true)
		mPort = rcos_data_router.get_input_port(mPortPath)
	else:
		get_node("raised_panel").set_hidden(false)
		mPort = rcos_data_router.get_output_port(mPortPath)
	get_node("missing_port_overlay").set_hidden(mPort != null)
	if mPort == null:
		get_node("icon").set_texture(load(icon_path))
		rcos_data_router.request_port_creation_notice(mPortType, mPortPath, funcref(self, "_port_creation_notice"))
	else:
		var icon = rcos_data_router.get_node_icon(mPort, 32)
		if icon != null:
			get_node("icon").set_texture(icon)

func _port_creation_notice(port):
	call_deferred("configure", mPortType, mPortPath, mIconPath)

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
