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

var mAnnounceSourceAddress = null
var mAnnounceSourcePort = null
var mVjoyServerPort = null
var mProtocolVersion = null
var mLastHeartbeatTime = -1
var mInterfaceWidget = null

func init(addr, port):
	mAnnounceSourceAddress = addr
	mAnnounceSourcePort = port

func process_announce(announce):
	rcos.log_debug(self, ["process_announce()", announce])
	var words = announce.split(" ", false)
	if words.size() != 4:
		return
	mLastHeartbeatTime = OS.get_unix_time()
	mProtocolVersion = int(words[1])
	mVjoyServerPort = int(words[2])
	if mInterfaceWidget == null:
		var connector_service = rcos.get_node("services/connector_service")
		if connector_service == null:
			rcos.log_error(self, "Unable to find connector service")
			return
		var host = words[3]
		mInterfaceWidget = connector_service.add_interface_widget(host)
		mInterfaceWidget.connect("activated", self, "activate")
		mInterfaceWidget.set_icon(load("res://vjoy_client/graphics/icon.png"))
	var info = rlib.join_array([
		"vJoy Server",
		mAnnounceSourceAddress+":"+str(mVjoyServerPort),
		"Protocol version: "+str(mProtocolVersion)
	], "\n")
	mInterfaceWidget.set_info(info)

func activate():
	var vjoy_client = rcos.spawn_module("vjoy_client")
	vjoy_client.connect_to_server(mAnnounceSourceAddress, mVjoyServerPort)