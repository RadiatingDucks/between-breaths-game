extends CharacterBody2D

#commented by ChatGPT

# Define states the player can be in
enum STATES { MOVE, CLIMB }

# ------------------------------
# Exported variables (tweakable in the inspector)
# ------------------------------
@export var max_speed := 350                  # Maximum horizontal speed
@export var acceleration := 1000              # Acceleration when on the ground
@export var air_acceleration := 1500          # Acceleration while in the air
@export var friction := 3000                  # Friction when on the ground
@export var air_friction := 500               # Friction while in the air
@export var up_gravity := 1500                # Gravity applied while moving upward
@export var down_gravity := 1500              # Gravity applied while moving downward
@export var jump_amount := -750               # Initial jump velocity

@export var direction = 0                     # Last input direction (left/right)

# ------------------------------
# Jump control
# ------------------------------
var coyote_time := 0                          # Small buffer time after leaving ground to still allow jumping
var jumping_amount = 0                        # How many jumps have been used so far
var max_jump = 2                              # Maximum allowed jumps (e.g. double jump)

# ------------------------------
# State handling
# ------------------------------
@export var state := STATES.MOVE              # Current state (default = MOVE)

# ------------------------------
# Node references
# ------------------------------
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var anchor: Node2D = $Anchor
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bubble_ui = get_node("../UI/bubbleUI") # UI for breath bubbles
@onready var redness = get_node("../UI/redness")    # UI for warning overlay (red fade)
@onready var water_timer := $time_out_water        # Timer for drowning

# ------------------------------
# Constants (not used everywhere but left in)
# ------------------------------
const SPEED = 350.0
const JUMP_VELOCITY = -600.0

# ------------------------------
# Other variables
# ------------------------------
var start_position = Vector2(0,0)             # Starting position of the player
var water_contact_count = 0                   # How many water bodies the player is inside
var total_bubbles := 5                        # Max number of UI bubbles
var max_time := 5.0                           # Time before drowning (matches timer length)

# ------------------------------
# Main physics loop
# ------------------------------
func _physics_process(delta: float) -> void:
	update_bubbles() # Update breath UI

	match state:
		STATES.MOVE:
			coyote_time -= delta

			# Apply gravity depending on movement
			apply_gravity(delta)

			# Reset jumps when on the ground
			if is_on_floor():
				jumping_amount = 0

			# Handle jumping (normal + coyote time + double jump)
			if Input.is_action_just_pressed("jump") and (jumping_amount < max_jump or coyote_time > 0):
				velocity.y = jump_amount
				jumping_amount += 1
				audioManager.play_sound("jump_land")

			# Horizontal movement input
			var direction := Input.get_axis("move_left", "move_right")

			# Track if we were grounded before moving
			var was_on_floor = is_on_floor()
			move_and_slide()

			# Idle case
			if direction == 0:
				apply_friction(delta)
				animation_player.play("idle")

			# Water sound effects
			if water_contact_count > 0:
				audioManager.play_loop("swim")
			else:
				audioManager.stop_sound("swim")

			# Running and jumping animations
			if direction != 0:
				# Flip player and hitbox depending on direction
				anchor.scale.x = sign(direction)
				collision_shape.scale.x = sign(direction)

				# Accelerate in chosen direction
				accelerate_x(direction, delta)

				# Animation depending on air/ground
				if not is_on_floor():
					animation_player.play("jump")
				else:
					animation_player.play("run")

			# Walking sounds (only on ground, not in water)
			if is_on_floor() and direction != 0 and water_contact_count <= 0:
				audioManager.play_loop("walk")
			else:
				audioManager.stop_sound("walk")

			# Coyote time: allow jump a short time after leaving ground
			if was_on_floor and not is_on_floor() and velocity.y > 0:
				coyote_time = 0.30
				jumping_amount += 1

# ------------------------------
# Movement helpers
# ------------------------------
func accelerate_x(horizontal_direction: float, delta: float) -> void:
	var acceleration_amount = acceleration
	if not is_on_floor():
		acceleration_amount = air_acceleration
	velocity.x = move_toward(velocity.x, max_speed * horizontal_direction, acceleration_amount * delta)

func apply_friction(delta: float) -> void:
	var friction_amount = friction
	if not is_on_floor():
		friction_amount = air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += up_gravity * delta
		else:
			velocity.y += down_gravity * delta

	# Reload scene with "R" (debug shortcut)
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

# ------------------------------
# Death + respawn
# ------------------------------
func died() -> void:
	position = Global.checkpoint

# Timer callback: drown when oxygen runs out
func _on_time_out_water_timeout() -> void:
	died()

# ------------------------------
# Water + hazard detection
# ------------------------------
func _on_water_detector_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.name == "water":
		water_contact_count += 1
		if water_contact_count == 1: # First entry
			fade_out_warning()
			$time_out_water.stop()
			audioManager.play_sound("splash")
			# Stop splash sound after 1 second
			get_tree().create_timer(1.0).timeout.connect(func(): audioManager.stop_sound("splash"))

	if body.name == "Spikes":
		died()

func _on_water_detector_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.name == "water":
		water_contact_count -= 1
		if water_contact_count <= 0:
			water_contact_count = 0  # Safety clamp
			$time_out_water.start()

# ------------------------------
# Breath bubbles + warning overlay
# ------------------------------
func update_bubbles():
	if water_timer.is_stopped():
		# In water = show all bubbles
		for bubble in bubble_ui.get_children():
			bubble.visible = true
	else:
		# Out of water = show bubbles depending on time left
		var time_left = water_timer.time_left
		var bubbles_to_show = int(ceil((time_left / max_time) * total_bubbles))

		for i in range(total_bubbles):
			bubble_ui.get_child(i).visible = i < bubbles_to_show

		# Show warning overlay if nearly out of bubbles
		if bubbles_to_show <= 2:
			fade_in_warning()
		else:
			fade_out_warning()

# Fade in red warning overlay
func fade_in_warning():
	if redness.visible and redness.modulate.a >= 1.0:
		return # already visible
	var tween = create_tween()
	redness.visible = true
	redness.modulate.a = 0.0
	tween.tween_property(redness, "modulate:a", 1.0, 0.5)

# Fade out red warning overlay
func fade_out_warning():
	if not redness.visible:
		return # already hidden
	var tween = create_tween()
	tween.tween_property(redness, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): redness.visible = false)
