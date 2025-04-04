extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var head: Area3D = $Node/root/neck/neck2/neck3/neck4/head/headArea
@onready var boom: Area3D = $Node/root/neck/neck2/neck3/neck4/head/boomArea
@onready var top = $Node/root/neck
@onready var bossHealthbar = $"../CharacterBody3D/BossHealthbar"
@onready var backBossHealthbar = $"../CharacterBody3D/BackBossHealthbar"
@onready var hitbox = $hitbox/CollisionShape3D
@onready var hitArea = $hitBox

@export var rotatable = true
@export var rotationSpeed = 0.05
@export var attackmove = 0
@export var attackstop_distance = 7.5
@export var motionValue = 100
@export var interruptable = false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var ranged_attack_timer = randi_range(240, 360)
var Health = 600
var aggro = false
var speed = 0
var attacks = ["attack2", "attack3", "attack6"]
var spawnpoint = Vector3(0, 0, 0)

const aggro_range = 30
const melee_attack_range = 7.5  # Distance at which bro uses 1st 2nd and 4th attack


func _ready():
	animation_player.play("preaggro")
	spawnpoint = self.position
	Global.restart.connect(on_restart)
	Global.playerDealDamage.connect(on_playerDealDamage)
	
	
	if not head.is_connected("area_entered", Callable(self, "_on_head_area_entered")):
		head.connect("area_entered", Callable(self, "_on_head_area_entered"))
	
	if not boom.is_connected("area_entered", Callable(self, "_on_boom_area_entered")):
		boom.connect("area_entered", Callable(self, "_on_boom_area_entered"))


func _physics_process(delta):
	move_and_slide()
	if not is_on_floor():
		velocity.y -= gravity * delta
	if !aggro and self.global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		animation_player.play("aggro")
		Global.isFighting = true
		await animation_player.animation_finished
		music.playing = true
		backBossHealthbar.max_value = Health
		bossHealthbar.max_value = Health
		backBossHealthbar.value = backBossHealthbar.max_value
		bossHealthbar.value = backBossHealthbar.max_value
		$"../CharacterBody3D/BossHealthbar/RichTextLabel".clear
		$"../CharacterBody3D/BossHealthbar/RichTextLabel".add_text("Meenstra, the Giant Plant")
		backBossHealthbar.visible = true
		bossHealthbar.visible = true
		backBossHealthbar.value = Health
		speed = 2

	if aggro:
		bossHealthbar.value = Health
		if backBossHealthbar.value > Health:
			backBossHealthbar.value -= backBossHealthbar.max_value/500
			backBossHealthbar.value -= backBossHealthbar.max_value/bossHealthbar.max_value
		if backBossHealthbar.value < Health:
			backBossHealthbar.value += backBossHealthbar.max_value/500
		if typeof(Global.enemy_lock_on_position) == TYPE_VECTOR3:
			move_towards_player(delta)
		handle_attack(delta)
		if self.global_position.distance_to(Global.player_position) > aggro_range:
			aggro = false
			Health = bossHealthbar.max_value
			Global.isFighting = false
			music.playing = false
			backBossHealthbar.visible = false
			bossHealthbar.visible = false


func on_restart():
	aggro = false
	Health = bossHealthbar.max_value
	backBossHealthbar.value = Health
	bossHealthbar.value = Health
	Global.isFighting = false
	music.playing = false
	backBossHealthbar.visible = false
	bossHealthbar.visible = false
	animation_player.stop
	animation_player.play("preaggro")
	ranged_attack_timer = randi_range(240, 360)
	self.position = spawnpoint



func move_towards_player(delta):
	var direction = Vector3(Global.enemy_lock_on_position.x - self.global_position.x, 0, Global.enemy_lock_on_position.z - self.global_position.z)
	direction = direction.normalized()
	var target_rotation_y = atan2(-direction.x, -direction.z)
	if self.global_position.distance_to(Global.player_position) >= attackstop_distance and rotatable:
		self.global_position += (speed + attackmove) * direction * delta
	else:
		global_translate(transform.basis.z * -attackmove * delta)
	if rotatable:
		if speed <= 0:
			top.rotation.y = lerp_angle(self.rotation.y, target_rotation_y, rotationSpeed)
		else:
			self.rotation.y = lerp_angle(self.rotation.y, target_rotation_y, rotationSpeed)


# Handle attacking logic
func handle_attack(delta):
	var attackAnim = ["attack1", "attack2", "attack3", "attack4", "attack5", "attack6"] #Array med liste av alle attacks
	if self.global_position.distance_to(Global.player_position) > 10:
		ranged_attack_timer -= randi_range(3, 9)
	else:
		ranged_attack_timer -= randi_range(1, 3)

#Ranged attack
	if ranged_attack_timer <= 0 and animation_player.current_animation not in attackAnim:
		ranged_attack_timer = 9999
		speed = 0
		var random_ranged_attack = randi_range(1, 10)
		
		if random_ranged_attack == 5 and animation_player.current_animation not in attackAnim:
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4end")
		elif random_ranged_attack == 4 and animation_player.current_animation not in attackAnim:
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4end")
		elif random_ranged_attack == 3 and animation_player.current_animation not in attackAnim:
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4end")
		elif random_ranged_attack <= 2 and animation_player.current_animation not in attackAnim:
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4")
			await animation_player.animation_finished
			animation_player.play("attack4end")
		
		elif random_ranged_attack > 5 and animation_player.current_animation not in attackAnim:
			if  self.global_position.distance_to(Global.player_position) < 5:
				animation_player.play("attack6")
			else:
				var random_breath_attack = randi_range(1, 3)
				if random_breath_attack > 1:
					animation_player.play("attack5")
				else:
					animation_player.play("attack6")
		await animation_player.animation_finished
		speed = 2
		animation_player.play("walk")
		ranged_attack_timer = randi_range(750, 1500)

#Close range attacks
	if self.global_position.distance_to(Global.player_position) <= melee_attack_range and animation_player.current_animation not in attackAnim:
		var random_animation = attacks[randi() % attacks.size()]
		speed = 0
		animation_player.play(random_animation)
		attacks = ["attack1", "attack2", "attack3"]
		attacks.erase(random_animation)
		print(attacks)
		await animation_player.animation_finished
		speed = 2
		animation_player.play("walk")


#Hitboxes
func _on_head_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !head.disabled:
		Global.playerTakeDamage.emit(60*motionValue/100)

func _on_boom_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !boom.disabled:
		Global.playerTakeDamage.emit(45*motionValue/100)


func on_playerDealDamage(area):
	if area == self.hitArea and !hitbox.disabled:
		Health -= Global.weaponDamage
		print("Plant hit! Health remaining: " + str(Health))
		if Health <= 0:
			backBossHealthbar.visible = false
			bossHealthbar.visible = false
			hitbox.disabled = true
			aggro = false
			Global.isFighting = false
			Global.locked_on = false
			animation_player.stop()
			animation_player.play("death")
			await animation_player.animation_finished
			queue_free()
