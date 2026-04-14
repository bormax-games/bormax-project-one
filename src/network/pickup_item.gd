extends Area3D

@export var bob_height := 0.15
@export var bob_speed := 2.0
@export var spin_speed := 45.0

var _start_position := Vector3.ZERO
var _time := 0.0

func _ready() -> void:
	add_to_group("pickup_item")
	_start_position = global_position


func _process(delta: float) -> void:
	_time += delta
	rotation_degrees.y += spin_speed * delta
	global_position.y = _start_position.y + sin(_time * bob_speed) * bob_height
