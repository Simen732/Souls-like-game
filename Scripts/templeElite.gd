extends Node3D

const TEMPLE_ARROW = preload("res://scenes/templeArrow.tscn")

@onready var top = $top
@onready var bottom = $bottom
@onready var animation_playerTop = $top/AnimationPlayer
@onready var animation_playerBottom = $bottom/AnimationPlayer
@onready var leftHand: Area3D = $top/Node/Root/body/ArmL/ElbowL/leftHand
@onready var rightHand: Area3D = $top/Node/Root/body/ArmR/ElbowR/rightHand
@onready var hitArea = $hitBox
@onready var hitbox = $hitBox/CollisionShape3D

@export var rotatable = true

var Health = 30
var aggro = false
var speed = 1.5
var strafe_speed_multiplier = 1.8  # Faster strafing when moving away
var attackstop_distance = 0
var attackCooldown = 0  # Cooldown for attacks

const aggro_range = 30
const melee_range = 3  # Distance for melee attacks
const ranged_range = 15  # Distance for ranged attacks

func _ready():
	Global.restart.connect(_on_restart)
	Global.playerDealDamage.connect(on_playerDealDamage)
	
	if not leftHand.is_connected("area_entered", Callable(self, "_on_leftHand_area_entered")):
		leftHand.connect("area_entered", Callable(self, "_on_leftHand_area_entered"))
	
	if not rightHand.is_connected("area_entered", Callable(self, "_on_rightHand_area_entered")):
		rightHand.connect("area_entered", Callable(self, "_on_rightHand_area_entered"))

func _process(delta):
	if !aggro and self.global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		animation_playerTop.play("aggro")
		animation_playerBottom.play("walk")
		await animation_playerTop.animation_finished
		animation_playerTop.play("aggroidle")

	if aggro:
		move_towards_player(delta)
		handle_attack(delta)
		if self.global_position.distance_to(Global.player_position) > aggro_range or Health <= 1:
			aggro = false
			Global.isFighting = false
			if animation_playerBottom.current_animation != "walk":
				animation_playerTop.play("deaggro")
				animation_playerBottom.play("idle")
				await animation_playerTop.animation_finished
				animation_playerTop.play("idle")
			else:
				animation_playerTop.stop
				animation_playerTop.play("deaggro")
				animation_playerBottom.stop
				animation_playerBottom.play("idle")
				await animation_playerTop.animation_finished
				animation_playerTop.play("idle")

func _on_restart():
	queue_free()

# Move towards the player and handle animations
func move_towards_player(delta):
	var topDirection = Vector3(Global.enemy_lock_on_position.x - self.global_position.x, 0, Global.enemy_lock_on_position.z - self.global_position.z)
	topDirection = topDirection.normalized()
	
	if rotatable:
		var topTarget_rotation_y = atan2(-topDirection.x, -topDirection.z)
		top.rotation.y = lerp_angle(top.rotation.y, topTarget_rotation_y, 0.75)
	
	# Calculate the direction towards or away from the player
	var bottomDirection = Vector3(topDirection)
	var is_moving_away = self.global_position.distance_to(Global.player_position) <= 15  # Moving away if too close

	if is_moving_away:
		bottomDirection = -topDirection  # Move away
		# Add strafing only when moving away
		var strafeDirection = Vector3(-bottomDirection.z, 0, bottomDirection.x)  # Perpendicular vector
		var strafe_weight = 0.7  # Adjust to control how much strafing influences the motion
		bottomDirection = (bottomDirection + strafeDirection * strafe_speed_multiplier * strafe_weight).normalized()
	else:
		bottomDirection = topDirection  # Move straight toward the player when too far

	if self.global_position.distance_to(Global.player_position) >= attackstop_distance and speed > 0:
		self.global_position += speed * bottomDirection * delta
	
	var bottomTarget_rotation_y = atan2(-bottomDirection.x, -bottomDirection.z)
	bottom.rotation.y = bottomTarget_rotation_y

# Handle attacking logic
func handle_attack(delta):
	if attackCooldown > 0:
		attackCooldown -= 1
	
	var attackAnim = ["attack1", "attack2", "attack3", "attack4"]
	
	# Close range attack
	if self.global_position.distance_to(Global.player_position) <= ranged_range and self.global_position.distance_to(Global.player_position) >= melee_range and animation_playerTop.current_animation not in attackAnim and attackCooldown == 0:
		animation_playerTop.play("attack1")
		
		# Instantiate the projectile
		var instance = TEMPLE_ARROW.instantiate()
		$top/Node/Root/body/ArmR/ElbowR/arrowSpawner.add_child(instance)
		
		# Calculate direction with a slight left offset
		var aim_direction = (Global.player_position - instance.global_position).normalized()
		var left_offset = Vector3(-aim_direction.z, 0, aim_direction.x).normalized() * 0.05  # Adjust offset value as needed
		aim_direction += left_offset
		aim_direction = aim_direction.normalized()
		
		# Apply the adjusted aim direction to the projectile's velocity
		if instance.has_method("set_velocity"):
			instance.set_velocity(aim_direction * instance.speed)
		
		await animation_playerTop.animation_finished
		attackCooldown = 60
	
	# Melee attack
	if self.global_position.distance_to(Global.player_position) <= melee_range and animation_playerTop.current_animation not in attackAnim and attackCooldown == 0:
		animation_playerTop.play("attack3")
		await animation_playerTop.animation_finished
		attackCooldown = 60

func _on_leftHand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !leftHand.disabled:
		Global.playerTakeDamage.emit(30)

func _on_rightHand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !rightHand.disabled:
		Global.playerTakeDamage.emit(30)

func on_playerDealDamage(area):
	if area == self.hitArea:
		if !hitbox.disabled:
			Health -= Global.weaponDamage
			if Health <= 0:
				hitbox.disabled = true
				aggro = false
				animation_playerTop.stop()
				animation_playerTop.play("death")
				animation_playerBottom.stop()
				animation_playerBottom.play("death")
				await animation_playerBottom.animation_finished
				Global.stopLockOn = true
				Global.locked_on = false
				queue_free()
