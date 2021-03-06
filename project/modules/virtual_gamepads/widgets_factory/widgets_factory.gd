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

func _ready():
	rcos.add_task({
		"type": "widget_factory",
		"product_name": "Gamepad Widget",
		"product_id": "virtual_gamepads.emupad_widget",
		"product_icon": load("res://modules/virtual_gamepads/widgets/emupad_widget/graphics/icon.widget.png"),
		"config_presets": [
			"Stick",
			"DPad",
			"Touchpad",
			"1 Button",
			"2 Buttons",
			"4 Buttons"
		],
		"create_widget_func": funcref(self, "create_widget")
	})

func create_widget():
	return rlib.instance_scene("res://modules/virtual_gamepads/widgets/emupad_widget/emupad_widget.tscn")
