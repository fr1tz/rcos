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

const ADDRESS_ITEM_SCENE_PATH = "res://remote_connector/address_item.tscn"

onready var mHostNameEdit = get_node("hostname_edit")
onready var mIconButton = get_node("icon_button")
onready var mColorButton = get_node("color_button")
onready var mAddressesList = get_node("addresses_panel/addresses_scroller/addresses_list")
onready var mAddAddressEdit = get_node("add_address_edit")
onready var mAddAddressButton = get_node("add_address_button")
onready var mCancelButton = get_node("cancel_button")
onready var mSaveButton = get_node("save_button")
onready var mIconSelectorDialog = get_node("dialogs/icon_selector_dialog")
onready var mColorSelectorDialog = get_node("dialogs/color_selector_dialog")

var mMainGui = null
var mHostInfoService = null

func _ready():
	mIconButton.connect("pressed", self, "show_dialog", ["icon_selector_dialog"])
	mColorButton.connect("pressed", self, "show_dialog", ["color_selector_dialog"])
	mAddAddressEdit.connect("text_changed", self, "_add_address_text_changed")
	mAddAddressEdit.connect("text_entered", self, "_add_address_button_pressed")
	mAddAddressButton.connect("pressed", self, "_add_address_button_pressed")
	mAddAddressButton.set_disabled(true)
	mCancelButton.connect("pressed", self, "_cancel")
	mSaveButton.connect("pressed", self, "_save")
	mIconSelectorDialog.connect("cancel_button_pressed", self, "hide_dialogs")
	mIconSelectorDialog.connect("icon_selected", self, "_icon_selected")
	mIconSelectorDialog.add_icons("res://data_router/icons/32", "device_*.png")
	mColorSelectorDialog.connect("cancel_button_pressed", self, "hide_dialogs")
	mColorSelectorDialog.connect("color_selected", self, "_color_selected")

func _add_address_text_changed(text):
	mAddAddressButton.set_disabled(text == "")

func _add_address_button_pressed(dummy_arg = ""):
	add_address(mAddAddressEdit.get_text())
	mAddAddressEdit.set_text("")

func _cancel():
	mMainGui.hide_dialogs()

func _save():
	if !rcos.has_node("services/host_info_service"):
		return
	var host_name = mHostNameEdit.get_text() 
	var host_info_service = rcos.get_node("services/host_info_service")
	var host_info = host_info_service.get_host_info_from_hostname(host_name)
	if host_info == null:
		host_info = host_info_service.create_host_info(host_name)
	host_info.set_host_name(host_name)
	host_info.set_host_icon(mIconButton.get_button_icon())
	host_info.set_host_color(mColorButton.get_node("color_frame").get_frame_color())
	host_info.clear_addresses()
	for c in mAddressesList.get_children():
		var addr = c.get_text()
		host_info.add_address(addr)
	host_info_service.save_changes()
	mMainGui._update_services()
	mMainGui.hide_dialogs()

func _icon_selected(texture):
	set_icon(texture)
	hide_dialogs()

func _color_selected(color):
	set_color(color)
	hide_dialogs()

func initialize(main_gui):
	mMainGui = main_gui

func clear():
	mHostNameEdit.set_text("Device Name")
	mIconButton.set_button_icon(load("res://data_router/icons/32/question_mark.png"))
	mColorButton.get_node("color_frame").set_frame_color(Color(1, 1, 1))
	for c in mAddressesList.get_children():
		mAddressesList.remove_child(c)
		c.free()

func set_icon(texture):
	mIconButton.set_button_icon(texture)

func set_color(color):
	mColorButton.get_node("color_frame").set_frame_color(color)

func add_address(addr):
	var item = rlib.instance_scene(ADDRESS_ITEM_SCENE_PATH)
	mAddressesList.add_child(item)
	item.set_text(addr)

func load_host_info(host_info):
	clear()
	mHostNameEdit.set_text(host_info.get_host_name())
	mIconButton.set_button_icon(host_info.get_host_icon())
	mColorButton.get_node("color_frame").set_frame_color(host_info.get_host_color())
	for addr in host_info.get_addresses():
		add_address(addr)

func hide_dialogs():
	get_node("dialogs").set_hidden(true)

func show_dialog(dialog_name):
	var dialogs = get_node("dialogs")
	dialogs.set_hidden(false)
	for dialog in dialogs.get_children():
		dialog.set_hidden(dialog.get_name() != dialog_name)
