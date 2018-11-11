extends ColorFrame

var mRot = 0

func _ready():
	set_process(true)

func _process(delta):
	mRot -= 0.1
	update()

func _draw():
	draw_set_transform(get_size()/2, mRot, Vector2(1, 1))
	draw_line(Vector2(-15, 0), Vector2(15, 0), Color(1, 0, 1), 2)
	draw_line(Vector2(0, -15), Vector2(0, 15), Color(1, 1, 1), 2)
