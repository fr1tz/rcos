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

var mWidgetPanelId = -1
var mTaskId = -1
var mSelectedReshapeControl = null

onready var mIOPorts = get_node("widget_panel_io_ports")
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
onready var mWidgetPanel = get_node("grid_area/widget_panel")
onready var mReshapeControls = get_node("grid_area/reshape_controls")
onready var mReshapeGrid = get_node("grid_area/reshape_grid")
onready var mWidgetFactoriesPanel = get_node("widget_factories_panel")

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
	var widgets_service = rcos.get_node("services/widgets_service")
	update_available_widgets(widgets_service.get_widget_factory_tasks())
	widgets_service.connect("widget_factory_tasks_changed", self, "update_available_widgets")

func _save_to_file():
	var conf_file_path = "user://etc/widget_panels.d/widget_panel_"+str(mWidgetPanelId)+".conf"
	mWidgetPanel.save_to_file(conf_file_path)

func _load_from_file():
	var conf_file_path = "user://etc/widget_panels.d/widget_panel_"+str(mWidgetPanelId)+".conf"
	mWidgetPanel.load_from_file(conf_file_path)

func _on_widget_factory_item_selected(item):
	var task_id = item.get_widget_factory_task_id()
	var pos = mWidgetPanel.get_pos().abs()
	var config_preset = item.get_config_preset()
	mWidgetPanel.create_widget(task_id, pos, config_preset)
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

func init(panel_id, task_id, io_ports_path_prefix):
	mWidgetPanelId = panel_id
	mTaskId = task_id
	mWidgetPanel.set_io_ports_path_prefix(io_ports_path_prefix)
	mIOPorts.initialize(self, io_ports_path_prefix)

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

func show_widget_factories_panel():
	mWidgetFactoriesPanel.set_hidden(false)

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
	mWidgetPanel.toggle_edit_mode(edit_mode)
	if edit_mode:
		var widget_containers = mWidgetPanel.get_widget_containers()
		for container in widget_containers:
			var reshape_control = rlib.instance_scene("res://widget_panels/widget_panel/reshape_control.tscn")
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

func get_widget_panel_id():
	return mWidgetPanelId
