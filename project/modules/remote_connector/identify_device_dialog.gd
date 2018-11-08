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

extends ColorFrame

const DEVICE_ITEM_SCENE_PATH = "res://modules/remote_connector/device_item.tscn"

onready var mDeviceAddressLabel = get_node("device_address_label")
onready var mDevicesList = get_node("devices_panel/devices_scroller/devices_list")
onready var mAddDeviceButton = get_node("add_device_button")
onready var mCancelButton = get_node("cancel_button")

var mMainGui = null
var mDeviceEditorDialog = null

func _ready():
	mAddDeviceButton.connect("pressed", self, "_add_device")
	mCancelButton.connect("pressed", self, "_cancel")

func _device_selected(host_info):
	if !rcos.has_node("services/host_info_service"):
		return
	var host_info_service = rcos.get_node("services/host_info_service")
	host_info.add_address(mDeviceAddressLabel.get_text())
	host_info_service.save_changes()
	mMainGui._update_services()
	mMainGui.hide_dialogs()

func _add_device():
	mDeviceEditorDialog.clear()
	mDeviceEditorDialog.add_address(mDeviceAddressLabel.get_text())
	mMainGui.show_dialog("device_editor_dialog")

func _cancel():
	mMainGui.hide_dialogs()

func initialize(main_gui, device_editor_dialog):
	mMainGui = main_gui
	mDeviceEditorDialog = device_editor_dialog

func set_device_address(addr):
	mDeviceAddressLabel.set_text(addr)
	
func refresh_known_devices():
	for c in mDevicesList.get_children():
		mDevicesList.remove_child(c)
		c.free()
	if !rcos.has_node("services/host_info_service"):
		return
	var host_info_service = rcos.get_node("services/host_info_service")
	for host_info in host_info_service.get_host_info_nodes():
		if host_info.get_host_name() == "localhost":
			continue
		var item = rlib.instance_scene(DEVICE_ITEM_SCENE_PATH)
		mDevicesList.add_child(item)
		item.load_host_info(host_info)
		item.connect("pressed", self, "_device_selected", [host_info])
