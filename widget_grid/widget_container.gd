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

extends ColorFrame

var mEditMode = false
var mReshapeControl = null

func _ready():
	mReshapeControl = get_node("reshape_control")
	mReshapeControl.set_control(self)

func set_widget(widget):
	get_node("widget").add_child(widget)
	widget.set_pos(Vector2(0, 0))
	set_size(widget.get_size())

func toggle_edit_mode(edit_mode):
	mEditMode = edit_mode
	mReshapeControl.set_hidden(!edit_mode)

func get_reshape_control():
	return mReshapeControl