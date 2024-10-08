extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var biGay = $Node/Root/RigidBody3D
@onready var biGaySword: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D
@onready var biGayFoot: Area3D = $Node/Root/LegL/KneeL/FootL/Area3D2
@onready var health: ProgressBar = $"../CharacterBody3D/Health"
@onready var BiGaySwordCollision = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D/CollisionShape3D
@onready var boss_healthbar = $"../CharacterBody3D/Boss Healthbar"


signal playerShank


const aggro_range = 20
var aggro = false
var speed = 0.75
const attack124_range = 3  # Distance at which bro uses 1st 2nd and 4th attack
const attack3_range = 8
const attack5_range = 20
var walk_animation_playing = false
var attack_cooldown

# Attack animation names
const attack_animations = ["attack1", "attack2", "attack4"]

# Attack probabilities 
var attack_probabilities = [0.75, 0.75, 0.75]  # Initial weights
var total_probability = 2.25  # Initial total probability
var last_attack_index = -0.5  # Index of the last attack used

# Damage values for each attack (you can adjust these as needed)
var attack_damage = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	
	boss_healthbar.max_value = Global.biGayHealth
	boss_healthbar.value = boss_healthbar.max_value
	
	$GPUParticles3D.position.y = $GPUParticles3D.position.y + 1000
	if not biGaySword.is_connected("area_entered", Callable(self, "_on_sword_area_entered")):
		biGaySword.connect("area_entered", Callable(self, "_on_sword_area_entered"))

	if not biGayFoot.is_connected("area_entered", Callable(self, "_on_foot_area_entered")):
		biGayFoot.connect("area_entered", Callable(self, "_on_foot_area_entered"))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Global.biGayHealth > 0:
		if !aggro:
			if $".".global_position.distance_to(Global.player_position) <= aggro_range:
				aggro = true
				Global.isFightingBoss = true
				music.playing = true
				print("Du gikk inn")

	if aggro:
		move_towards_player(delta)
		handle_attack(delta)
		boss_healthbar.visible = true

# Move towards the player and handle animations
func move_towards_player(delta):
	var direction = (Global.player_position - $".".global_position)
	translate(speed * direction * delta / 10)
	var target_position = Global.player_position
	target_position.y = $".".global_position.y  # Keep biguy's current y value
	look_at(target_position)

	if direction.length() > 0.1:
		if !walk_animation_playing:
			animation_player.play("walk")
			walk_animation_playing = true
	else:
		if walk_animation_playing:
			animation_player.stop()
			walk_animation_playing = false

# Handle attacking logic
func handle_attack(delta):
	if $".".global_position.distance_to(Global.player_position) <= attack124_range:
		var animations = ["attack1", "attack2", "attack4"]
		var random_animation = animations[randi() % animations.size()]
		if animation_player.current_animation != "attack1":
			if animation_player.current_animation != "attack2":
					if animation_player.current_animation != "attack4":
						speed = 0
						animation_player.play(random_animation)
						await animation_player.animation_finished
						speed = 0.75
						animation_player.play("walk")


# Handle when the sword hits an area
# Handle when the sword hits something
func _on_sword_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !BiGaySwordCollision.disabled:
		print("Player detected! Dealing damage.")
		Global.enemyDamage = 40
		apply_damage_to_player()

func _on_foot_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player":
		print("Player detected! Dealing damage.")
		Global.enemyDamage = 20
		apply_damage_to_player()


# Apply damage to the player
func apply_damage_to_player() -> void:
	#health.value -=   # Subtract the damage from the player's health
	emit_signal("playerShank")
	print("Player hit! Health remaining: " + str(health.value))

# When the enemy takes damage
func _on_character_body_3d_bi_gay_damage():
	if $Node/Root/BiGay/BiguyHitbox.disabled == false:
		Global.biGayHealth -= Global.weaponDamage
		boss_healthbar.value -= Global.weaponDamage
		if Global.biGayHealth <= 0:
			$Node/Root/BiGay/BiguyHitbox.disabled = true
			$GPUParticles3D.position.y = $GPUParticles3D.position.y - 1000
			aggro = false
			animation_player.stop()
			animation_player.play("dafeeted")
			await animation_player.animation_finished
			queue_free()
