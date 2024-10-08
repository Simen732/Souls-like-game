extends Node3D

signal attackFinished
signal attackConnected
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_animation_player_animation_finished(attack1):
	emit_signal("attackFinished")
	


func _on_area_3d_area_entered(area):
	emit_signal("attackConnected")
