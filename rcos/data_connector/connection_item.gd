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

extends Button

var mOutputPortPath = null
var mInputPortPath = null
var mConnectionDisabled = false

func initialize(output_port_path, input_port_path, disabled):
	mOutputPortPath = output_port_path
	mInputPortPath = input_port_path
	mConnectionDisabled = disabled
	get_node("output_port_path_label").set_text(mOutputPortPath)
	get_node("input_port_path_label").set_text(mInputPortPath)
	update_markings()

func get_output_port_path():
	return mOutputPortPath

func get_input_port_path():
	return mInputPortPath

func is_connection_disabled():
	return mConnectionDisabled

func activate_connection():
	if mConnectionDisabled:
		return
	data_router.add_connection(mOutputPortPath, mInputPortPath)
	update_markings()

func deactivate_connection():
	data_router.remove_connection(mOutputPortPath, mInputPortPath)
	update_markings()

func toggle_connection_disabled():
	if mConnectionDisabled:
		mConnectionDisabled = false
		activate_connection()
	else:
		mConnectionDisabled = true
		deactivate_connection()

func update_markings():
	var output_exists = data_router.has_output_port(mOutputPortPath)
	var input_exists = data_router.has_input_port(mInputPortPath)
	get_node("output_port_icon/missing").set_hidden(output_exists)
	get_node("output_port_icon/existing").set_hidden(!output_exists)
	get_node("input_port_icon/missing").set_hidden(input_exists)
	get_node("input_port_icon/existing").set_hidden(!input_exists)
	if mConnectionDisabled:
		get_node("connection_icon/active").set_hidden(true)
		get_node("connection_icon/inactive").set_hidden(true)
		get_node("connection_icon/disabled").set_hidden(false)
	else:
		var connection_exists = data_router.has_connection(mOutputPortPath, mInputPortPath)
		get_node("connection_icon/active").set_hidden(!connection_exists)
		get_node("connection_icon/inactive").set_hidden(connection_exists)
		get_node("connection_icon/disabled").set_hidden(true)