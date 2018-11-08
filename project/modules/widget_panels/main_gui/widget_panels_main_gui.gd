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

extends Panel

const PANELS_CONFIG_DIR = "user://etc/widget_panels.d"
const CONFIG_FILE_PATH = "user://etc/widget_panels.conf"

onready var mPanelItems = get_node("items_container/items")

var mModule = null
var mSelectedItem = null

func _ready():
	get_node("buttons/new").connect("pressed", self, "_create_widget_panel")
	get_node("buttons/rename").connect("pressed", self, "_rename_selected_widget_panel")
	get_node("buttons/toggle").connect("pressed", self, "_toggle_selected_widget_panel")
	get_node("buttons/remove").connect("pressed", self, "_remove_selected_widget_panel")

func _create_widget_panel():
	var dir = Directory.new()
	var widget_panel_id = 1
	while true:
		if mPanelItems.has_node(str(widget_panel_id)):
			widget_panel_id += 1
		else:
			break
	var widget_panel_label = "Widget Panel "+str(widget_panel_id)
	var item = rlib.instance_scene("res://modules/widget_panels/main_gui/widget_panel_item.tscn")
	item.set_name(str(widget_panel_id))
	item.set_text(widget_panel_label)
	item.connect("pressed", self, "_item_selected", [item])
	get_node("items_container/items").add_child(item)
	_save()
	mModule.show_widget_panel(widget_panel_id, widget_panel_label)

func _toggle_selected_widget_panel():
	if mSelectedItem == null:
		return

func _remove_selected_widget_panel():
	if mSelectedItem == null:
		return
	var panel_id = mSelectedItem.get_name()
	mModule.hide_widget_panel(panel_id)
	mPanelItems.remove_child(mSelectedItem)
	mSelectedItem.free()
	mSelectedItem = null
	_save()

func _item_selected(item):
	if mSelectedItem != null:
		mSelectedItem.set_pressed(false)
	mSelectedItem = item

func _save():
	var panels = []
	for panel_item in mPanelItems.get_children():
		panels.push_back({
			"id": panel_item.get_name(),
			"label": panel_item.get_text(),
			"disabled": false
		})
	var file = File.new()
	if file.open(CONFIG_FILE_PATH, File.WRITE) != OK:
		return
	var config = {
		"version": 0,
		"panels": panels
	}
	file.store_buffer(config.to_json().to_utf8())
	file.close()

func _load():
	var file = File.new()
	if file.open(CONFIG_FILE_PATH, File.READ) != OK:
		return
	var text = file.get_buffer(file.get_len()).get_string_from_utf8()
	file.close()
	var config = {}
	if config.parse_json(text) != OK:
		return
	if config.version == 0:
		for panel in config.panels:
			var item = rlib.instance_scene("res://modules/widget_panels/main_gui/widget_panel_item.tscn")
			item.set_name(panel.id)
			item.set_text(panel.label)
			item.connect("pressed", self, "_item_selected", [item])
			get_node("items_container/items").add_child(item)
			mModule.show_widget_panel(panel.id, panel.label)

func initialize(module):
	mModule = module
	var dir = Directory.new()
	if !dir.dir_exists(PANELS_CONFIG_DIR):
		dir.make_dir_recursive(PANELS_CONFIG_DIR)
	_load()

