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

const TYPE_STICK = 0
const TYPE_DPAD = 1
const TYPE_SINGLE_BUTTON = 2
const TYPE_DUAL_BUTTON = 3

func _ready():
	rcos.add_task({
			"type": "widget_factory",
			"product_name": "Gamepad Widget (Stick)",
			"product_id": "virtual_gamepads.action_widget",
			"create_widget_func": funcref(self, "create_stick_widget")
		})
	rcos.add_task({
			"type": "widget_factory",
			"product_name": "Gamepad Widget (DPad)",
			"product_id": "virtual_gamepads.action_widget",
			"create_widget_func": funcref(self, "create_dpad_widget")
		})
	rcos.add_task({
			"type": "widget_factory",
			"product_name": "Gamepad Widget (1 Button)",
			"product_id": "virtual_gamepads.action_widget",
			"create_widget_func": funcref(self, "create_1button_widget")
		})
	rcos.add_task({
			"type": "widget_factory",
			"product_name": "Gamepad Widget (2 Buttons)",
			"product_id": "virtual_gamepads.action_widget",
			"create_widget_func": funcref(self, "create_2button_widget")
		})

func create_stick_widget():
	var widget = rlib.instance_scene("res://virtual_gamepads/widgets/action_widget/action_widget.tscn")
	widget.set_initial_config(get_default_config(TYPE_STICK))
	return widget

func create_dpad_widget():
	var widget = rlib.instance_scene("res://virtual_gamepads/widgets/action_widget/action_widget.tscn")
	widget.set_initial_config(get_default_config(TYPE_DPAD))
	return widget

func create_1button_widget():
	var widget = rlib.instance_scene("res://virtual_gamepads/widgets/action_widget/action_widget.tscn")
	widget.set_initial_config(get_default_config(TYPE_SINGLE_BUTTON))
	return widget

func create_2button_widget():
	var widget = rlib.instance_scene("res://virtual_gamepads/widgets/action_widget/action_widget.tscn")
	widget.set_initial_config(get_default_config(TYPE_DUAL_BUTTON))
	return widget

func get_default_config(type):
	var basic_config = {
		"num_pads": 1
	}
	var pad1config = {
		"mode": "stick",
		"stick_config": {
			"radius": 32,
			"threshold": 0,
			"x_action": "axis_x",
			"y_action": "axis_y",
			
		},
		"dpad_config": {
			"radius": 32,
			"threshold": 10
		},
		"button_config": {
			"button_num": 1
		}
	}
	var pad2config = {
		"mode": "stick",
		"stick_config": {
			"radius": 32,
			"threshold": 0,
			"x_action": "axis_x",
			"y_action": "axis_y",
		},
		"dpad_config": {
			"radius": 32,
			"threshold": 10
		},
		"button_config": {
			"button_num": 2
		}
	}
	if type == TYPE_DPAD:
		pad1config.mode = "dpad"
		pad2config.mode = "dpad"
	elif type == TYPE_SINGLE_BUTTON:
		pad1config.mode = "button"
		pad2config.mode = "button"
	elif type == TYPE_DUAL_BUTTON:
		basic_config.num_pads = 2
		pad1config.mode = "button"
		pad2config.mode = "button"
	var widget_config = {
		"basic_config": basic_config,
		"pad_configs": [ pad1config, pad2config ]
	}
	return widget_config
