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

var mModule = null

onready var mAddWidgetButton = get_node("button_area/add_widget_button")
onready var mEditWidgetsButton = get_node("button_area/edit_widgets_button")
onready var mWidgetFactoriesPanel = get_node("widget_factories_panel")
onready var mGridBackground = get_node("grid_area/scroller/background")
onready var mGridControl = get_node("grid_area/scroller/grid")
onready var mScrollbarH = get_node("grid_area/scroll_bar_h")
onready var mScrollbarV = get_node("grid_area/scroll_bar_v")

func _ready():
	get_viewport().connect("size_changed", self, "_on_size_changed")
	mAddWidgetButton.connect("pressed", self, "show_widget_factories_panel")
	mEditWidgetsButton.connect("toggled", self, "toggle_edit_mode")
	mWidgetFactoriesPanel.connect("item_selected", self, "_on_widget_factory_item_selected")
	mScrollbarH.connect("value_changed", self, "_scroll")
	mScrollbarV.connect("value_changed", self, "_scroll")
	mGridControl.connect("item_rect_changed", self, "_on_size_changed")
	#var popup = get_node("add_widget_button").get_popup()
	#popup.connect("item_pressed", mGridControl, "add_widget")

func _on_widget_factory_item_selected(item):
	var task_id = item.get_widget_factory_task().id
	var pos = mGridControl.get_pos().abs()
	mGridControl.add_widget(task_id, pos)
	mWidgetFactoriesPanel.set_hidden(true)

func _on_size_changed():
	rcos.log_debug(self, "_on_size_changed()")
	var area_size = get_node("grid_area").get_size()
	var grid_size = mGridControl.get_size()
	var scroller = get_node("grid_area/scroller")
	var hscrollbar = get_node("grid_area/scroll_bar_h")
	var vscrollbar = get_node("grid_area/scroll_bar_v")
	var corner = get_node("grid_area/corner_rect")
	hscrollbar.set_hidden(grid_size.x <= area_size.x)
	vscrollbar.set_hidden(grid_size.y <= area_size.y)
	var hscroll = false
	var vscroll = false
	if !hscrollbar.is_hidden():
		area_size.y -= 40
	if !vscrollbar.is_hidden():
		area_size.x -= 40
	if grid_size.x > area_size.x:
		hscroll = true
	if grid_size.y > area_size.y:
		vscroll = true
	corner.set_hidden(true)
	if hscroll && vscroll:
		scroller.set_margin(MARGIN_RIGHT, 40)
		scroller.set_margin(MARGIN_BOTTOM, 40)
		hscrollbar.set_hidden(false)
		hscrollbar.set_margin(MARGIN_RIGHT, 40)
		vscrollbar.set_hidden(false)
		vscrollbar.set_margin(MARGIN_BOTTOM, 40)
		corner.set_hidden(false)
	elif hscroll:
		scroller.set_margin(MARGIN_RIGHT, 0)
		scroller.set_margin(MARGIN_BOTTOM, 40)
		hscrollbar.set_hidden(false)
		hscrollbar.set_margin(MARGIN_RIGHT, 0)
		vscrollbar.set_hidden(true)
	elif vscroll:
		scroller.set_margin(MARGIN_RIGHT, 40)
		scroller.set_margin(MARGIN_BOTTOM, 0)
		hscrollbar.set_hidden(true)
		vscrollbar.set_hidden(false)
		vscrollbar.set_margin(MARGIN_BOTTOM, 0)
	else:
		scroller.set_margin(MARGIN_RIGHT, 0)
		scroller.set_margin(MARGIN_BOTTOM, 0)
		hscrollbar.set_hidden(true)
		vscrollbar.set_hidden(true)
	hscrollbar.set_max(grid_size.x)
	hscrollbar.set_page(scroller.get_size().x)
	vscrollbar.set_max(grid_size.y)
	vscrollbar.set_page(scroller.get_size().y)
	mGridBackground.set_size(area_size - mGridControl.get_pos())

func _scroll(val):
	var x = -mScrollbarH.get_val()
	var y = -mScrollbarV.get_val()
	mGridControl.set_pos(Vector2(x, y))
	mGridBackground.set_pos(Vector2(x, y))

func init(module):
	mModule = module

func go_back():
	if mWidgetFactoriesPanel.is_hidden():
		return false
	mWidgetFactoriesPanel.set_hidden(true)
	return true

func show_widget_factories_panel():
	mWidgetFactoriesPanel.set_hidden(false)

func toggle_edit_mode(edit_mode):
	mGridControl.toggle_edit_mode(edit_mode)

func update_available_widgets(widget_factory_tasks):
	mWidgetFactoriesPanel.update_available_widgets(widget_factory_tasks)
