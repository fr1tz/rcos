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

extends ColorFrame

onready var mIconsList = get_node("icons_panel/icons_scroller/icons_list")
onready var mCancelButton = get_node("cancel_button")

func _init():
	add_user_signal("cancel_button_pressed")
	add_user_signal("icon_selected")

func _ready():
	mCancelButton.connect("pressed", self, "emit_signal", ["cancel_button_pressed"])

func _button_pressed(button):
	emit_signal("icon_selected", button.get_button_icon())

func clear_icons():
	for c in mIconsList.get_children():
		mIconsList.remove_child(c)
		c.free()

func add_icon(texture):
	var button = Button.new()
	mIconsList.add_child(button)
	button.set_custom_minimum_size(Vector2(40, 40))
	button.set_size(Vector2(40, 40))
	button.set_button_icon(texture)
	button.connect("pressed", self, "_button_pressed", [button])

func add_icons(dir_path, match_expr):
	var filenames = rlib.find_files(dir_path, match_expr)
	for filename in filenames:
		var texture = load(filename)
		add_icon(texture)
