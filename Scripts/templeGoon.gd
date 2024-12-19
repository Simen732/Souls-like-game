extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var leftHand: Area3D = $Node/Root/ArmL/ElbowL/sphere4/leftHand
@onready var rightHand: Area3D = $Node/Root/ArmR/ElbowR/sphere7/rightHand
@onready var ball: Area3D = $Node/Root/sphere/ball

@onready var hitArea = $Node/Root/templeGoon
@onready var hitbox = $Node/Root/templeGoon/hitBox

@export var rotatable = true
@export var attackmove = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var Health = 30
var aggro = false
var speed = 2
var attackstop_distance = 0


const aggro_range = 30
const attack_range = 1  # Distance at which bro uses melee attacks


func _ready():
	Global.restart.connect(_on_restart)
	Global.playerDealDamage.connect(on_playerDealDamage)
	
	if not leftHand.is_connected("area_entered", Callable(self, "_on_leftHand_area_entered")):
		leftHand.connect("area_entered", Callable(self, "_on_leftHand_area_entered"))
	
	if not rightHand.is_connected("area_entered", Callable(self, "_on_rightHand_area_entered")):
		rightHand.connect("area_entered", Callable(self, "_on_rightHand_area_entered"))
	
	if not ball.is_connected("area_entered", Callable(self, "_on_ball_area_entered")):
		ball.connect("area_entered", Callable(self, "_on_ball_area_entered"))
	
	animation_player.play("idle")


func _physics_process(delta):
	move_and_slide()
	if not is_on_floor():
		velocity.y -= gravity * delta
	if !aggro and self.global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		animation_player.play("walk")

	if aggro:
		if typeof(Global.enemy_lock_on_position) == TYPE_VECTOR3:
			move_towards_player(delta)
		handle_attack(delta)
		if self.global_position.distance_to(Global.player_position) > aggro_range or Health <= 1:
			aggro = false
			Global.isFighting = false
			if animation_player.current_animation != "walk":
				await animation_player.animation_finished
				animation_player.play("idle")
			else:
				animation_player.stop
				animation_player.play("idle")
				

func _on_restart():
	queue_free()

# Move towards the player and handle animations
func move_towards_player(delta):
	var direction = Vector3(Global.enemy_lock_on_position.x - self.global_position.x, 0, Global.enemy_lock_on_position.z - self.global_position.z)
	direction = direction.normalized()
	if self.global_position.distance_to(Global.player_position) >= attackstop_distance:
		self.global_position += (speed + attackmove) * direction * delta
	if rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		self.rotation.y = lerp_angle(self.rotation.y, target_rotation_y, 0.05)


func handle_attack(delta):
	var attackAnim = ["attack1", "attack2"]
	
	#Close range attack
	if self.global_position.distance_to(Global.player_position) <= attack_range and animation_player.current_animation not in attackAnim:
		speed = 0
		animation_player.play("attack1")
		await animation_player.animation_finished
		speed = 2
		animation_player.play("walk")
	
	if self.global_position.distance_to(Global.player_position) >= 2 and self.global_position.distance_to(Global.player_position) <= 4 and animation_player.current_animation not in attackAnim:
		speed = 0
		animation_player.play("attack2")
		await animation_player.animation_finished
		speed = 2
		animation_player.play("walk")


# Handle when the sword hits an area
func _on_leftHand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !leftHand.disabled:
		print("LeftHand")
		Global.playerTakeDamage.emit(20)


func _on_rightHand_area_entered(area: Area3D) -> void:
	print("RightHand")		
	if area.name == "Player" or area.get_parent().name == "Player" and !rightHand.disabled:
		Global.playerTakeDamage.emit(20)


func _on_ball_area_entered(area: Area3D) -> void:
	print("Ball")		
	if area.name == "Player" or area.get_parent().name == "Player" and !ball.disabled:
		Global.playerTakeDamage.emit(20)


func on_playerDealDamage(area):
	if area == self.hitArea:
		if !hitbox.disabled:
			Health -= Global.weaponDamage
			if Health <= 0:
				hitbox.disabled = true
				aggro = false
				Global.isFighting = false
				animation_player.stop()
				animation_player.play("death")
				await animation_player.animation_finished
				Global.stopLockOn = true
				Global.locked_on = false
				queue_free()
