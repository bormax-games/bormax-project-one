extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

#animation path
@onready var anim = $magician/AnimationPlayer


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		#animation jump
		if anim.current_animation != "jump":
			anim.play("jump")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		#animation walk
		if anim.current_animation != "walk" and anim.current_animation != "jump":
			anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		#animation idle
		if anim.current_animation != "idle" and anim.current_animation != "jump":
			anim.play("idle")

	move_and_slide()
