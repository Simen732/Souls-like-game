extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var biGay = $Node/Root/RigidBody3D
@onready var biGaySword: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D
@onready var biGayFoot: Area3D = $Node/Root/LegL/KneeL/FootL/Area3D2
@onready var biGayHand = $Node/Root/Body/ArmL/ElbowL/HandL/Area3D2
@onready var health: ProgressBar = $"../CharacterBody3D/Health"
@onready var BiGaySwordCollision = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D/CollisionShape3D
@onready var BiGayFootCollision = $Node/Root/LegL/KneeL/FootL/Area3D2/CollisionShape3D
@onready var BiGayHandCollision = $Node/Root/Body/ArmL/ElbowL/HandL/Area3D2/CollisionShape3D
@onready var boss_healthbar = $"../CharacterBody3D/Boss Healthbar"

signal playerShank


const aggro_range = 20
var aggro = false
@export var speed = 0.75
const attack124_range = 3  # Distance at which bro uses 1st 2nd and 4th attack
const attack3_range = 8
const attack5_minrange = 8
var walk_animation_playing = false
var attack_cooldown


# Attack probabilities
var attack_probabilities = [0.75, 0.75, 0.75]  # Initial weights
var total_probability = 2.25  # Initial total probability
var last_attack_index = -0.5  # Index of the last attack used


func _ready():
	$Node/Root/LegL/KneeL/FootL/Area3D2/GPUParticles3D2.emitting = false
	boss_healthbar.max_value = Global.biGayHealth
	boss_healthbar.value = boss_healthbar.max_value
	
	if not biGaySword.is_connected("area_entered", Callable(self, "_on_sword_area_entered")):
		biGaySword.connect("area_entered", Callable(self, "_on_sword_area_entered"))

	if not biGayFoot.is_connected("area_entered", Callable(self, "_on_foot_area_entered")):
		biGayFoot.connect("area_entered", Callable(self, "_on_foot_area_entered"))

	if not biGayHand.is_connected("area_entered", Callable(self, "_on_hand_area_entered")):
		biGayHand.connect("area_entered", Callable(self, "_on_hand_area_entered"))


func _process(delta):
	if !aggro and $".".global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Global.biGayHealth > 0:
		aggro = true
		Global.isFightingBoss = true
		music.playing = true
		boss_healthbar.visible = true
		

	if aggro:
		move_towards_player(delta)
		handle_attack(delta)
		if $".".global_position.distance_to(Global.player_position) > aggro_range or Global.playerIsDying or Global.biGayHealth <= 1:
			aggro = false
			Global.biGayHealth = 200
			boss_healthbar.value = Global.biGayHealth
			Global.isFightingBoss = false
			music.playing = false
			boss_healthbar.visible = false


# Move towards the player and handle animations
func move_towards_player(delta):
	var direction = (Global.enemy_lock_on_position - $".".global_position)
	direction.y = 0
	translate(speed * direction * delta / 10)
	if BiGaySwordCollision and BiGayFootCollision and BiGayHandCollision:
		if BiGaySwordCollision.disabled and BiGayFootCollision.disabled and BiGayHandCollision.disabled:
			look_at(Global.enemy_lock_on_position)

	if direction.length() > 0.1:
		if !walk_animation_playing:
			animation_player.play("walk")
			walk_animation_playing = true
	else:
		if walk_animation_playing:
			animation_player.play("idle")
			walk_animation_playing = false


# Handle attacking logic
func handle_attack(delta):
	if $".".global_position.distance_to(Global.player_position) <= attack124_range:
		var animations = ["attack1", "attack2", "attack3", "attack4"]
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


# Handle when the sword hits an area
func _on_sword_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !BiGaySwordCollision.disabled:
		Global.enemyDamage = 40
		apply_damage_to_player()

func _on_foot_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !BiGayFootCollision.disabled:
		Global.enemyDamage = 30
		apply_damage_to_player()

func _on_hand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !BiGayHandCollision.disabled:
		Global.enemyDamage = 20
		apply_damage_to_player()


# Apply damage to the player
func apply_damage_to_player() -> void:
	#health.value -=   # Subtract the damage from the player's health
	if !Global.playerIsDying:
		emit_signal("playerShank")
		print("Player hit! Health remaining: " + str(health.value))


# When the enemy takes damage
func _on_character_body_3d_bi_gay_damage():
	if $Node/Root/BiGay/BiguyHitbox.disabled == false:
		Global.biGayHealth -= Global.weaponDamage
		boss_healthbar.value = Global.biGayHealth
		if Global.biGayHealth <= 0:
			$Node/Root/BiGay/BiguyHitbox.disabled = true
			aggro = false
			animation_player.stop()
			animation_player.play("dafeeted")
			await animation_player.animation_finished
			boss_healthbar.visible = false
			queue_free()
