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

var mModule = null
var mWindow = null
var mWidgetPanelId = -1
var mConfigFile = null
var mSelectedReshapeControl = null

onready var mIOPorts = get_node("widget_panel_io_ports")
onready var mButtons = get_node("vsplit/buttons")
onready var mEditWidgetsButton = mButtons.get_node("edit_widgets_button")
onready var mAddWidgetButton = mButtons.get_node("add_widget_button")
onready var mAddOutputPortButton = mButtons.get_node("add_output_port_button")
onready var mAddInputPortButton = mButtons.get_node("add_input_port_button")
onready var mSaveButton = mButtons.get_node("save_button")
onready var mLoadButton = mButtons.get_node("load_button")
onready var mFullscreenButton = mButtons.get_node("fullscreen_button")
onready var mEditButtons = get_node("vsplit/edit_buttons")
onready var mRaiseLowerWidgetButton = mEditButtons.get_node("raiselower")
onready var mReshapeWidgetButton = mEditButtons.get_node("reshape")
onready var mRotateWidgetButton = mEditButtons.get_node("rotate")
onready var mDeleteWidgetButton = mEditButtons.get_node("delete")
onready var mConfigureWidgetButton = mEditButtons.get_node("configure")
onready var mGridArea = get_node("vsplit/grid_area")
onready var mWidgetGrid = mGridArea.get_node("widget_grid")
onready var mReshapeControls = mGridArea.get_node("reshape_controls")
onready var mReshapeGrid = mGridArea.get_node("reshape_grid")
onready var mWidgetFactoriesPanel = get_node("widget_factories_panel")

func _ready():
	mWidgetGrid.connect("grid_changed", self, "_widget_grid_changed")
	mWidgetGrid.connect("container_added", self, "_widget_container_added")
	mWidgetGrid.connect("container_changed", self, "_widget_container_changed")
	mWidgetGrid.connect("container_removed", self, "_widget_container_removed")
	mEditWidgetsButton.connect("toggled", self, "toggle_edit_mode")
	mAddWidgetButton.connect("pressed", self, "show_widget_factories_panel")
	mAddOutputPortButton.connect("pressed", self, "show_output_port_selector")
	mAddInputPortButton.connect("pressed", self, "show_input_port_selector")
	mSaveButton.connect("pressed", self, "_save_to_file")
	mLoadButton.connect("pressed", self, "_load_from_file")
	mFullscreenButton.connect("pressed", self, "activate_fullscreen")
	mRaiseLowerWidgetButton.connect("pressed", self, "raiselower_selected_widget")
	mReshapeWidgetButton.connect("pressed", self, "reshape_selected_widget")
	mRotateWidgetButton.connect("pressed", self, "rotate_selected_widget")
	mDeleteWidgetButton.connect("pressed", self, "delete_selected_widget")
	mConfigureWidgetButton.connect("pressed", self, "configure_selected_widget")
	mWidgetFactoriesPanel.connect("item_selected", self, "_on_widget_factory_item_selected")
	var widgets_service = rcos_services.get_service("widgets_service")
	update_available_widgets(widgets_service.get_widget_factory_tasks())
	widgets_service.connect("widget_factory_tasks_changed", self, "update_available_widgets")
	var isquare = Vector2(rcos.get_isquare_size(), rcos.get_isquare_size())
	mButtons.set_custom_minimum_size(isquare)
	for c in mButtons.get_children():
		c.set_custom_minimum_size(isquare)
	mEditButtons.set_custom_minimum_size(isquare)
	for c in mEditButtons.get_children():
		c.set_custom_minimum_size(isquare)
		c.set_disabled(true)

func _widget_grid_changed():
	var columns = mWidgetGrid.get_columns()
	var rows = mWidgetGrid.get_rows()
	mReshapeGrid.set_grid(columns, rows)

func _widget_container_added(container):
	var reshape_control = rlib.instance_scene("res://modules/widget_panels/panel_window/reshape_control.tscn")
	mReshapeControls.add_child(reshape_control)
	reshape_control.set_control(container)
	reshape_control.set_pos(container.get_pos())
	reshape_control.set_size(container.get_size())
	reshape_control.connect("clicked", self, "_reshape_control_clicked", [reshape_control])
	container.set_meta("reshape_control", reshape_control)

func _widget_container_changed(container):
	var reshape_control = container.get_meta("reshape_control")
	reshape_control.set_pos(container.get_pos())
	reshape_control.set_size(container.get_size())

func _widget_container_removed(container):
	var reshape_control = container.get_meta("reshape_control")
	if reshape_control == mSelectedReshapeControl:
		mSelectedReshapeControl = null
		for c in mEditButtons.get_children():
			c.set_disabled(true)
	mReshapeControls.remove_child(reshape_control)
	reshape_control.free()

func _reshape_control_clicked(reshape_control):
	if mSelectedReshapeControl != null:
		if reshape_control == mSelectedReshapeControl:
			return
		mSelectedReshapeControl.deselect()
	mSelectedReshapeControl = reshape_control
	mSelectedReshapeControl.select()
	for c in mEditButtons.get_children():
		c.set_disabled(false)

func _save_to_file():
	mWidgetGrid.save_to_file(mConfigFile)

func _load_from_file():
	if mWidgetGrid.load_from_file(mConfigFile):
		_widget_grid_changed()

func _on_widget_factory_item_selected(item):
	if mWidgetGrid.get_widget_containers().size() == 0:
		var isquare_size = rcos.get_isquare_size()
		var screen_size = mGridArea.get_size()
		var num_columns = int(floor(screen_size.x/isquare_size))
#		if columns % 2 != 0:
#			columns += 1
		var num_rows = int(floor(screen_size.y/isquare_size))
#		if rows % 2 != 0:
#			rows += 1
#		prints(screen_size.x, num_columns)
#		prints(screen_size.y, num_rows)
		mWidgetGrid.set_grid(num_columns, num_rows)
	var product_id = item.get_product_id()
	var grid_rect = [0, 0, 0, 0]
	var config_preset = item.get_config_preset()
	mWidgetGrid.create_widget(product_id, grid_rect, config_preset)
	show_grid()

func _reshape_selected_widget_begin():
	mReshapeGrid.clear_painted_rect()
	mReshapeGrid.connect("finished", self, "_reshape_selected_widget_finish")
	mReshapeGrid.set_hidden(false)

func _reshape_selected_widget_finish():
	mReshapeGrid.disconnect("finished", self, "_reshape_selected_widget_finish")
	mReshapeGrid.set_hidden(true)
	if mSelectedReshapeControl == null:
		return
	var widget_container = mSelectedReshapeControl.get_control()
	if widget_container == null:
		return
	var grid_rect = mReshapeGrid.get_painted_grid_rect()
	widget_container.set_grid_rect(grid_rect)

func reshape_selected_widget():
	_reshape_selected_widget_begin()

func raiselower_selected_widget():
	if mSelectedReshapeControl == null:
		return
	var widget_container = mSelectedReshapeControl.get_control()
	if widget_container == null:
		return
	var pos = widget_container.get_position_in_parent()
	if pos != widget_container.get_child_count() - 1:
		pos = widget_container.get_child_count() - 1
	else:
		pos = 0
	widget_container.get_parent().move_child(widget_container, pos)

func rotate_selected_widget():
	if mSelectedReshapeControl == null:
		return
	var widget_container = mSelectedReshapeControl.get_control()
	if widget_container == null:
		return
	widget_container.rotate()

func configure_selected_widget():
	if mSelectedReshapeControl == null:
		return
	var widget_container = mSelectedReshapeControl.get_control()
	if widget_container == null:
		return
	widget_container.configure(mWindow.get_task_id())

func delete_selected_widget():
	if mSelectedReshapeControl == null:
		return
	var widget_container = mSelectedReshapeControl.get_control()
	if widget_container == null:
		return
	widget_container.queue_free()

func go_back():
	if mWindow.set_fullscreen(false):
		return true
	if mWidgetFactoriesPanel.is_hidden():
		return false
	mWidgetFactoriesPanel.set_hidden(true)
	return true

func show_grid():
	mWidgetFactoriesPanel.set_hidden(true)

func show_widget_factories_panel():
	mWidgetFactoriesPanel.set_hidden(false)

func toggle_edit_mode(edit_mode):
	mEditButtons.set_hidden(!edit_mode)
	mReshapeControls.set_hidden(!edit_mode)
	mWidgetGrid.toggle_edit_mode(edit_mode)

func update_available_widgets(widget_factory_tasks):
	mWidgetFactoriesPanel.update_available_widgets(widget_factory_tasks)

func activate_fullscreen():
	mWindow.set_fullscreen(true)

func get_widget_panel_id():
	return mWidgetPanelId

func initialize(module, window, widget_panel_id):
	mModule = module
	mWindow = window
	mWidgetPanelId = widget_panel_id
	mConfigFile = mModule.CONFIG_DIR+"/widget_panel_"+str(widget_panel_id)+".conf"
	var io_ports_path_prefix = "rcos/widget_panel_"+str(widget_panel_id)+"/"
	mWidgetGrid.set_io_ports_path_prefix(io_ports_path_prefix)
	mIOPorts.initialize(self, io_ports_path_prefix)
	_load_from_file()
