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

extends PanelContainer

onready var mDisabledSegment = get_node("hbox/disabled_segment")
onready var mIcon = get_node("hbox/icon_segment/icon")
onready var mLabels = get_node("hbox/labels_segment/vbox")
onready var mRemoveSegment = get_node("hbox/remove_segment")

var mConnection = null

func _ready():
	var isquare = Vector2(rcos.get_isquare_size(), rcos.get_isquare_size())
	mDisabledSegment.set_custom_minimum_size(isquare)
	mRemoveSegment.set_custom_minimum_size(isquare)

func _toggle_disabled():
	var output_path = mConnection.get_output_port_path()
	var input_path = mConnection.get_input_port_path()
	var disabled = !mConnection.is_disabled()
	data_router.set_connection_disabled(output_path, input_path, disabled)

func _remove():
	var output_path = mConnection.get_output_port_path()
	var input_path = mConnection.get_input_port_path()
	data_router.remove_connection(output_path, input_path)

func initialize(connection):
	mConnection = connection
	mLabels.get_node("output_port").set_text(connection.get_output_port_path())
	mLabels.get_node("input_port").set_text(connection.get_input_port_path())
	mDisabledSegment.get_node("button").connect("pressed", self, "_toggle_disabled")
	mRemoveSegment.get_node("button").connect("pressed", self, "_remove")
	update_markings()

func get_output_port_path():
	return mConnection.get_output_port_path()

func get_input_port_path():
	return mConnection.get_input_port_path()

func is_connection_disabled():
	return mConnection.is_disabled()

func update_markings():
	get_node("hbox/disabled_segment/toggle_button").set_pressed(!mConnection.is_disabled())
	var output_exists = mConnection.get_output_port_node() != null
	var input_exists = mConnection.get_input_port_node() != null
	mIcon.get_node("output_port_icon/missing").set_hidden(output_exists)
	mIcon.get_node("output_port_icon/existing").set_hidden(!output_exists)
	mIcon.get_node("input_port_icon/missing").set_hidden(input_exists)
	mIcon.get_node("input_port_icon/existing").set_hidden(!input_exists)
	if mConnection.is_disabled():
		mIcon.get_node("connection_icon/active").set_hidden(true)
		mIcon.get_node("connection_icon/inactive").set_hidden(true)
		mIcon.get_node("connection_icon/disabled").set_hidden(false)
	else:
		var established = mConnection.is_established()
		mIcon.get_node("connection_icon/active").set_hidden(!established)
		mIcon.get_node("connection_icon/inactive").set_hidden(established)
		mIcon.get_node("connection_icon/disabled").set_hidden(true)
