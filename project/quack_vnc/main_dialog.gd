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

onready var mFBViewer = get_node("fb_viewer")

var mModule = null
var mGui = null
var mConnection = null

func _canvas_input(event):
	if !is_visible():
		return
	if event.type == InputEvent.KEY:
		mConnection.process_key_event(event)

func _zoom_button_selected(button_idx):
	if button_idx == 0:
		mFBViewer.mZoom = 0.1
	elif button_idx == 1:
		mFBViewer.mZoom = 0.25
	elif button_idx == 2:
		mFBViewer.mZoom = 0.5
	elif button_idx == 3:
		mFBViewer.mZoom = 1
	elif button_idx == 4:
		mFBViewer.mZoom = 2
	mFBViewer.update()

func zoom_in():
	mFBViewer.mZoom += 0.1
	mFBViewer.update()

func zoom_out():
	mFBViewer.mZoom -= 0.1
	mFBViewer.update()

func initialize(module, gui, connection):
	mModule = module
	mGui = gui
	mConnection = connection
	mFBViewer.initialize(mConnection)
	for i in range(1, 4):
		var button = get_node("controls/button"+str(i))
		button.connect("button_down", mConnection, "set_button_pressed", [i, true])
		button.connect("button_up", mConnection, "set_button_pressed", [i, false])
	get_node("controls/toggle_keyboard").connect("pressed", OS, "show_virtual_keyboard")
	get_node("controls/zoom_out").connect("pressed", self, "zoom_out")
	get_node("controls/zoom_in").connect("pressed", self, "zoom_in")
	get_node("controls/zoom_buttons").connect("button_selected", self, "_zoom_button_selected")
	rcos.enable_canvas_input(self)
