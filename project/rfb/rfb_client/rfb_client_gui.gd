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

onready var mMainDialog = get_node("main_dialog")
onready var mOptionsDialog = get_node("options_dialog")
onready var mOpenConnectionDialog = get_node("open_connection_dialog")
onready var mConnectionStateDialog = get_node("connection_state_dialog")

var mModule = null
var mConnection = null

func _ready():
	show_dialog("open_connection_dialog")

func _connection_state_changed(state):
	if state == mConnection.CS_ERROR || state == mConnection.CS_CONNECTING:
		show_dialog("connection_state_dialog")
	elif state == mConnection.CS_RECEIVE_SERVER_MESSAGES:
		show_dialog("main_dialog")

func initialize(module, connection):
	mModule = module
	mConnection = connection
	mConnection.connect("connection_state_changed", self, "_connection_state_changed")
	mMainDialog.initialize(mModule, self, mConnection)
	mOptionsDialog.initialize(mModule, self, mConnection)
	mOpenConnectionDialog.initialize(mModule, self, mConnection)
	mConnectionStateDialog.initialize(mModule, self, mConnection)

func show_dialog(dialog_name):
	for c in get_children():
		c.set_hidden(c.get_name() != dialog_name)
