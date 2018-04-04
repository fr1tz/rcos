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

func disable_canvas_input(node):
	rcos.disable_canvas_input(node)

func enable_canvas_input(node):
	rcos.enable_canvas_input(node)

func enable_overlay_draw(node):
	mWidgetHost.enable_overlay_draw(node)

func disable_overlay_draw(node):
	mWidgetHost.disable_overlay_draw(node)

func update_overlay_draw():
	mWidgetHost.update_overlay_draw()
