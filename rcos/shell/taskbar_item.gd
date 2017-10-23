extends ReferenceFrame

var mTaskId = -1

func _init():
	add_user_signal("selected")

func _ready():
	get_node("button").connect("pressed", self, "emit_signal", ["selected"])

func get_task_id():
	return mTaskId

func set_task_id(task_id):
	mTaskId = task_id

func set_title(string):
	get_node("title").set_text(string)

func set_icon(texture):
	if texture == null:
		return
	get_node("icon").set_texture(texture)

func show_title():
	get_node("title").show()

func hide_title():
	get_node("title").hide()

func mark_active():
	get_node("button_down").show()

func mark_inactive():
	get_node("button_down").hide()
