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

extends MarginContainer

var mHostname = null
var mInterfaceWidgets = null

func _ready():
	mHostname = get_node("PanelContainer/MarginContainer/VBoxContainer/hostname")
	mInterfaceWidgets = get_node("PanelContainer/MarginContainer/VBoxContainer/interface_widgets")
	mHostname.set_text(get_name())

func add_interface_widget():
		var interface_widget = rlib.instance_scene("res://rcos/remote_connector/interface_widget.tscn")
		mInterfaceWidgets.add_child(interface_widget)
		return interface_widget
