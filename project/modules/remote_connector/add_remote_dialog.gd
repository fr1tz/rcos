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

onready var mCancelButton = get_node("cancel_button")
onready var mSaveButton = get_node("save_button")

var mMainGui = null

func _ready():
	mCancelButton.connect("pressed", self, "_cancel")
	mSaveButton.connect("pressed", self, "_save")

func _cancel():
	mMainGui.hide_dialogs()

func _save():
	if !rcos.has_node("services/host_info_service"):
		return

func initialize(main_gui):
	mMainGui = main_gui
