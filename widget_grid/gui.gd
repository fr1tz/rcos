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
var mTaskId = -1

onready var mAddWidgetButton = get_node("button_area/add_widget_button")
onready var mEditWidgetsButton = get_node("button_area/edit_widgets_button")
onready var mSaveButton = get_node("button_area/save_button")
onready var mLoadButton = get_node("button_area/load_button")
onready var mFullscreenButton = get_node("button_area/fullscreen_button")
onready var mRaiseLowerWidgetButton = get_node("button_area/edit_buttons/raiselower")
onready var mReshapeWidgetButton = get_node("button_area/edit_buttons/reshape")
onready var mRotateWidgetButton = get_node("button_area/edit_buttons/rotate")
onready var mDeleteWidgetButton = get_node("button_area/edit_buttons/delete")
onready var mConfigureWidgetButton = get_node("button_area/edit_buttons/configure")
onready var mGridBackground = get_node("grid_area/scroller/background")
onready var mGridControl = get_node("grid_area/scroller/grid")
onready var mReshapeGrid = get_node("grid_area/scroller/reshape_grid")
onready var mScrollbarH = get_node("grid_area/scroll_bar_h")
onready var mScrollbarV = get_node("grid_area/scroll_bar_v")
onready var mWidgetFactoriesPanel = get_node("widget_factories_panel")
onready var mWidgetConfigWindow = get_node("widget_config_window")

func _ready():
	get_viewport().connect("size_changed", self, "_on_size_changed")
	mAddWidgetButton.connect("pressed", self, "show_widget_factories_panel")
	mEditWidgetsButton.connect("toggled", self, "toggle_edit_mode")
	mSaveButton.connect("pressed", mGridControl, "save_to_file")
	mLoadButton.connect("pressed", mGridControl, "load_from_file")
	mFullscreenButton.connect("pressed", self, "activate_fullscreen")
	mRaiseLowerWidgetButton.connect("pressed", mGridControl, "raiselower_selected_widget")
	mReshapeWidgetButton.connect("pressed", self, "reshape_selected_widget")
	mRotateWidgetButton.connect("pressed", mGridControl, "rotate_selected_widget")
	mDeleteWidgetButton.connect("pressed", mGridControl, "delete_selected_widget")
	mConfigureWidgetButton.connect("pressed", mGridControl, "configure_selected_widget")
	mWidgetFactoriesPanel.connect("item_selected", self, "_on_widget_factory_item_selected")
	mScrollbarH.connect("value_changed", self, "_scroll")
	mScrollbarV.connect("value_changed", self, "_scroll")
	mGridControl.connect("item_rect_changed", self, "_on_size_changed")

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
	var hscroll = false
	var vscroll = false
	if grid_size.x > area_size.x && grid_size.y > area_size.y:
		hscroll = true
		vscroll = true
	elif grid_size.x > area_size.x:
		hscroll = true
	elif grid_size.y > area_size.y:
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
	mReshapeGrid.set_size(area_size - mGridControl.get_pos())

func _scroll(val):
	var x = -mScrollbarH.get_val()
	var y = -mScrollbarV.get_val()
	mGridControl.set_pos(Vector2(x, y))
	mGridBackground.set_pos(Vector2(x, y))
	mReshapeGrid.set_pos(Vector2(x, y))

func _reshape_selected_widget_begin():
	mReshapeGrid.clear_painted_rect()
	mReshapeGrid.connect("finished", self, "_reshape_selected_widget_finish")
	mReshapeGrid.set_hidden(false)

func _reshape_selected_widget_finish():
	mReshapeGrid.disconnect("finished", self, "_reshape_selected_widget_finish")
	mReshapeGrid.set_hidden(true)
	var widget_container = mGridControl.get_selected_widget_container()
	if widget_container == null:
		return
	var rect = mReshapeGrid.get_painted_rect()
	widget_container.set_pos(rect.pos)
	widget_container.set_size(rect.size)

func reshape_selected_widget():
	_reshape_selected_widget_begin()

func init(module, task_id):
	mModule = module
	mTaskId = task_id

func go_back():
	var task = rcos.get_task(mTaskId)
	if task.has("fullscreen") && task.fullscreen:
		var new_task_properties = {
			"canvas_region": null,
			"fullscreen": false
		}
		rcos.change_task(mTaskId, new_task_properties)
	if mWidgetFactoriesPanel.is_hidden() \
	&& mWidgetConfigWindow.is_hidden():
		return false
	mWidgetFactoriesPanel.set_hidden(true)
	mWidgetConfigWindow.set_hidden(true)
	return true

func show_widget_factories_panel():
	mWidgetFactoriesPanel.set_hidden(false)

func toggle_edit_mode(edit_mode):
	get_node("button_area/edit_buttons").set_hidden(!edit_mode)
	mGridControl.toggle_edit_mode(edit_mode)

func update_available_widgets(widget_factory_tasks):
	mWidgetFactoriesPanel.update_available_widgets(widget_factory_tasks)

func activate_fullscreen():
	var new_task_properties = {
		"canvas_region": get_node("grid_area/scroller").get_global_rect(),
		"fullscreen": true
	}
	rcos.change_task(mTaskId, new_task_properties)
