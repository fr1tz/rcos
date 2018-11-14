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

var mObject = null
var mMethodName = null
var mType = 0
var mState = null

func start(args = []):
	if mState != null:
		return false
	mState = mObject.callv(mMethodName, args)
	if mState == null:
		return false
	if typeof(mState) != TYPE_OBJECT:
		return false
	if !mState.is_type("GDFunctionState"):
		return false
	coroutines.mRunningCoroutines.push_back(self)
	return true

func stop():
	if coroutines.mRunningCoroutines.has(self):
		coroutines.mRunningCoroutines.remove(self)

func is_running():
	return mState != null

func initialize(object, method_name, type = 0):
	mObject = object
	mMethodName = method_name
	mType = type
	mState = null
	set_name(str(object.get_instance_ID())+" ["+object.get_name()+"] "+method_name)
