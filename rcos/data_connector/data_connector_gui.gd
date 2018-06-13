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

onready var mOutputsTree = get_node("outputs_panel/tree")
onready var mInputsTree = get_node("inputs_panel/tree")

func _ready():
	mOutputsTree.set_hide_root(true)
	mInputsTree.set_hide_root(true)
	get_node("status_bar/refresh_button").connect("pressed", self, "refresh")
	get_node("status_bar/connect_button").connect("pressed", self, "_connect")
	get_node("status_bar/disconnect_button").connect("pressed", self, "_disconnect")
	refresh()

func _build_tree(tree_control, node, parent_item = null):
	var item = tree_control.create_item(parent_item)
	item.set_text(0, node.get_name())
	for c in node.get_children():
		_build_tree(tree_control, c, item)

func _get_path(tree_item, tree):
	var path = tree_item.get_text(0)
	while tree_item.get_parent() != tree.get_root():
		tree_item = tree_item.get_parent()
		path = tree_item.get_text(0)+"/"+path
	return path

func _connect():
	if mOutputsTree.get_selected() == null || mInputsTree.get_selected() == null:
		return
	var output_path = _get_path(mOutputsTree.get_selected(), mOutputsTree)
	var input_path = _get_path(mInputsTree.get_selected(), mInputsTree)
	data_router.add_connection(output_path, input_path)

func _disconnect():
	print("_disconnect(): TODO")

func refresh():
	mOutputsTree.clear()
	_build_tree(mOutputsTree, get_node("/root/data_router/output_ports"))
	mInputsTree.clear()
	_build_tree(mInputsTree, get_node("/root/data_router/input_ports"))
