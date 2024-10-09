extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var biguy = $RigidBody3D
@onready var biGaySword: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D

const aggro_range = 20
var aggro = false
var speed = 1
const attack124_range = 3  # Distance at which bro uses 1st 2nd and 4th attack
const attack3_range = 8
const attack5_range = 20
var walk_animation_playing = false

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
	# Connect the sword's area_entered signal to detect hits on the player
	biGaySword.connect("area_entered", Callable(self, "_on_sword_area_entered"))
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

# Move towards the player and handle animations
func move_towards_player(delta):
	var direction = (Global.player_position - $".".global_position)
	translate(speed * direction * delta / 10)
	var target_position = Global.player_position
	target_position.y = biguy.global_position.y  # Keep biguy's current y value
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
		speed = 0
		animation_player.play(random_animation)
		await animation_player.animation_finished
		speed = 1
		animation_player.play("walk")

# Handle when the sword hits an area
func _on_sword_area_entered(area: Area3D) -> void:
	# Check if the area entered belongs to the player
	if area.name == "Player":  # Assuming the player's collision area is named "Player"
		apply_damage_to_player(attack_damage)

# Apply damage to the player
func apply_damage_to_player(damage: int) -> void:
	Global.playerHealth -= damage  # Subtract the damage from the player's health
	print("Player hit! Health remaining: " + str(Global.playerHealth))

	# Optionally check if the player has died
	if Global.playerHealth <= 0:
		handle_player_death()

# Handle player death logic
func handle_player_death():
	print("Player is dead!")
	# Add logic to trigger death animation, respawn, or game over

# When the enemy takes damage
func _on_character_body_3d_bi_gay_damage():
	Global.biGayHealth -= Global.weaponDamage
	if Global.biGayHealth <= 0:
		aggro = false
		animation_player.stop()
		animation_player.play("dafeeted")
		await animation_player.animation_finished
		queue_free()
