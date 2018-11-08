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

extends Panel

var mModule = null
var mGui = null
var mConnection = null

func _init():
	add_user_signal("cancel_button_pressed")
	add_user_signal("connect_button_pressed")

func _cancel_button_pressed():
	emit_signal("cancel_button_pressed")

func _connect_button_pressed():
	var address = get_node("address_edit").get_text()
	var port = int(get_node("port_edit").get_text())
	mModule.connect_to_server(address, port)

func initialize(module, gui, connection):
	mModule = module
	mGui = gui
	mConnection = connection
	get_node("cancel_button").connect("pressed", mModule, "kill")
	get_node("connect_button").connect("pressed", self, "_connect_button_pressed")
