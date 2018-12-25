extends ReferenceFrame

var mClock = 0

func _ready():
	connect("visibility_changed", self, "_visibility_changed")

func _visibility_changed():
	mClock = 0
	set_fixed_process(!is_hidden())

func _fixed_process(delta):
	mClock += delta
	var icon = get_node("spinner/icon")
	icon.set_rot(icon.get_rot() - delta*2)
	var label = get_node("label")
	label.set_hidden(fmod(mClock, 0.5) > 0.25)
