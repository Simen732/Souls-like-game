extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var biGaySword: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D
@onready var biGayHilt: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Area3D2
@onready var biGayFoot: Area3D = $Node/Root/LegL/KneeL/FootL/Area3D2
@onready var biGayHand: Area3D = $Node/Root/Body/ArmL/ElbowL/HandL/Area3D2
@onready var boss_healthbar = $"../CharacterBody3D/BossHealthbar"


@export var rotatable = true
@export var attackmove = 0


signal playerShank

var ranged_attack_timer = randi_range(60, 180)
var Health = 300
var aggro = false
var speed = 0.75
var attackstop_distance = 0



const aggro_range = 30
const attack124_range = 3  # Distance at which bro uses 1st 2nd and 4th attack
const attack3_range = 6
const attack5_minrange = 8


func _ready():
	Global.restart.connect(on_restart)
	$Node/Root/LegL/KneeL/FootL/Area3D2/GPUParticles3D2.emitting = false
	boss_healthbar.max_value = Health
	boss_healthbar.value = boss_healthbar.max_value
	
	if not biGaySword.is_connected("area_entered", Callable(self, "_on_sword_area_entered")):
		biGaySword.connect("area_entered", Callable(self, "_on_sword_area_entered"))

	if not biGayFoot.is_connected("area_entered", Callable(self, "_on_foot_area_entered")):
		biGayFoot.connect("area_entered", Callable(self, "_on_foot_area_entered"))

	if not biGayHand.is_connected("area_entered", Callable(self, "_on_hand_area_entered")):
		biGayHand.connect("area_entered", Callable(self, "_on_hand_area_entered"))

	if not biGayHilt.is_connected("area_entered", Callable(self, "_on_hilt_area_entered")):
		biGayHilt.connect("area_entered", Callable(self, "_on_hilt_area_entered"))


func _process(delta):
	

	
	if !aggro and $".".global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		music.playing = true
		boss_healthbar.visible = true
		animation_player.play("walk")

	if aggro:
		move_towards_player(delta)
		handle_attack(delta)
		if $".".global_position.distance_to(Global.player_position) > aggro_range or Health <= 1:
			aggro = false
			Health = boss_healthbar.max_value
			boss_healthbar.value = Health
			Global.isFighting = false
			music.playing = false
			boss_healthbar.visible = false
			if animation_player.current_animation != "walk":
				await animation_player.animation_finished
				animation_player.play("idle")
			else:
				animation_player.stop
				animation_player.play("idle")

func on_restart():
	aggro = false
	Health = boss_healthbar.max_value
	boss_healthbar.value = Health
	Global.isFighting = false
	music.playing = false
	boss_healthbar.visible = false
	animation_player.stop()	
	animation_player.play("idle")
	$".".position = Vector3(0, -29.726, 105)
	$".".rotation = Vector3(0, 0, 0)


# Move towards the player and handle animations
func move_towards_player(delta):
	var direction = Vector3(Global.enemy_lock_on_position.x - $".".global_position.x, 0, Global.enemy_lock_on_position.z - $".".global_position.z)
	direction = direction.normalized()
	if $".".global_position.distance_to(Global.player_position) >= attackstop_distance:
		$".".global_position += (speed + attackmove) * direction * delta
	if rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		$".".rotation.y = lerp_angle($".".rotation.y, target_rotation_y, 0.05)


# Handle attacking logic
func handle_attack(delta):
	if $".".global_position.distance_to(Global.player_position) >= attack3_range:
		ranged_attack_timer -= 1


#Close range attacks
	if $".".global_position.distance_to(Global.player_position) <= attack124_range:
		var animations = ["attack1", "attack2", "attack4"]
		var random_animation = animations[randi() % animations.size()]
		if animation_player.current_animation != "attack1":
			if animation_player.current_animation != "attack2":
				if animation_player.current_animation != "attack3":
					if animation_player.current_animation != "attack4":
						if animation_player.current_animation != "attack5":
							speed = 0
							animation_player.play(random_animation)
							await animation_player.animation_finished
							speed = 0.75
							animation_player.play("walk")

#Attack3
	elif $".".global_position.distance_to(Global.player_position) <= attack3_range:
		if animation_player.current_animation != "attack1":
			if animation_player.current_animation != "attack2":
				if animation_player.current_animation != "attack3":
					if animation_player.current_animation != "attack4":
						if animation_player.current_animation != "attack5":
							attackstop_distance = 2
							speed = 0
							animation_player.play("attack3")
							await animation_player.animation_finished
							speed = 0.75
							attackstop_distance = 0
							ranged_attack_timer = randi_range(60, 180)
							animation_player.play("walk")

#ULTIMATE PERFECT ATTACK
	elif $".".global_position.distance_to(Global.player_position) >= attack5_minrange:
		if animation_player.current_animation != "attack1":
			if animation_player.current_animation != "attack2":
				if animation_player.current_animation != "attack3":
					if animation_player.current_animation != "attack4":
						if animation_player.current_animation != "attack5":
							if ranged_attack_timer <= 0:
								attackstop_distance = 5
								speed = 0
								animation_player.play("attack5")
								await animation_player.animation_finished
								speed = 0.75
								attackstop_distance = 6
								ranged_attack_timer = randi_range(60, 180)
								animation_player.play("walk")


# Handle when the sword hits an area
func _on_sword_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGaySword.disabled:
		Global.enemyDamage = 40
		emit_signal("playerShank")

func _on_foot_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGayFoot.disabled:
		Global.enemyDamage = 60
		emit_signal("playerShank")

func _on_hand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGayHand.disabled:
		Global.enemyDamage = 20
		emit_signal("playerShank")
		

func _on_hilt_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGayHilt.disabled:
		Global.enemyDamage = 30
		emit_signal("playerShank")



func _on_character_body_3d_player_damage(area):
		if area.name == "BiGay" or area.get_parent().name == "BiGay":
			if !$Node/BiGay/BiguyHitbox.disabled:
				Health -= Global.weaponDamage
				boss_healthbar.value = Health
				print("Bigay hit! Health remaining: " + str(boss_healthbar.value))
				if Health <= 0:
					$Node/BiGay/BiguyHitbox.disabled = true
					aggro = false
					animation_player.stop()
					animation_player.play("dafeeted")
					await animation_player.animation_finished
					boss_healthbar.visible = false
					Global.stopLockOn = true
					Global.locked_on = false
					queue_free()
