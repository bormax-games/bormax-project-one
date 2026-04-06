extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.8
const GRAVITY := 12.0
const SEND_INTERVAL := 0.05
const LERP_RATE := 12.0

@onready var camera: Camera3D = $Pivot/Camera3D
@onready var label_3d: Label3D = $Label3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var peer_id: int = -1
var input_dir := Vector2.ZERO
var jump_requested := false
var send_timer := 0.0

var target_position := Vector3.ZERO
var target_velocity := Vector3.ZERO
var target_basis := Basis.IDENTITY
var received_first_state := false

func _ready() -> void:
	_ensure_inputs()
	if camera != null:
		camera.current = false


func setup_from_peer(new_peer_id: int) -> void:
	peer_id = new_peer_id
	name = str(peer_id)
	label_3d.text = "Peer %d" % peer_id
	target_position = global_position
	target_velocity = velocity
	target_basis = basis
	if _is_local_player() and camera != null:
		camera.current = true


func _physics_process(delta: float) -> void:
	if not Net.is_online():
		return

	if Net.is_server():
		if _is_local_player():
			_capture_input_locally()
		_server_simulate(delta)
		return

	if _is_local_player():
		_capture_input_locally()
		send_timer -= delta
		if send_timer <= 0.0:
			send_timer = SEND_INTERVAL
			rpc_id(1, "_rpc_submit_input", peer_id, input_dir, jump_requested)
			jump_requested = false
		_interpolate_to_server(delta)
	else:
		_interpolate_to_server(delta)


func _server_simulate(delta: float) -> void:
	var dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	velocity.y -= GRAVITY * delta
	if is_on_floor() and jump_requested:
		velocity.y = JUMP_VELOCITY
	jump_requested = false

	move_and_slide()

	if dir.length() > 0.01:
		look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)

	Net.broadcast_player_state(peer_id, global_position, velocity, basis)


func _interpolate_to_server(delta: float) -> void:
	if not received_first_state:
		return
	global_position = global_position.lerp(target_position, min(1.0, delta * LERP_RATE))
	velocity = velocity.lerp(target_velocity, min(1.0, delta * LERP_RATE))
	basis = basis.slerp(target_basis, min(1.0, delta * LERP_RATE))


func apply_server_state(pos: Vector3, vel: Vector3, new_basis: Basis) -> void:
	target_position = pos
	target_velocity = vel
	target_basis = new_basis
	if not received_first_state:
		received_first_state = true
		global_position = pos
		velocity = vel
		basis = new_basis


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_submit_input(sent_peer_id: int, sent_input_dir: Vector2, sent_jump: bool) -> void:
	if not Net.is_server():
		return
	if multiplayer.get_remote_sender_id() != sent_peer_id:
		return
	if sent_peer_id != peer_id:
		return
	input_dir = sent_input_dir.limit_length(1.0)
	if sent_jump:
		jump_requested = true


func _capture_input_locally() -> void:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z := Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_dir = Vector2(x, z)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	if Input.is_action_just_pressed("jump"):
		jump_requested = true
	if Input.is_action_just_pressed("interact"):
		Net.request_pickup(peer_id)


func _is_local_player() -> bool:
	return multiplayer.get_unique_id() == peer_id


func _ensure_inputs() -> void:
	var actions := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"interact": KEY_E
	}
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.keycode = actions[action]
			InputMap.action_add_event(action, ev)
