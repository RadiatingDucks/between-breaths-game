extends CharacterBody2D

enum STATES{MOVE, CLIMB}

#exports of movement values
@export var max_speed: = 350
@export var acceleration: = 1000
@export var air_acceleration: = 1500
@export var friction: = 1000
@export var air_friction: = 500
@export var up_gravity: = 1400
@export var down_gravity: = 1400
@export var jump_amount: = -700

@export var state := STATES.MOVE

@onready var animation_player: AnimationPlayer = $AnimationPlayer


const SPEED = 350.0
const JUMP_VELOCITY = -600.0

var start_position = Vector2(0,0)
var water_contact_count = 0


func _physics_process(delta: float) -> void:
	
	match state:
		STATES.MOVE:
			# Add the gravity.
			apply_gravity(delta)
			
			#if not is_on_floor():
				#velocity.y += up_gravity * delta

			# Handle jump.
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = jump_amount

			# Get the input direction and handle the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			var direction := Input.get_axis("move_left", "move_right")
				
			if direction == 0:
				apply_friction(delta)
				animation_player.play("idle")
			if direction != 0:
				accelerate_x(direction, delta)
				animation_player.play("run")

			move_and_slide()
	
func accelerate_x(horizontal_direction: float, delta: float) -> void:
	var acceleration_amount = acceleration
	if not is_on_floor(): acceleration_amount = air_acceleration
	velocity.x = move_toward(velocity.x, max_speed * horizontal_direction, acceleration_amount * delta)

func apply_friction(delta: float) -> void:
	var friction_amount = friction
	if not is_on_floor(): friction_amount = air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += up_gravity * delta
		else:
			velocity.y += down_gravity * delta
	pass
	
	

	if position.y > 900:
		died()
	
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		



func died() -> void:
	position = Global.checkpoint


func _on_water_detector_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
		if body.name == "water":
			water_contact_count += 1
			if water_contact_count == 1:
				$time_out_water.stop()
	


func _on_time_out_water_timeout() -> void:
	died()
	


func _on_water_detector_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.name == "water":
		water_contact_count -= 1
		if water_contact_count <= 0:
			water_contact_count = 0  # Safety: prevent negative
			$time_out_water.start()
