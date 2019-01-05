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

func get_scheme():
	return "rfb"

func get_desc():
	return "Open using Quack VNC"

func get_icon():
	return load("res://modules/quack_vnc/graphics/icon.png")

func open(url):
	rcos_log.debug(self, ["open():", url])
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
	rcos.spawn_module("quack_vnc").connect_to_server(address, port)
