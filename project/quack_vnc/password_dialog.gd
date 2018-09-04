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

func _init():
	add_user_signal("password_entered")

func _ready():
	get_node("line_edit").connect("text_changed", self, "_text_changed")
	get_node("line_edit").connect("text_entered", self, "_text_entered")
	get_node("button").connect("pressed", self, "_button_pressed")

func _text_changed(text):
	get_node("button").set_disabled(text == "")

func _text_entered(text):
	if text != "":
		emit_signal("password_entered", text)

func _button_pressed():
	var password = get_node("line_edit").get_text()
	emit_signal("password_entered", password)
