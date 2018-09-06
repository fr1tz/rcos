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

extends Node

var mData = null

func _init():
	add_user_signal("data_changed")

func get_port_type():
	return data_router.PORT_TYPE_INPUT

func get_port_path():
	return data_router.get_node("input_ports").get_path_to(self)

func put_data(data):
	var old_data = mData
	mData = data
	emit_signal("data_changed", old_data, mData)

func get_data():
	return mData
