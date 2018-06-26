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

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func update_joystick_state(state):
	if mTouchpadConfig.mode == "stick":
		var vec = get_vec()
		var x_action = mTouchpadConfig.stick_config.x_action
		if x_action == "axis_x":
			state.axis_x += vec.x
		elif x_action == "axis_y":
			state.axis_y += vec.x
		elif x_action == "axis_z":
			state.axis_z += vec.x
		elif x_action == "axis_x_rot":
			state.axis_x_rot += vec.x
		elif x_action == "axis_y_rot":
			state.axis_y_rot += vec.x
		elif x_action == "axis_z_rot":
			state.axis_z_rot += vec.x
		var y_action = mTouchpadConfig.stick_config.y_action
		if y_action == "axis_x":
			state.axis_x += vec.y
		elif y_action == "axis_y":
			state.axis_y += vec.y
		elif y_action == "axis_z":
			state.axis_z += vec.y
		elif y_action == "axis_x_rot":
			state.axis_x_rot += vec.y
		elif y_action == "axis_y_rot":
			state.axis_y_rot += vec.y
		elif y_action == "axis_z_rot":
			state.axis_z_rot += vec.y
	elif mTouchpadConfig.mode == "dpad":
		var vec = get_vec()
		state.axis_x += vec.x
		state.axis_y += vec.y
	elif mTouchpadConfig.mode == "button":
		if is_active():
			var button_num = mTouchpadConfig.button_config.button_num
			state.buttons[button_num-1] += 1
