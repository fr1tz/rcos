# Copyright © 2017-2019 Michael Goldener <mg@wasted.ch>
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

var mNextAvailableTaskId = 1
var mTaskNodesByTaskId = {} # Task ID -> Task Node
var mTaskNodesByCanvas = {} # Task canvas -> Task Node

func _init():
	add_user_signal("task_list_changed")
	add_user_signal("task_added")
	add_user_signal("task_changed")
	add_user_signal("task_removed")

func add_task(properties, parent_task_id = -1):
	var parent_node = self
	if parent_task_id >= 0:
		if !mTaskNodesByTaskId.has(parent_task_id):
			return -1
		parent_node = mTaskNodesByTaskId[parent_task_id]
	var task_id = mNextAvailableTaskId
	mNextAvailableTaskId += 1
	var task_node = rlib.instance_scene("res://rcos_sys/tasks/task.tscn")
	task_node.set_name(str(task_id)) 
	task_node.properties = properties
	parent_node.add_child(task_node)
	mTaskNodesByTaskId[task_id] = task_node
	if properties.has("canvas") && properties.canvas != null:
		mTaskNodesByCanvas[properties.canvas] = task_node
	emit_signal("task_added", task_node)
	emit_signal("task_list_changed")
	return task_id

func change_task(task_id, properties):
	if !mTaskNodesByTaskId.has(task_id):
		return false
	var task_node = mTaskNodesByTaskId[task_id]
	task_node.change_properties(properties)
	return true

func remove_task(task_id):
	if !mTaskNodesByTaskId.has(task_id):
		return true
	var task_node = mTaskNodesByTaskId[task_id]
	emit_signal("task_removed", task_node)
	mTaskNodesByTaskId.erase(task_id)
	if task_node.properties.has("canvas") && task_node.properties.canvas != null:
		mTaskNodesByCanvas.erase(task_node.properties.canvas)
	task_node.get_parent().remove_child(task_node)
	task_node.free()
	emit_signal("task_list_changed")
	return true

func get_task_properties(task_id):
	if !mTaskNodesByTaskId.has(task_id):
		return null
	var properties = {}
	var task_node = mTaskNodesByTaskId[task_id]
	for key in task_node.properties.keys():
		properties[key] = task_node.properties[key]
	return properties

func get_task_from_canvas(canvas):
	if mTaskNodesByCanvas.has(canvas):
		return mTaskNodesByCanvas[canvas]
	return null

func get_task_list():
	return mTaskNodesByTaskId
