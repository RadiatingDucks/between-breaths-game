extends Area2D

var found_checkpoint = true

func _on_body_entered(_body: Node2D) -> void:
	if found_checkpoint:
		Global.checkpoint = position
		found_checkpoint = false;
	
	
