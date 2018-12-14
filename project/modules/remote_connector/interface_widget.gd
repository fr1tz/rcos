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

extends Button

var mMainGui = null
var mServiceInfo = null

func _init():
	add_user_signal("selected")

func _ready():
	get_node("button").connect("pressed", self, "_selected")
	get_node("hbox/favorite_box/button").connect("pressed", self, "_toggle_fav")
	var isquare_size = rcos.get_isquare_size()
	var isquare = Vector2(isquare_size, isquare_size)
	get_node("hbox/favorite_box").set_custom_minimum_size(isquare)

func _selected():
	emit_signal("selected")

func _toggle_fav():
	mServiceInfo.favorite = !mServiceInfo.favorite
	_update_fav_button()
	mMainGui.save_favorites()

func _update_fav_button():
	var icon = get_node("hbox/favorite_box/icon")
	if mServiceInfo.favorite:
		icon.set_modulate(Color(1, 1, 0))
	else:
		icon.set_modulate(Color(1, 1, 1))

func activate():
	rcos.open(mServiceInfo.url)

func get_desc():
	return mServiceInfo.desc

func update():
	get_node("hbox/icon").set_texture(mServiceInfo.icon)
	get_node("hbox/label").set_text(mServiceInfo.name)

func initialize(main_gui, service_info):
	mMainGui = main_gui
	mServiceInfo = service_info
	if !mServiceInfo.has("favorite"):
		mServiceInfo["favorite"] = false
	update()
	_update_fav_button()
