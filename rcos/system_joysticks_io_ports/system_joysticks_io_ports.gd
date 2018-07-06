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
	var devices = Input.get_connected_joysticks()
	for index in devices:
		_add_joystick(index)
	Input.connect("joy_connection_changed", self, "_joy_connection_changed")

func _add_joystick(index):
	var joystick = rlib.instance_scene("res://rcos/system_joysticks_io_ports/joystick.tscn")
	joystick.init(index)
	joystick.set_name("joystick"+str(index))
	add_child(joystick)

func _remove_joystick(index):
	var joystick = get_node("joystick"+str(index))
	if joystick == null:
		return
	remove_child(joystick)
	joystick.queue_free()

func _joy_connection_changed(index, connected):
	if connected:
		_add_joystick(index)
	else:
		_remove_joystick()
