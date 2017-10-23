extends Button

var mInfo = null

func _ready():
	connect("pressed", self, "open_connection")

func open_connection():
	rcos.open_connection(mInfo)

func update_info(info):
	mInfo = info
	get_node("interface_name").set_text(info.name)
