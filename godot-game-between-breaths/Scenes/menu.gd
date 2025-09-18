extends Control

# ------------------------------
# Main menu script
# ------------------------------

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Automatically put keyboard/controller focus on the Start button
	$VBoxContainer/startbutton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Continuously play background music (ensures it loops or restarts if needed)
	audioManager.play_music(audioManager.music_tracks["bg"])


# ------------------------------
# Button callbacks
# ------------------------------

# Quit button: exits the game
func _on_quitbutton_pressed() -> void:
	get_tree().quit()

# Start button: loads the first level
func _on_startbutton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
