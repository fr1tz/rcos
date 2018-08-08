# Copyright © 2018 Michael Goldener <mg@wasted.ch>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#-------------------------------------------------------------------------------
# Widget Host API
#-------------------------------------------------------------------------------

var mWidgetHost = null

func _init(widget_host):
	mWidgetHost = widget_host

func enable_widget_frame_input(node):
	var parent_node = node.get_parent()
	while parent_node != null:
		if parent_node.has_method("enable_widget_frame_input"):
			if parent_node.enable_widget_frame_input(node):
				node.set_meta("widget_frame", parent_node)
			return true
		parent_node = parent_node.get_parent()
	return false

func disable_widget_frame_input(node):
	if !node.has_meta("widget_frame"):
		return true
	var widget_frame = node.get_meta("widget_frame")
	widget_frame.disable_widget_frame_input(node)
	return true

func enable_overlay_draw(node):
	mWidgetHost.enable_overlay_draw(node)

func disable_overlay_draw(node):
	mWidgetHost.disable_overlay_draw(node)

func update_overlay_draw():
	mWidgetHost.update_overlay_draw()
