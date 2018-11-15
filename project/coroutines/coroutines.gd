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

var mPackedCoroutine = preload("res://coroutines/coroutine.tscn")

var mRunningCoroutines = []

func _ready():
	set_process(true)

func _process(delta):
	var frame = get_tree().get_frame()
	var n = mRunningCoroutines.size()-1
	while n >= 0:
		var coroutine = mRunningCoroutines[n]
		var r = coroutine.mState.resume()
		if r == null || !(typeof(r) == TYPE_OBJECT && r.is_type("GDFunctionState")):
			mRunningCoroutines.remove(n)
		coroutine.mState = r
		n -= 1

func create(object, method_name, type = 0):
	var coroutine = mPackedCoroutine.instance()
	coroutine.initialize(object, method_name, type)
	add_child(coroutine)
	return coroutine

func destroy(coroutine):
	if coroutine == null || coroutine.get_parent() != self:
		return
	if mRunningCoroutines.has(coroutine):
		mRunningCoroutines.erase(coroutine)
	remove_child(coroutine)
	coroutine.queue_free()
