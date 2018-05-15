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

extends ReferenceFrame

const STATE_INACTIVE = 0
const STATE_SELECT = 1
const STATE_SCROLL = 2

var mState = STATE_INACTIVE
var mActiveIndex = -1
var mInitialTouchPos = Vector2(0, 0)
var mLastTouchPos = Vector2(0, 0)
var mSelectStateTimeout = 0

func _ready():
	rcos.enable_canvas_input(self)
	
func _get_input_area():
	if has_node("input_area"):
		return get_node("input_area").get_global_rect()
	return get_global_rect()

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
	if mState == STATE_INACTIVE \
	&& touch \
	&& event.pressed \
	&& _get_input_area().has_point(event.pos):
		_set_select_state(index, event.pos)
	elif mState == STATE_SELECT \
	&& drag \
	&& index == mActiveIndex \
	&& (event.pos-mInitialTouchPos).length() > 5:
		_set_scroll_state()
	elif mState == STATE_SCROLL \
	&& drag \
	&& index == mActiveIndex:
		_scroll(event.pos - mLastTouchPos)
	elif mState != STATE_INACTIVE \
	&& touch \
	&& !event.pressed \
	&& index == mActiveIndex:
		if mState == STATE_SELECT \
		&& _get_input_area().has_point(event.pos):
			_send_click()
		_set_inactive_state()
	# Update last touch pos.
	if index == mActiveIndex:
		mLastTouchPos = event.pos

func _process(delta):
	mSelectStateTimeout -= delta
	if mSelectStateTimeout <= 0:
		_set_scroll_state()

func _set_inactive_state():
	mState = STATE_INACTIVE
	mActiveIndex = -1
	set_process(false)
	call_deferred("set_ignore_mouse", false)
	get_parent().emit_signal("scrolling_stopped")
	#print("new state: inactive")

func _set_select_state(touch_index, touch_pos):
	mState = STATE_SELECT
	mActiveIndex = touch_index
	mInitialTouchPos = touch_pos
	mSelectStateTimeout = 0.5
	set_process(true)
	#print("new state: select")

func _set_scroll_state():
	mState = STATE_SCROLL
	set_process(false)
	get_parent().emit_signal("scrolling_started")
	#print("new state: scroll")

func _scroll(scroll_vec):
	get_parent().scroll(scroll_vec)
	#print("scroll: ", scroll_vec)

func _send_click():
	var pos = mLastTouchPos
	set_ignore_mouse(true)
	#print("scroller_input_area(): click: ", pos)
	var canvas = get_viewport()
	# Send mouse down.
	var ev = InputEvent()
	ev.device = -1
	ev.type = InputEvent.MOUSE_BUTTON
	ev.ID = canvas.get_next_input_event_id()
	ev.button_mask = 1
	ev.pos = pos
	ev.x = ev.pos.x
	ev.y = ev.pos.y
	ev.button_index = 1
	ev.pressed = true
	canvas.input(ev)
	# Send mouse up.
	ev.ID = canvas.get_next_input_event_id()
	ev.pressed = false
	canvas.input(ev)
