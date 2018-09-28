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
	var open_func = funcref(self, "open")
	var scheme = "vjoy"
	var desc = "Open using vJoyCtrl"
	var icon = load("res://vjoyctrl/graphics/icon.png")
	rcos.register_url_handler(open_func, scheme, desc, icon)

func open(url):
	rcos.log_debug(self, ["open():", url])
	if url == "vjoy":
		rcos.spawn_module("vjoyctrl")
		return
	if !url.begins_with("vjoy://"):
		return
	var server = url.right(7)
	var address = "localhost"
	var port = 6000
	var sep_pos = server.find(":")
	if sep_pos != -1:
		if sep_pos > 0:
			address = server.left(sep_pos)
		port = int(server.right(sep_pos+1))
	rcos.spawn_module("vjoyctrl").connect_to_server(address, port)
