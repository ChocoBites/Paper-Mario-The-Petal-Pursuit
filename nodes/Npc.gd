extends KinematicBody

export(NodePath) var area_path
onready var area: Area = get_node(area_path)

export(float, 0, 2) var walk_speed = 0.5

export(int, 0, 500) var min_walk_time = 100
export(int, 0, 500) var max_walk_time = 300

export(int, 0, 500) var min_wait_time = 10
export(int, 0, 500) var max_wait_time = 100

# home is starting position
onready var home = global_transform.origin.round()

var wait_time: int = 0
var walk_time: int = 0

var dir: Vector3

func _ready() -> void:
	area.connect("body_exited", self, "_on_area_exit")

func _physics_process(_delta) -> void:
	#rotation_degrees.y += 1
	#return

	if wait_time > 0:
		wait_time -= 1
	elif walk_time > 0:
		walk_time -= 1
		move_and_slide(dir * walk_speed, Vector3.UP)

		if walk_time == 0:
			wait_time = rand_range(min_wait_time, max_wait_time)
	else:
		# choose new direction to walk in
		dir = Vector3(rand_range(-1, 1), 0, rand_range(-1, 1)).normalized()
		look_at(global_transform.origin + dir, Vector3.UP)
		walk_time = rand_range(min_walk_time, max_walk_time)

func _on_area_exit(body):
	if body == self:
		print("left area, going home")

		# walk towards home
		dir = (home - global_transform.origin).normalized()

		look_at(home, Vector3.UP)

		#wait_time = rand_range(min_wait_time, max_wait_time)
		walk_time = rand_range(min_walk_time, max_walk_time)
