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

var mEditorId = -1
var mTaskId = -1
var mSelectedReshapeControl = null

onready var mEditWidgetsButton = get_node("button_area/edit_widgets_button")
onready var mAddWidgetButton = get_node("button_area/add_widget_button")
onready var mAddOutputPortButton = get_node("button_area/add_output_port_button")
onready var mAddInputPortButton = get_node("button_area/add_input_port_button")
onready var mSaveButton = get_node("button_area/save_button")
onready var mLoadButton = get_node("button_area/load_button")
onready var mFullscreenButton = get_node("button_area/fullscreen_button")
onready var mRaiseLowerWidgetButton = get_node("button_area/edit_buttons/raiselower")
onready var mReshapeWidgetButton = get_node("button_area/edit_buttons/reshape")
onready var mRotateWidgetButton = get_node("button_area/edit_buttons/rotate")
onready var mDeleteWidgetButton = get_node("button_area/edit_buttons/delete")
onready var mConfigureWidgetButton = get_node("button_area/edit_buttons/configure")
onready var mGridControl = get_node("grid_area/grid_control")
onready var mReshapeControls = get_node("grid_area/reshape_controls")
onready var mReshapeGrid = get_node("grid_area/reshape_grid")
onready var mWidgetFactoriesPanel = get_node("widget_factories_panel")
onready var mOutputPortSelector = get_node("output_node_selector")
onready var mInputPortSelector = get_node("input_node_selector")

func _ready():
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
	mOutputPortSelector.connect("canceled", self, "show_grid")
	mOutputPortSelector.connect("node_selected", self, "_output_port_selected")
	mInputPortSelector.connect("canceled", self, "show_grid")
	mInputPortSelector.connect("node_selected", self, "_input_port_selected")	
	var widget_grid_service = rcos.get_node("services/widget_grid_service")
	update_available_widgets(widget_grid_service.get_widget_factory_tasks())
	widget_grid_service.connect("widget_factory_tasks_changed", self, "update_available_widgets")

func _save_to_file():
	var conf_file_path = "user://etc/widget_grids/widget_grid_editor_"+mEditorId+".conf"
	mGridControl.save_to_file(conf_file_path)

func _load_from_file():
	var conf_file_path = "user://etc/widget_grids/widget_grid_editor_"+mEditorId+".conf"
	mGridControl.load_from_file(conf_file_path)

func _on_widget_factory_item_selected(item):
	var task_id = item.get_widget_factory_task_id()
	var pos = mGridControl.get_pos().abs()
	mGridControl.add_widget(task_id, pos)
	show_grid()

func _output_port_selected(node):
	var srv = rcos.get_node("services/rcos_widgets_service")
	var task_id = srv.get_widget_factory_task_id("output_port_widget")
	if task_id == -1:
		return
	var container = mGridControl.add_widget(task_id, Vector2(0, 0))
	var widget = container.get_widget()
	widget.get_config_gui()._port_selected(node)
	show_grid()

func _input_port_selected(node):
	var srv = rcos.get_node("services/rcos_widgets_service")
	var task_id = srv.get_widget_factory_task_id("input_port_widget")
	if task_id == -1:
		return
	var container = mGridControl.add_widget(task_id, Vector2(0, 0))
	var widget = container.get_widget()
	widget.get_config_gui()._port_selected(node)
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
	var rect = mReshapeGrid.get_painted_rect()
	widget_container.set_pos(rect.pos)
	widget_container.set_size(rect.size)
	mSelectedReshapeControl.set_pos(rect.pos)
	mSelectedReshapeControl.set_size(rect.size)

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
	widget_container.configure(mTaskId)

func delete_selected_widget():
	if mSelectedReshapeControl == null:
		return
	var widget_container = mSelectedReshapeControl.get_control()
	if widget_container == null:
		return
	widget_container.queue_free()
	widget_container = null
	mSelectedReshapeControl.queue_free()
	mSelectedReshapeControl = null

func init(editor_id, task_id, io_ports_path_prefix):
	mEditorId = editor_id
	mTaskId = task_id
	mGridControl.set_io_ports_path_prefix(io_ports_path_prefix)

func go_back():
	var properties = rcos.get_task_properties(mTaskId)
	if properties.has("fullscreen") && properties.fullscreen:
		var new_task_properties = {
			"canvas_region": null,
			"fullscreen": false
		}
		rcos.change_task(mTaskId, new_task_properties)
		return true
	if mWidgetFactoriesPanel.is_hidden():
		return false
	mWidgetFactoriesPanel.set_hidden(true)
	return true

func show_grid():
	mWidgetFactoriesPanel.set_hidden(true)
	mOutputPortSelector.set_hidden(true)
	mInputPortSelector.set_hidden(true)

func show_widget_factories_panel():
	mWidgetFactoriesPanel.set_hidden(false)
	mOutputPortSelector.set_hidden(true)
	mInputPortSelector.set_hidden(true)

func show_output_port_selector():
	mWidgetFactoriesPanel.set_hidden(true)
	mOutputPortSelector.set_hidden(false)
	mInputPortSelector.set_hidden(true)

func show_input_port_selector():
	mWidgetFactoriesPanel.set_hidden(true)
	mOutputPortSelector.set_hidden(true)
	mInputPortSelector.set_hidden(false)

func _on_reshape_control_clicked(reshape_control):
	if mSelectedReshapeControl != null:
		if reshape_control == mSelectedReshapeControl:
			return
		mSelectedReshapeControl.deselect()
	mSelectedReshapeControl = reshape_control
	mSelectedReshapeControl.select()

func toggle_edit_mode(edit_mode):
	get_node("button_area/edit_buttons").set_hidden(!edit_mode)
	mReshapeControls.set_hidden(!edit_mode)
	mGridControl.toggle_edit_mode(edit_mode)
	if edit_mode:
		var widget_containers = mGridControl.get_widget_containers()
		for container in widget_containers:
			var reshape_control = rlib.instance_scene("res://widget_grid/widget_grid_editor/reshape_control.tscn")
			mReshapeControls.add_child(reshape_control)
			reshape_control.set_control(container)
			reshape_control.set_pos(container.get_pos())
			reshape_control.set_size(container.get_size())
			reshape_control.connect("clicked", self, "_on_reshape_control_clicked", [reshape_control])
	else:
		mSelectedReshapeControl = null
		for reshape_control in mReshapeControls.get_children():
			mReshapeControls.remove_child(reshape_control)
			reshape_control.free()

func update_available_widgets(widget_factory_tasks):
	mWidgetFactoriesPanel.update_available_widgets(widget_factory_tasks)

func activate_fullscreen():
	var new_task_properties = {
		"canvas_region": get_node("grid_area").get_global_rect(),
		"fullscreen": true
	}
	rcos.change_task(mTaskId, new_task_properties)
