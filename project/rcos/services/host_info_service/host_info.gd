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

var mHostInfoService = null
var mHostName = ""
var mHostIcon = load("res://data_router/icons/32/question_mark.png")
var mHostColor = Color(1, 1, 1)
var mAddresses = []
var mDirty = false

func clear_addresses():
	if !mAddresses.empty():
		mAddresses.clear()
		mDirty = true

func add_address(addr):
	if !mAddresses.has(addr):
		var host_info = mHostInfoService.get_host_info_from_address(addr)
		if host_info != null:
			host_info.remove_address(addr)
		mAddresses.push_back(addr)
		mDirty = true

func remove_address(addr):
	if mAddresses.has(addr):
		mAddresses.erase(addr)
		mDirty = true

func has_address(addr):
	return mAddresses.has(addr)

func get_addresses():
	return mAddresses

func get_host_name():
	return mHostName

func set_host_name(host_name):
	if mHostName != host_name:
		mHostName = host_name
		mDirty = true

func get_host_icon():
	return mHostIcon

func set_host_icon(host_icon):
	if mHostIcon != host_icon:
		mHostIcon = host_icon
		mDirty = true

func get_host_color():
	return mHostColor

func set_host_color(host_color):
	if mHostColor != host_color:
		mHostColor = host_color
		mDirty = true

func is_dirty():
	return mDirty

func mark_as_dirty():
	mDirty = true

func mark_as_clean():
	mDirty = false

func initialize(host_info_service):
	mHostInfoService = host_info_service
