extends Node3D
class_name templeGoon

@onready var animation_player = $AnimationPlayer
@onready var right_hand = $Node/Root/ArmR/ElbowR/sphere7/RightHand
@onready var rightHandCollisionShape = $Node/Root/Body/CollisionShape3D
@onready var left_hand = $Node/Root/ArmL/ElbowL/sphere4/leftHand
@onready var leftHandCollisionShape = $Node/Root/ArmL/ElbowL/sphere4/leftHand/CollisionShape3D
@onready var hit_box = $templeGoonBody/hitBox
@onready var goonArea = $templeGoonBody

@export var attackmove = 0
@export var rotatable = true

var isDead = false
var Health = 25
const aggro_range = 30
var aggro = false
var speed = 2
var attackstop_distance = 0

func _ready():
	Global.restart.connect(on_restart)
	print(goonArea)
	
	if not goonArea.is_connected("area_entered", Callable(self, "_on_character_body_3d_player_damage")): #Idk chattern ba meg legge det til
		goonArea.connect("area_entered", Callable(self, "_on_character_body_3d_player_damage"))
	
	if not right_hand.is_connected("area_entered", Callable(self, "_on_hand_area_entered")):
		right_hand.connect("area_entered", Callable(self, "_on_hand_area_entered"))
		
	if not left_hand.is_connected("area_entered", Callable(self, "_on_hand_area_entered")):
		left_hand.connect("area_entered", Callable(self, "_on_hand_area_entered"))


func _process(delta):
	if !aggro and $".".global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		animation_player.play("walk")

	if aggro and !isDead:
		move_towards_player(delta)
		handle_attack(delta)
		if $".".global_position.distance_to(Global.player_position) > aggro_range or Health <= 1:
			aggro = false
			Global.isFighting = false
			if animation_player.current_animation != "walk":
				await animation_player.animation_finished
				animation_player.play("idle")
	else:
		if !isDead:
			animation_player.stop
			animation_player.play("idle")


func on_restart():
	queue_free()


# Move towards the player and handle animations
func move_towards_player(delta):
	var direction = Vector3(Global.enemy_lock_on_position.x - $".".global_position.x, 0, Global.enemy_lock_on_position.z - $".".global_position.z)
	direction = direction.normalized()
	if $".".global_position.distance_to(Global.player_position) >= attackstop_distance:
		$".".global_position += (speed + attackmove) * direction * delta
	if rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		$".".rotation.y = lerp_angle($".".rotation.y, target_rotation_y, 0.5)


# Handle attacking logic
func handle_attack(delta):

#Close range attack
	if $".".global_position.distance_to(Global.player_position) <= 1:
		if animation_player.current_animation != "attack1":
			if animation_player.current_animation != "attack2":
				speed = 0
				animation_player.play("attack1")
				await animation_player.animation_finished
				speed = 2
				animation_player.play("walk")

	if $".".global_position.distance_to(Global.player_position) == 3.5:
		if animation_player.current_animation != "attack1":
			if animation_player.current_animation != "attack2":
				rotatable = false
				speed = 0
				animation_player.play("attack2")
				await animation_player.animation_finished
				speed = 2
				rotatable = true
				animation_player.play("walk")


func _on_character_body_3d_player_damage(area):
	print(self.goonArea)
	if area == self.goonArea: #Sjekker om areaet som sverdet treffer er samme som goonen sin
		Health -= Global.weaponDamage
		print(Health)
		if Health <= 0:
			isDead = true
			aggro = false
			animation_player.stop()
			animation_player.play("death")
			await animation_player.animation_finished
			queue_free()


func _on_left_hand_area_entered(area):
	if area.name == "Player" or area.get_parent().name == "Player" and !leftHandCollisionShape.disabled:
		Global.playerTakeDamage.emit(20)


func _on_right_hand_area_entered(area):
	if area.name == "Player" or area.get_parent().name == "Player" and !rightHandCollisionShape.disabled:
		Global.playerTakeDamage.emit(20)
