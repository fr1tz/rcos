extends Button

var mInfo = ""

func _init():
	add_user_signal("activated")

func _ready():
	get_node("button").connect("pressed", self, "_emit_on_pressed_signal")

func _emit_on_pressed_signal():
	emit_signal("pressed")

func activate():
	emit_signal("activated")

func get_info():
	return mInfo

func set_icon(tex):
	get_node("icon").set_texture(tex)

func set_info(info):
	mInfo = info
