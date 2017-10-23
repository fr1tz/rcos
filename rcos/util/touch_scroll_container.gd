
extends Control

const STATE_INACTIVE = 0
const STATE_SELECT = 1
const STATE_SCROLL = 2

var mState = STATE_INACTIVE
var mActiveIndex = -1
var mInitialTouchPos = Vector2(0, 0)
var mLastTouchPos = Vector2(0, 0)
var mSelectStateTimeout = 0
var mNextViewportInputEventId = 0

func _ready():
	set_process_input(true)

func _input(event):
	if !is_visible():
		return
	if event.type == InputEvent.SCREEN_TOUCH \
	|| event.type == InputEvent.SCREEN_DRAG:
		_process_screen_input(event)

func _process_screen_input(event):
	if mState == STATE_INACTIVE \
	&& event.type == InputEvent.SCREEN_TOUCH \
	&& event.is_pressed() \
	&& get_global_rect().has_point(event.pos):
		_set_select_state(event.index, event.pos)
	elif mState == STATE_SELECT \
	&& event.type == InputEvent.SCREEN_DRAG \
	&& event.index == mActiveIndex \
	&& (event.pos-mInitialTouchPos).length() > 5:
		_set_scroll_state()
	elif mState == STATE_SCROLL \
	&& event.type == InputEvent.SCREEN_DRAG \
	&& event.index == mActiveIndex:
		_scroll(event.pos - mLastTouchPos)
	elif mState != STATE_INACTIVE \
	&& event.type == InputEvent.SCREEN_TOUCH \
	&& !event.is_pressed() \
	&& event.index == mActiveIndex:
		if mState == STATE_SELECT \
		&& get_global_rect().has_point(event.pos):
			_send_click_to_viewport()
		_set_inactive_state()
	# Update last touch pos.
	if event.index == mActiveIndex:
		mLastTouchPos = event.pos

func _process(delta):
	mSelectStateTimeout -= delta
	if mSelectStateTimeout <= 0:
		_set_scroll_state()

func _set_inactive_state():
	mState = STATE_INACTIVE
	mActiveIndex = -1
	set_process(false)
	print("new state: inactive")

func _set_select_state(touch_index, touch_pos):
	mState = STATE_SELECT
	mActiveIndex = touch_index
	mInitialTouchPos = touch_pos
	mSelectStateTimeout = 0.5
	set_process(true)
	print("new state: select")

func _set_scroll_state():
	mState = STATE_SCROLL
	set_process(false)
	print("new state: scroll")

func _scroll(scroll_vec):
	#print("scroll: ", scroll_vec)
	var viewport = get_node("Viewport")
	var container = viewport.get_child(0)
	if container == null:
		return
	var viewport_width = viewport.get_rect().size.x
	var container_width = container.get_size().x
	if container_width > viewport_width:
		var x = container.get_pos().x + scroll_vec.x
		x = clamp(x, viewport_width-container_width, 0)
		container.set_pos(Vector2(x, container.get_pos().y))
	var viewport_height = viewport.get_rect().size.y
	var container_height = container.get_size().y
	if container_height > viewport_height:
		var y = container.get_pos().y + scroll_vec.y
		y = clamp(y, viewport_height-container_height, 0)
		container.set_pos(Vector2(container.get_pos().x, y))

func _send_click_to_viewport():
	var viewport = get_node("Viewport")
	var pos = mLastTouchPos - get_global_pos()
	print("click: ", pos)
	var ev = InputEvent()
	# Send mouse down.
	mNextViewportInputEventId += 1
	ev.type = InputEvent.MOUSE_BUTTON
	ev.ID = mNextViewportInputEventId
	ev.button_mask = 1
	ev.pos = pos
	ev.x = ev.pos.x
	ev.y = ev.pos.y
	ev.button_index = 1
	ev.pressed = true
	viewport.input(ev)
	# Send mouse up.
	mNextViewportInputEventId += 1
	ev.ID = mNextViewportInputEventId
	ev.pressed = false
	viewport.input(ev)
