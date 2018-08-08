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

extends Panel

export(NodePath) var root_path = null

var mRootNode = null
var mCurrentNode = null

func _init():
	add_user_signal("canceled")
	add_user_signal("node_selected")

func _ready():
	get_node("refresh_button").connect("pressed", self, "_refresh")
	get_node("cancel_button").connect("pressed", self, "_cancel")
	if root_path == null:
		return
	mRootNode = get_node(root_path)
	if mRootNode == null:
		return
	_set_current_node(mRootNode)

func _refresh():
	var items = get_node("current_node_path/scroller/items")
	for c in items.get_children():
		items.remove_child(c)
		c.queue_free()
	var n = mCurrentNode
	while n != mRootNode.get_parent():
		var item = Button.new()
		item.set_custom_minimum_size(Vector2(40, 40))
		item.set_text(n.get_name())
		items.add_child(item)
		items.move_child(item, 0)
		item.connect("pressed", self, "_set_current_node", [n])
		n = n.get_parent()
	items = get_node("items_scroller/items")
	for c in items.get_children():
		items.remove_child(c)
		c.queue_free()
	for c in mCurrentNode.get_children():
		var item = rlib.instance_scene("res://rcos/lib/_res/node_selector/node_item.tscn")
		item.set_custom_minimum_size(Vector2(200, 40))
		item.set_size(Vector2(200, 40))
		items.add_child(item)
		var label = c.get_name()
		if c.get_child_count() == 0:
			item.connect("pressed", self, "_item_selected", [item])
		else:
			label += " >"
			item.connect("pressed", self, "_set_current_node", [c])
		item.set_text(label)
		var icon = data_router.get_node_icon(c, 32)
		if icon:
			item.set_icon(icon)

func _cancel():
	emit_signal("canceled")

func _item_selected(item):
	#prints("_item_selected", mCurrentNode, item.get_text())
	var node = mCurrentNode.get_node(item.get_text())
	if node.get_child_count() == 0:
		emit_signal("node_selected", node)
	else:
		_set_current_node(node)

func _set_current_node(node):
	#prints("_set_current_node", mCurrentNode, node.get_name())
	if node != mRootNode && !mRootNode.is_a_parent_of(node):
		return
	mCurrentNode = node
	call_deferred("_refresh")


