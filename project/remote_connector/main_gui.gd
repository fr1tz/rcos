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

onready var mInterfaceWidgetContainers = get_node("interfaces_panel/interfaces_scroller/interfaces_list")
onready var mInfoWidget = get_node("info_panel/info_widget")
onready var mOpenConnectionButton = get_node("buttons/open_connection")
onready var mScanButton = get_node("buttons/scan")
onready var mCancelScanButton = get_node("scan_progress/cancel_button")
onready var mOpenConnectionDialog = get_node("dialogs/open_connection_dialog")
onready var mIdentifyDeviceDialog = get_node("dialogs/identify_device_dialog")
onready var mDeviceEditorDialog = get_node("dialogs/device_editor_dialog")

var mHostInfoService = null
var mNetworkScannerService = null
var mSelectedInterfaceWidget = null
var mServices = []

func _ready():
	get_viewport().connect("display", self, "_on_displayed")
	get_viewport().connect("conceal", self, "_on_concealed")
	get_viewport().connect("size_changed", self, "_on_size_changed")
	mOpenConnectionButton.connect("pressed", mOpenConnectionDialog, "set_hidden", [false])
	if rcos.has_node("services/host_info_service"):
		mHostInfoService = rcos.get_node("services/host_info_service")
		mHostInfoService.connect("host_info_changed", self, "_host_info_changed")
	if rcos.has_node("services/network_scanner_service"):
		mNetworkScannerService = rcos.get_node("services/network_scanner_service")
		mNetworkScannerService.connect("scan_started", self, "_scan_started")
		mNetworkScannerService.connect("service_discovered", self, "_service_discovered")
		mNetworkScannerService.connect("scan_finished", self, "_scan_finished")
		mScanButton.connect("pressed", mNetworkScannerService, "start_scan")
		mCancelScanButton.connect("pressed", mNetworkScannerService, "stop_scan")
		mNetworkScannerService.call_deferred("start_scan")
	else:
		mScanButton.set_hidden(true)
	mOpenConnectionDialog.initialize(self)
	mIdentifyDeviceDialog.initialize(self, mDeviceEditorDialog)
	mDeviceEditorDialog.initialize(self)

func _scan_started():
	mServices = []
	for c in mInterfaceWidgetContainers.get_children():
		mInterfaceWidgetContainers.remove_child(c)
		c.free()
	mSelectedInterfaceWidget = null
	get_node("scan_progress").set_hidden(false)

func _scan_finished():
	get_node("scan_progress").set_hidden(true)

func _service_discovered(service_info):
	mServices.push_back(service_info)
	_add_service(service_info)

func _add_service(service_info):
	var interface_widget = add_interface_widget(service_info.host)
	interface_widget.set_url(service_info.url)
	interface_widget.set_icon(service_info.icon)
	interface_widget.set_text(service_info.name)
	interface_widget.set_desc(service_info.desc)

func _host_info_changed(host_info):
	for c in mInterfaceWidgetContainers.get_children():
		mInterfaceWidgetContainers.remove_child(c)
		c.free()
	for service_info in mServices:
		_add_service(service_info)

func _show_tab(idx):
	get_node("tabs").set_current_tab(idx)
	
func _on_displayed():
	#print("connector: _on_displayed")
	rcos.log_debug(self, "_on_displayed()")

func _on_concealed():
	#print("connector: _on_concealed")
	rcos.log_debug(self, "_on_concealed()")

func _on_size_changed():
	rcos.log_debug(self, "_on_size_changed()")
	var width = float(get_viewport().get_rect().size.x - 4 - 8 - 10)
	var new_column_count = floor(width/(42+2))
	for interface_container in mInterfaceWidgetContainers.get_children():
		interface_container.mInterfaceWidgets.set_columns(new_column_count)

func _interface_widget_selected(interface_widget):
	if interface_widget == mSelectedInterfaceWidget:
		mSelectedInterfaceWidget.activate()
	elif mSelectedInterfaceWidget != null:
		mSelectedInterfaceWidget.set_pressed(false)
		mInfoWidget.get_node("label").set_text("")
	mSelectedInterfaceWidget = interface_widget
	mSelectedInterfaceWidget.set_pressed(true)
	show_desc(mSelectedInterfaceWidget)

func _edit_button_pressed(interface_container):
	if mHostInfoService == null:
		return
	var host_label = interface_container.get_host_label()
	var host_info = mHostInfoService.get_host_info_from_hostname(host_label)
	if host_info == null:
		mIdentifyDeviceDialog.set_device_address(host_label)
		mIdentifyDeviceDialog.refresh_known_devices()
		show_dialog("identify_device_dialog")
	else:
		mDeviceEditorDialog.load_host_info(host_info)
		show_dialog("device_editor_dialog")

func add_interface_widget(host_addr):
	var host_info = null
	if mHostInfoService != null:
		host_info = mHostInfoService.get_host_info_from_address(host_addr)
	var host_label = host_addr
	if host_info != null:
		host_label = host_info.get_host_name()
	var interface_container = null
	for c in mInterfaceWidgetContainers.get_children():
		if c.get_host_label() == host_label:
			interface_container = c
			break
	if interface_container == null:
		interface_container = rlib.instance_scene("res://remote_connector/interface_widget_container.tscn")
		mInterfaceWidgetContainers.add_child(interface_container)
		interface_container.connect("edit_button_pressed", self, "_edit_button_pressed", [interface_container])
		interface_container.set_host_label(host_label)
		if host_info != null:
			var host_icon = host_info.get_host_icon()
			var host_color = host_info.get_host_color()
			interface_container.set_host_icon(host_icon)
			interface_container.set_host_color(host_color)
	var interface_widget = interface_container.add_interface_widget()
	interface_widget.connect("selected", self, "_interface_widget_selected", [interface_widget])
	return interface_widget

func show_desc(interface_widget):
	mInfoWidget.get_node("label").set_text(interface_widget.get_desc())

func hide_dialogs():
	get_node("dialogs").set_hidden(true)

func show_dialog(dialog_name):
	var dialogs = get_node("dialogs")
	dialogs.set_hidden(false)
	for dialog in dialogs.get_children():
		dialog.set_hidden(dialog.get_name() != dialog_name)
