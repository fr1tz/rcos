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

var mOverlayDrawNodes = {}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func enable_overlay_draw(node):
#	if mOverlayDrawNodes.has(node):
#		return
#	if !node.has_method("_overlay_draw"):
#		return
#	var widget_container = null
#	for c in mWidgetContainers.get_children():
#		if c.is_a_parent_of(node):
#			widget_container = c
#			break
#	if widget_container == null:
#		return
#	mOverlayDrawNodes[node] = widget_container
#
#func disable_overlay_draw(node):
#	mOverlayDrawNodes.erase(node)
#
#func update_overlay_draw():
#	mOverlay.update()
#
#func draw_overlay():
#	for node in mOverlayDrawNodes.keys():
#		var widget_container = mOverlayDrawNodes[node]
#		var canvas = widget_container.get_widget_canvas()
#		var canvas_size = canvas.get_rect().size
#		var center = widget_container.get_pos() + widget_container.get_size()/2
#		var rot = widget_container.get_widget_rotation()
#		var pos = center + Vector2(-canvas_size.x/2, -canvas_size.y/2).rotated(rot)
#		var scale = Vector2(1, 1)
#		mOverlay.draw_set_transform(pos, rot, scale)
#		node._overlay_draw(mOverlay)
