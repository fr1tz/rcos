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

var mAddress = ""
var mPort = -1
var mStream = null

func _init():
	add_user_signal("port_open")
	add_user_signal("port_closed")

func _ready():
	get_node("check_status_timer").connect("timeout", self, "_check_status")

func _check_status():
	var status = mStream.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTING:
		return
	if status == StreamPeerTCP.STATUS_CONNECTED:
		emit_signal("port_open", mPort)
	else:
		emit_signal("port_closed", mPort)

func test(address, port):
	mAddress = address
	mPort = port
	mStream = StreamPeerTCP.new()
	if mStream.connect(mAddress, mPort) != OK:
		emit_signal("port_closed", mPort)
		queue_free()
		return
	get_node("check_status_timer").start()
