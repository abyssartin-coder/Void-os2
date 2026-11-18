extends Node2D

const W := 540.0
const H := 960.0
const LANE_W := 150.0
const ROAD_X := 45.0
const CAR := Vector2(70, 120)
const CAR_Y := 800.0

var lane := 1
var car_x := 270.0
var obstacles: Array = []
var spawn_t := 0.0
var speed := 380.0
var score := 0.0
var best := 0
var dead := false
var dead_t := 0.0
var line_off := 0.0
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	randomize()
	_reset()


func _reset() -> void:
	lane = 1
	car_x = _lane_x(1)
	obstacles.clear()
	spawn_t = 0.5
	speed = 380.0
	score = 0.0
	dead = false
	dead_t = 0.0


func _lane_x(l: int) -> float:
	return ROAD_X + LANE_W * l + LANE_W / 2.0


func _move(dir: int) -> void:
	if dead:
		if dead_t > 0.4:
			_reset()
		return
	lane = clampi(lane + dir, 0, 2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var x := get_global_mouse_position().x
		_move(-1 if x < W / 2.0 else 1)
	elif event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right"):
		_move(1)


func _process(delta: float) -> void:
	if dead:
		dead_t += delta
	else:
		score += delta * 10.0
		speed = 380.0 + score * 1.5
		line_off = fmod(line_off + speed * delta, 80.0)
		car_x = lerpf(car_x, _lane_x(lane), minf(1.0, delta * 14.0))

		spawn_t -= delta
		if spawn_t <= 0.0:
			spawn_t = maxf(0.45, 1.1 - score * 0.004) * randf_range(0.85, 1.25)
			obstacles.append({
				"lane": randi() % 3,
				"y": -CAR.y,
				"color": Color.from_hsv(randf(), 0.55, 0.9),
			})

		var car_rect := Rect2(car_x - CAR.x / 2.0 + 6.0, CAR_Y - CAR.y / 2.0 + 10.0, CAR.x - 12.0, CAR.y - 20.0)
		for o in obstacles:
			o["y"] += speed * 0.75 * delta
			var r := Rect2(_lane_x(o["lane"]) - CAR.x / 2.0 + 6.0, o["y"] - CAR.y / 2.0 + 10.0, CAR.x - 12.0, CAR.y - 20.0)
			if r.intersects(car_rect):
				dead = true
				dead_t = 0.0
				best = maxi(best, int(score))
		obstacles = obstacles.filter(func(o): return o["y"] < H + 150.0)
	queue_redraw()


func _draw_car(pos: Vector2, color: Color) -> void:
	var half := CAR / 2.0
	draw_rect(Rect2(pos.x - half.x - 6, pos.y - half.y + 14, 10, 28), Color("111111"))
	draw_rect(Rect2(pos.x + half.x - 4, pos.y - half.y + 14, 10, 28), Color("111111"))
	draw_rect(Rect2(pos.x - half.x - 6, pos.y + half.y - 42, 10, 28), Color("111111"))
	draw_rect(Rect2(pos.x + half.x - 4, pos.y + half.y - 42, 10, 28), Color("111111"))
	draw_rect(Rect2(pos.x - half.x, pos.y - half.y, CAR.x, CAR.y), color)
	draw_rect(Rect2(pos.x - half.x + 8, pos.y - half.y + 22, CAR.x - 16, 26), Color("1b1d23"))
	draw_rect(Rect2(pos.x - half.x + 8, pos.y + half.y - 24, CAR.x - 16, 12), color.darkened(0.25))


func _text(t: String, y: float, size: int, color: Color = Color.WHITE) -> void:
	draw_string(font, Vector2(0, y), t, HORIZONTAL_ALIGNMENT_CENTER, W, size, color)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("2f3b2f"))
	draw_rect(Rect2(ROAD_X, 0, LANE_W * 3.0, H), Color("3a3d45"))
	draw_rect(Rect2(ROAD_X - 6, 0, 6, H), Color("d98a1f"))
	draw_rect(Rect2(ROAD_X + LANE_W * 3.0, 0, 6, H), Color("d98a1f"))
	for i in range(1, 3):
		var x := ROAD_X + LANE_W * i
		var y := -80.0 + line_off
		while y < H:
			draw_rect(Rect2(x - 3, y, 6, 44), Color("e8e4d4"))
			y += 80.0

	for o in obstacles:
		_draw_car(Vector2(_lane_x(o["lane"]), o["y"]), o["color"])
	_draw_car(Vector2(car_x, CAR_Y), Color("f0a23a"))

	_text("SCORE  %d" % int(score), 56, 36)
	if best > 0:
		_text("BEST  %d" % best, 92, 24, Color("d98a1f"))

	if dead:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.6))
		_text("GAME OVER", 420, 64)
		_text("Score  %d" % int(score), 490, 36)
		_text("Best  %d" % best, 535, 28, Color("f0a23a"))
		if dead_t > 0.4:
			_text("Tap to play again", 620, 30)
	elif score < 3.0:
		_text("Tap left / right side to change lane", 900, 24, Color(1, 1, 1, 0.8))
