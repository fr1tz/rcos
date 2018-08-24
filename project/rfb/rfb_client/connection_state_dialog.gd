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

func _ready():
	var retry_button = get_node("status_dialog/retry_button")
	retry_button.connect("pressed", self, "_retry_connection")

func _retry_connection():
	var address = mConnection.get_remote_address()
	var port = mConnection.get_remote_port()
	mConnection.connect_to_server(address, port)

func _connection_state_changed(state):
	var state_label = get_node("status_dialog/label")
	var retry_button = get_node("status_dialog/retry_button")
	retry_button.set_hidden(true)
	if state == mConnection.CS_ERROR:
		state_label.set_text("ERROR: "+mConnection.get_error())
		_set_spinner_spin(false)
		retry_button.set_hidden(false)
	elif state == mConnection.CS_READY_TO_CONNECT:
		state_label.set_text("Ready")
		_set_spinner_spin(false)
	elif state == mConnection.CS_CONNECTING:
		state_label.set_text("Connecting")
		_set_spinner_spin(true)
	elif state == mConnection.CS_RECEIVE_PROTOCOL_VERSION:
		state_label.set_text("Waiting for protocol version")
	elif state == mConnection.CS_RECEIVE_SECURITY_MSG:
		state_label.set_text("Waiting for security message")
	elif state == mConnection.CS_WAITING_FOR_PASSWORD:
		state_label.set_text("Waiting for password")
		get_node("password_dialog").set_hidden(false)
	elif state == mConnection.CS_RECEIVE_VNC_AUTH_CHALLENGE:
		state_label.set_text("Waiting for VNC auth challenge")
	elif state == mConnection.CS_RECEIVE_SECURITY_RESULT_MSG:
		state_label.set_text("Waiting for security result message")
	elif state == mConnection.CS_RECEIVE_SERVER_INIT_MSG:
		state_label.set_text("Waiting for server init message")
	elif state == mConnection.CS_RECEIVE_SERVER_MESSAGES:
		state_label.set_text("Connected")
		_set_spinner_spin(false)

func _set_spinner_spin(spinning):
	set_fixed_process(spinning)

func _fixed_process(delta):
	var spinner = get_node("status_dialog/spinner")
	spinner.set_rotation_deg(spinner.get_rotation_deg() - delta*180)

func initialize(module, gui, connection):
	mModule = module
	mGui = gui
	mConnection = connection
	mConnection.connect("connection_state_changed", self, "_connection_state_changed")
	get_node("password_dialog").set_hidden(true)
	get_node("password_dialog").connect("password_entered", mConnection, "set_password")
