extends Node3D


func _process(delta):
	Global.enemy_lock_on_position = $".".global_position
	var direction = (Global.player_position - $".".global_position)
	if $".".global_position.distance_to(Global.player_position) > 5:
		translate(Global.SPEED * direction * delta)
	else:
		translate(Global.SPEED * direction * delta * 0.75)
