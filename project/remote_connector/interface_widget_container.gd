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

var mHostname = null
var mInterfaceWidgets = null

func _ready():
	mHostname = get_node("VBoxContainer/header/host")
	mInterfaceWidgets = get_node("VBoxContainer/interface_widgets")
	mHostname.set_text(get_name())

func add_interface_widget():
		var interface_widget = rlib.instance_scene("res://remote_connector/interface_widget.tscn")
		mInterfaceWidgets.add_child(interface_widget)
		return interface_widget

func set_host_name(name):
	mHostname.set_text(name)

func set_host_icon(tex):
	get_node("VBoxContainer/header/icon").set_texture(tex)

func set_host_color(color):
	get_node("VBoxContainer/header/icon").set_modulate(color)
