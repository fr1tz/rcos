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

var mDataRouter = null
var mID = null
var mOutputPortPath = null
var mInputPortPath = null
var mOutputPortNode = null
var mInputPortNode = null
var mDisabled = false

func get_id():
	return mID

func get_output_port_path():
	return mOutputPortPath

func get_input_port_path():
	return mInputPortPath

func get_output_port_node():
	return mOutputPortNode

func get_input_port_node():
	return mInputPortNode

func is_disabled():
	return mDisabled

func set_disabled(disabled):
	if disabled == mDisabled:
		return
	mDataRouter.set_connection_disabled(mOutputPortPath, mInputPortPath, disabled)

func is_established():
	if mOutputPortNode == null || mInputPortNode == null:
		return false
	return mOutputPortNode.get_connections().has(mInputPortNode)

