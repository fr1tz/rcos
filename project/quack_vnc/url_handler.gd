# Copyright © 2018 Michael Goldener <mg@wasted.ch>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends Node

func _ready():
	var open_func = funcref(self, "open")
	var scheme = "rfb"
	var desc = "Open using RFB client"
	var icon = load("res://quack_vnc/graphics/icon.png")
	rcos.register_url_handler(open_func, scheme, desc, icon)

func open(url):
	rcos.log_debug(self, ["open():", url])
	if url == "rfb":
		rcos.spawn_module("rfb_client")
		return
	if !url.begins_with("rfb://"):
		return
	var server = url.right(6)
	var address = "localhost"
	var port = 5900
	var sep_pos = server.find("::")
	if sep_pos != -1:
		if sep_pos > 0:
			address = server.left(sep_pos)
		port = int(server.right(sep_pos+2))
	else:
		sep_pos = server.find(":")
		if sep_pos != -1:
			if sep_pos > 0:
				address = server.left(sep_pos)
			port = 5900 + int(server.right(sep_pos+1))
		elif server != "":
			address = server
	rcos.spawn_module("rfb_client").connect_to_server(address, port)
