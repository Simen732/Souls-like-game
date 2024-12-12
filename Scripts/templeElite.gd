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
@onready var area_3d_2 = $top/Area3D2

var Health = 75
var aggro = false
var speed = 1.5
var attackstop_distance = 0
var attackCooldown = 0 
const aggro_range = 30
const melee_range = 3  
const ranged_range = 15 

func _ready():
	Global.restart.connect(_on_restart)
	Global.playerDealDamage.connect(on_playerDealDamage)
	
	if not leftHand.is_connected("area_entered", Callable(self, "_on_leftHand_area_entered")):
		leftHand.connect("area_entered", Callable(self, "_on_leftHand_area_entered"))
	
	if not rightHand.is_connected("area_entered", Callable(self, "_on_rightHand_area_entered")):
		rightHand.connect("area_entered", Callable(self, "_on_rightHand_area_entered"))
	
	if not area_3d_2.is_connected("area_entered", Callable(self, "_on_area_3d_2_area_entered")):
		area_3d_2.connect("area_entered", Callable(self, "_on_area_3d_2_area_entered"))

func _process(delta):
	if !aggro and self.global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		animation_playerTop.play("aggro")
		animation_playerBottom.play("walk")
		animation_playerTop.play("aggroidle")

	if aggro:
		if animation_playerTop.current_animation == "attack2":
				animation_playerBottom.play("idle")
		move_towards_player(delta)
		handle_attack(delta)
		if self.global_position.distance_to(Global.player_position) > aggro_range or Health <= 1:
			aggro = false
			Global.isFighting = false
			if animation_playerBottom.current_animation != "walk":
				animation_playerTop.play("deaggro")
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

func move_towards_player(delta):
	var topDirection = Vector3(Global.enemy_lock_on_position.x - self.global_position.x, 0, Global.enemy_lock_on_position.z - self.global_position.z)
	topDirection = topDirection.normalized()
	if rotatable:
		var topTarget_rotation_y = atan2(-topDirection.x, -topDirection.z)
		top.rotation.y = lerp_angle(top.rotation.y, topTarget_rotation_y, 0.75)
	
	var bottomDirection = Vector3(topDirection)
	if self.global_position.distance_to(Global.player_position) > 15:
		bottomDirection = Vector3(topDirection)
	else:
		bottomDirection = Vector3(-topDirection)
	bottomDirection = bottomDirection.normalized()
	if animation_playerTop.current_animation == "attack4":
		bottomDirection = Vector3(topDirection)
	if self.global_position.distance_to(Global.player_position) >= attackstop_distance and speed > 0:
		self.global_position += (speed) * bottomDirection * delta
	var bottomTarget_rotation_y = atan2(-bottomDirection.x, -bottomDirection.z)
	bottom.rotation.y = bottomTarget_rotation_y
func handle_attack(delta):
	if attackCooldown > 0:
		attackCooldown -= 1
	
	var attackAnim = ["attack1", "attack2", "attack3", "attack4"]
	

	if self.global_position.distance_to(Global.player_position) <= ranged_range and self.global_position.distance_to(Global.player_position) >= melee_range and animation_playerTop.current_animation not in attackAnim and attackCooldown == 0:
		animation_playerTop.play("attack1")
		var instance = TEMPLE_ARROW.instantiate()
		$top/Node/Root/body/ArmR/ElbowR/arrowSpawner.add_child(instance)
		await animation_playerTop.animation_finished
		attackCooldown = 60
	if self.global_position.distance_to(Global.player_position) <= melee_range and animation_playerTop.current_animation not in attackAnim and attackCooldown == 0:
		var animations = ["attack2", "attack4"]
		var random_animation = animations[randi() % animations.size()]
		if random_animation == "attack2":
			speed = 0
		animation_playerTop.play(random_animation)
		await animation_playerTop.animation_finished
		speed = 1.5
		attackCooldown = 60
		
func _on_leftHand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !leftHand.disabled:
		Global.playerTakeDamage.emit(30)
		
func _on_rightHand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !rightHand.disabled:
		Global.playerTakeDamage.emit(30)
		
func _on_area_3d_2_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !area_3d_2.disabled:
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
