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

extends Button

func set_icon(texture):
	get_node("hsplit/icon/icon").set_texture(texture)

func set_icon_frame_color(color):
	if color == null: color = Color(0, 0, 0, 0)
	get_node("hsplit/icon/icon_frame").set_modulate(color)

func set_icon_label(text):
	if text == null: text = ""
	get_node("hsplit/icon/icon_label").set_text(text)

func set_text(text):
	if text == null: text = ""
	if text == "":
		get_node("hsplit/label").set_hidden(true)
	else:
		get_node("hsplit/label").set_hidden(false)
		get_node("hsplit/label").set_text(text)

func get_text():
	return get_node("hsplit/label").get_text()
