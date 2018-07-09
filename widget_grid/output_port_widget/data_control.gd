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

extends ReferenceFrame

onready var mIcon = get_node("icon")
onready var mLabel = get_node("label")

func set_icon(texture):
	mIcon.set_texture(texture)

func set_label(text):
	mLabel.set_text(text)
	mLabel.set_pos(get_size()/2 - mLabel.get_size()/2 - Vector2(0, 16))
