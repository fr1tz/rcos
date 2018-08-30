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

var mConnection = null
var mFramebufferTexture = null
var mCursorTexture = null
var mCursorHotspot = Vector2(0, 0)
var mViewportCenter = Vector2(0, 0)
var mZoom = 1.0
var mState = STATE_IDLE
var mActiveIndex = -1
var mInitialTouchPos = Vector2(0, 0)
var mLastTouchPos = Vector2(0, 0)

func _ready():
	get_node("activate_scroll_state_timer").connect("timeout", self, "_set_state", [STATE_SCROLL])

func _draw():
	if mFramebufferTexture != null:
		var fb_size = mFramebufferTexture.get_size()
		var fb_rect = Rect2(Vector2(0, 0), fb_size)
		var viewport_rect = Rect2(mViewportCenter - get_size()/2, get_size())
		var src_rect = fb_rect.clip(viewport_rect)
		var rect = Rect2(src_rect.pos - viewport_rect.pos, src_rect.size)
		draw_rect(get_rect(), Color(0.2, 0.2, 0.2))
		draw_texture_rect_region(mFramebufferTexture, rect, src_rect)
	if mCursorTexture != null:
		draw_texture(mCursorTexture, get_size()/2 - mCursorHotspot)

func _canvas_input(event):
	if !is_visible() || event.type == InputEvent.KEY:
		return
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var index = 0
	if touchscreen:
		index = event.index
	if mState == STATE_IDLE \
	&& touch \
	&& event.pressed \
	&& get_rect().has_point(event.pos):
		mActiveIndex = index
		mInitialTouchPos = event.pos
		_set_state(STATE_SELECT)
	elif mState == STATE_SELECT \
	&& drag \
	&& index == mActiveIndex \
	&& (event.pos-mInitialTouchPos).length() > 5:
		_set_state(STATE_SCROLL)
	elif mState == STATE_SCROLL \
	&& drag \
	&& index == mActiveIndex:
		mViewportCenter -= event.relative_pos
		#mViewportCenter.x = clamp(mViewportCenter.x, 0, mFramebufferTexture.get_width())
		#mViewportCenter.y = clamp(mViewportCenter.y, 0, mFramebufferTexture.get_height())
		mConnection.set_pointer_pos_x(int(mViewportCenter.x))
		mConnection.set_pointer_pos_y(int(mViewportCenter.y))
		update()
		#mConnection.send_pointer()
		#get_node("crosshair").set_hidden(false)
	elif mState != STATE_IDLE \
	&& touch \
	&& !event.pressed \
	&& index == mActiveIndex:
		if mState == STATE_SELECT && get_rect().has_point(event.pos):
			var vec = event.pos - (get_rect().pos + get_rect().size/2)
			var fb_pos =  mViewportCenter + vec
			if (fb_pos.x >= 0 && fb_pos.x <= mFramebufferTexture.get_width()) \
			|| (fb_pos.y >= 0 && fb_pos.y <= mFramebufferTexture.get_height()):
				mViewportCenter = fb_pos
				mConnection.set_pointer_pos_x(int(fb_pos.x))
				mConnection.set_pointer_pos_y(int(fb_pos.y))
				update()
				#mConnection.send_pointer()
		mActiveIndex = -1
		#get_node("crosshair").set_hidden(true)
		_set_state(STATE_IDLE)
	# Update last touch pos.
	if index == mActiveIndex:
		mLastTouchPos = event.pos

func _set_state(state):
	mState = state
	if mState == STATE_SELECT:
		get_node("activate_scroll_state_timer").start()
	else:
		get_node("activate_scroll_state_timer").stop()

func _framebuffer_changed(image):
	if mFramebufferTexture == null:
		mFramebufferTexture = ImageTexture.new()
		mViewportCenter = Vector2(image.get_width(), image.get_height())/2
	mFramebufferTexture.create_from_image(image, 0)
	update()

func _cursor_changed(image, hotspot):
	mCursorHotspot = hotspot
	if mCursorTexture == null:
		mCursorTexture = ImageTexture.new()
	mCursorTexture.create_from_image(image, 0)
	update()

func initialize(connection):
	mConnection = connection
	mConnection.connect("framebuffer_changed", self, "_framebuffer_changed")
	mConnection.connect("cursor_changed", self, "_cursor_changed")
	rcos.enable_canvas_input(self)
