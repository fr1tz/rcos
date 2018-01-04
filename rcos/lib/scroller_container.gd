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

func _init():
	add_user_signal("scrolling_started")
	add_user_signal("scrolling_stopped")

func _draw():
     VisualServer.canvas_item_set_clip(get_canvas_item(),true)

func scroll(scroll_vec):
	var container = get_child(0)
	if container == null:
		return
	var viewport_width = get_rect().size.x
	var container_width = container.get_size().x
	if container_width > viewport_width:
		var x = container.get_pos().x + scroll_vec.x
		x = clamp(x, viewport_width-container_width, 0)
		container.set_pos(Vector2(x, container.get_pos().y))
	var viewport_height = get_rect().size.y
	var container_height = container.get_size().y
	if container_height > viewport_height:
		var y = container.get_pos().y + scroll_vec.y
		y = clamp(y, viewport_height-container_height, 0)
		container.set_pos(Vector2(container.get_pos().x, y))
