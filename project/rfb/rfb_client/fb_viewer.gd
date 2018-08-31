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

extends ReferenceFrame

const STATE_IDLE = 0
const STATE_SELECT = 1
const STATE_SCROLL = 2
const STATE_ZOOM = 3

var mConnection = null
var mZoom = 1
var mState = STATE_IDLE
var mNumTouches = 0
var mTouches = []
var mInitialTouchPos = {}
var mLastTouchPos = {}
var mDesktop = {
	"texture": null,
	"dirty": false
}
var mCursor = {
	"texture": null,
	"hotspot": Vector2(0, 0),
	"pos": Vector2(0, 0)
}

func _ready():
	get_node("activate_scroll_state_timer").connect("timeout", self, "_set_state", [STATE_SCROLL])

func _draw():
	#VisualServer.canvas_item_set_clip(get_canvas_item(), true)
	if mDesktop.texture != null:
		var fb_size = mDesktop.texture.get_size()
		var fb_rect = Rect2(Vector2(0, 0), fb_size)
		var vp_center = mCursor.pos 
		var vp_size = get_size()/mZoom
		var vp_rect = Rect2(vp_center - vp_size/2, vp_size)
		var src_rect = fb_rect.clip(vp_rect)
		var dst_size = src_rect.size*mZoom
		var dst_rect = Rect2((src_rect.pos - vp_rect.pos)*mZoom, dst_size)
		draw_rect(get_rect(), Color(0.2, 0.2, 0.2))
		draw_texture_rect_region(mDesktop.texture, dst_rect, src_rect)
	if mCursor.texture != null:
		draw_texture(mCursor.texture, get_size()/2 - mCursor.hotspot)

func _canvas_input(event):
	if mDesktop.texture == null || !is_visible() || event.type == InputEvent.KEY:
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	var oldNumTouches = mNumTouches
	if touch:
		if event.pressed:
			if get_rect().has_point(event.pos):
				mNumTouches += 1
				mTouches.append(index)
				mInitialTouchPos[index] = event.pos
		else:
			if mTouches.has(index):
				mNumTouches -= 1
				mTouches.erase(index)
		if oldNumTouches == 0 && mNumTouches == 1:
			_set_state(STATE_SELECT)
#		elif oldNumTouches == 1 && mNumTouches == 2:
#			_set_state(STATE_ZOOM)
		elif oldNumTouches == 2 && mNumTouches == 1:
			_set_state(STATE_SCROLL)
		elif oldNumTouches == 1 && mNumTouches == 0:
			if mState == STATE_SELECT && get_rect().has_point(event.pos):
				var vec = event.pos - (get_rect().pos + get_rect().size/2)
				var fb_pos =  mCursor.pos + vec/mZoom
				if (fb_pos.x >= 0 && fb_pos.x <= mDesktop.texture.get_width()) \
				&& (fb_pos.y >= 0 && fb_pos.y <= mDesktop.texture.get_height()):
					mCursor.pos = fb_pos
					mConnection.set_pointer_pos_x(int(fb_pos.x))
					mConnection.set_pointer_pos_y(int(fb_pos.y))
					update()
					#mConnection.send_pointer()
			_set_state(STATE_IDLE)
	elif drag:
		if mState == STATE_SELECT \
		&& (event.pos-mInitialTouchPos[index]).length() > 0:
			_set_state(STATE_SCROLL)
		elif mState == STATE_SCROLL:
			mCursor.pos -= event.relative_pos / mZoom
			mCursor.pos.x = clamp(mCursor.pos.x, 0, mDesktop.texture.get_width())
			mCursor.pos.y = clamp(mCursor.pos.y, 0, mDesktop.texture.get_height())
			mConnection.set_pointer_pos_x(int(mCursor.pos.x))
			mConnection.set_pointer_pos_y(int(mCursor.pos.y))
			update()
			#mConnection.send_pointer()
			#get_node("crosshair").set_hidden(false)	
		elif mState == STATE_ZOOM:
			var pos1 = mLastTouchPos[0]
			var pos2 = mLastTouchPos[1]
			var old_dist = (pos1 - pos2).length()
			if index == 0:
				pos1 = event.pos
			elif index == 1:
				pos2 = event.pos
			var new_dist = (pos1 - pos2).length()
			if new_dist > old_dist:
				mZoom = clamp(mZoom+0.1, 0.1, 2)
			elif new_dist < old_dist:
				mZoom = clamp(mZoom-0.1, 0.1, 2)
			update()
	# Update last touch pos.
	mLastTouchPos[index] = event.pos

func _set_state(state):
	mState = state
	if mState == STATE_SELECT:
		get_node("activate_scroll_state_timer").start()
	else:
		get_node("activate_scroll_state_timer").stop()

func _update_desktop():
	var image = mConnection.get_desktop_fb().get_image()
	if mDesktop.texture == null:
		mDesktop.texture = ImageTexture.new()
		mCursor.pos = Vector2(image.get_width(), image.get_height())/2
	mDesktop.texture.create_from_image(image, Texture.FLAG_FILTER)
	mDesktop.dirty = false
	update()

func _update_cursor():
	var image = mConnection.get_cursor_fb().get_image()
	mCursor.hotspot = mConnection.get_cursor_hotspot()
	if mCursor.texture == null:
		mCursor.texture = ImageTexture.new()
	mCursor.texture.create_from_image(image, 0)
	update()

func _desktop_fb_changed(fb):
	mDesktop.dirty = true
	if is_visible():
		_update_desktop()

func _cursor_fb_changed(fb):
	mCursor.dirty = true
	if is_visible():
		_update_cursor()

func _visibility_changed():
	if is_visible():
		if mDesktop.dirty:
			_update_desktop()
		if mDesktop.dirty:
			_update_cursor()

func initialize(connection):
	mConnection = connection
	mConnection.connect("desktop_fb_changed", self, "_desktop_fb_changed")
	mConnection.connect("cursor_fb_changed", self, "_cursor_fb_changed")
	connect("visibility_changed", self, "_visibility_changed")
	rcos.enable_canvas_input(self)
