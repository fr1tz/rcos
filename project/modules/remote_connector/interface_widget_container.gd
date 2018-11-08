# Copyright © 2017, 2018 Michael Goldener <mg@wasted.ch>
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

extends PanelContainer

var mHostLabel = null
var mEditButton = null 
var mInterfaceWidgets = null

func _init():
	add_user_signal("edit_button_pressed")

func _ready():
	mHostLabel = get_node("VBoxContainer/header/host_label")
	mEditButton = get_node("VBoxContainer/header/edit_button")
	mInterfaceWidgets = get_node("VBoxContainer/MarginContainer/interface_widgets")
	mHostLabel.set_text(get_name())
	mEditButton.connect("pressed", self, "emit_signal", ["edit_button_pressed"])

func add_interface_widget():
	var interface_widget = rlib.instance_scene("res://modules/remote_connector/interface_widget.tscn")
	mInterfaceWidgets.add_child(interface_widget)
	return interface_widget

func get_host_label():
	return mHostLabel.get_text()

func set_host_label(name):
	mHostLabel.set_text(name)

func set_host_icon(tex):
	get_node("VBoxContainer/header/icon").set_texture(tex)
#	if tex.get_path().ends_with("device_generic.png"):
#		get_node("VBoxContainer/header/frame").set_hidden(true)
#	else:
#		get_node("VBoxContainer/header/frame").set_hidden(false)

func set_host_color(color):
#	var stylebox = get_stylebox("panel").duplicate()
#	stylebox.set_bg_color(color)
#	add_style_override("panel", stylebox)
	get_node("bg_color_frame").set_frame_color(color)
	get_node("VBoxContainer/header/icon_frame").set_modulate(color)
	get_node("VBoxContainer/header/frame/frame_color").set_frame_color(color)
