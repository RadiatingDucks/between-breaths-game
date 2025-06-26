extends CharacterBody2D


const SPEED = 330.0
const JUMP_VELOCITY = -600.0

var start_position = Vector2(0,0)
var water_contact_count = 0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if position.y > 900:
		died()
	
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		



func died() -> void:
	position = Global.checkpoint


func _on_water_detector_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
		if body.name == "water":
			water_contact_count += 1
			if water_contact_count == 1:
				$time_out_water.stop()
	


func _on_time_out_water_timeout() -> void:
	died()
	


func _on_water_detector_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body.name == "water":
		water_contact_count -= 1
		if water_contact_count <= 0:
			water_contact_count = 0  # Safety: prevent negative
			$time_out_water.start()
