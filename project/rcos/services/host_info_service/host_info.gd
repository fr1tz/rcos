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

var mHostName = ""
var mHostIcon = load("res://data_router/icons/32/question_mark.png")
var mHostColor = Color(1, 1, 1)
var mAddresses = []

func _init():
	add_user_signal("host_info_changed")

func clear_addresses():
	mAddresses.clear()

func add_address(addr):
	if !mAddresses.has(addr):
		mAddresses.push_back(addr)

func remove_address(addr):
	if mAddresses.has(addr):
		mAddresses.erase(addr)

func has_address(addr):
	return mAddresses.has(addr)

func get_addresses():
	return mAddresses

func get_host_name():
	return mHostName

func set_host_name(host_name):
	mHostName = host_name

func get_host_icon():
	return mHostIcon

func set_host_icon(host_icon):
	mHostIcon = host_icon

func get_host_color():
	return mHostColor

func set_host_color(host_color):
	mHostColor = host_color

func save_to_file():
	var dir = Directory.new()
	if !dir.dir_exists("user://etc/hosts"):
		dir.make_dir_recursive("user://etc/hosts")
	var cfile = ConfigFile.new()
	var s = "host_info"
	cfile.set_value(s, "name", mHostName)
	cfile.set_value(s, "icon", mHostIcon.get_path())
	cfile.set_value(s, "color", mHostColor.to_html())
	cfile.set_value(s, "addresses", rlib.join_array(mAddresses, " "))
	if cfile.save("user://etc/hosts/"+mHostName+".info") != OK:
		return false
	emit_signal("host_info_changed")
	return true
