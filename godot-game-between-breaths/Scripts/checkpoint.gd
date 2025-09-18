extends Area2D

#code for changing respawn position
func _on_body_entered(_body: Node2D) -> void:

	Global.checkpoint = position

	
	
