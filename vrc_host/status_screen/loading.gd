extends ReferenceFrame

export(Color) var color

var mProgress = 0
var mErrors = []

func _draw():
	var c = get_size()/2
	var r = get_size().x/2*mProgress
	draw_circle(c, r, color)
	for error in mErrors:
		r = get_size().x/2*error
		_draw_circle5(c, r, 0, 360, Color(1, 0, 0), 1)

func _draw_circle5(center, radius, angleFrom, angleTo, color, line_width = 1):
	var nbPoints = 32
	var pointsArc = Vector2Array() 
	for i in range(nbPoints+1):
		var anglePoint = angleFrom + i*(angleTo-angleFrom)/nbPoints - 90
		var point = center + Vector2( cos(deg2rad(anglePoint)), sin(deg2rad(anglePoint)) )* radius
		pointsArc.push_back( point )
	for indexPoint in range(nbPoints):
		#printt(indexPoint, pointsArc[indexPoint], pointsArc[indexPoint+1])
		draw_line(pointsArc[indexPoint], pointsArc[indexPoint+1], color, line_width)

func get_progress():
	return mProgress

func set_progress(progress):
	mProgress = clamp(progress, 0, 1)
	update()

func add_error():
	mErrors.append(mProgress)

