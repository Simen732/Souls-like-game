extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D

var aggro = false



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
		
	


func _on_character_body_3d_bi_gay_damage():
	Global.biGayHealth -= Global.weaponDamage
	if Global.biGayHealth <= 0:
		animation_player.play("dafeeted")
		await animation_player.animation_finished
		queue_free()


func _on_agro_area_entered(area):
	aggro = true
	Global.isFightingBoss = true
	music.playing = true
	print("Du gikk inn")






