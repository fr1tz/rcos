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

extends MarginContainer

func _draw():
	var rect = get_rect()
	draw_rect(rect, Color(0.2, 0.2, 0.2))
	var margin_bottom = get("custom_constants/margin_bottom")
	rect.size.y -= margin_bottom
	draw_rect(rect, Color(0.5, 0.5, 0.5))

