extends CharacterBody3D
const Rock = preload("res://scenes/gorillaRock.tscn")

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var handL: Area3D = $Node/root/body/chest/armLeft/elbowLeft/Area3D2
@onready var handR: Area3D = $Node/root/body/chest/armRight/elbowRight/Area3D2
@onready var body: Area3D = $Node/root/body/Area3D3
@onready var handLboom = $Node/root/body/chest/armRight/elbowRight/handRight/Area3D3
@onready var handRboom = $Node/root/body/chest/armLeft/elbowLeft/handLeft/Area3D3
@onready var bigBoom = $Node/Area3D3
@onready var bossHealthbar = $"../CharacterBody3D/BossHealthbar"
@onready var backBossHealthbar = $"../CharacterBody3D/BackBossHealthbar"
@onready var hitbox = $Node/root/body/hitBox/GorillaHitbox
@onready var hitArea = $Node/root/body/hitBox

@export var rotatable = true
@export var rotationSpeed = 0.1
@export var attackmove = 0
@export var attackstop_distance = 2.5
@export var interruptable = false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jump_attack_timer = randi_range(480, 720)
var Health = 150
var aggro = false
var speed = 3
var attacks = ["attack2", "attack3", "attack6"]
var spawnpoint = Vector3(0, 0, 0)

const aggro_range = 45
const attack23_range = 3  # Distance at which bro uses 1st 2nd and 4th attack
const attack1_range = 1.5


func _ready():
	animation_player.play("idle")
	spawnpoint = self.position
	Global.restart.connect(on_restart)
	Global.playerDealDamage.connect(on_playerDealDamage)
	
	if not handL.is_connected("area_entered", Callable(self, "_on_handL_area_entered")):
		handL.connect("area_entered", Callable(self, "_on_handL_area_entered"))
		
	if not handR.is_connected("area_entered", Callable(self, "_on_handR_area_entered")):
		handR.connect("area_entered", Callable(self, "_on_handR_area_entered"))
	
	if not handLboom.is_connected("area_entered", Callable(self, "_on_handLboom_area_entered")):
		handLboom.connect("area_entered", Callable(self, "_on_handLboom_area_entered"))
	
	if not handRboom.is_connected("area_entered", Callable(self, "_on_handRboom_area_entered")):
		handRboom.connect("area_entered", Callable(self, "_on_handRboom_area_entered"))
	
	if not body.is_connected("area_entered", Callable(self, "_on_body_area_entered")):
		body.connect("area_entered", Callable(self, "_on_body_area_entered"))
	
	if not bigBoom.is_connected("area_entered", Callable(self, "_on_bigBoom_area_entered")):
		bigBoom.connect("area_entered", Callable(self, "_on_bigBoom_area_entered"))


func _physics_process(delta):
	move_and_slide()
	if not is_on_floor():
		velocity.y -= gravity * delta
	if !aggro and self.global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		music.playing = true
		backBossHealthbar.max_value = Health
		bossHealthbar.max_value = Health
		backBossHealthbar.value = backBossHealthbar.max_value
		bossHealthbar.value = backBossHealthbar.max_value
		$"../CharacterBody3D/BossHealthbar/RichTextLabel".clear
		$"../CharacterBody3D/BossHealthbar/RichTextLabel".add_text("Robert, the Rampaging Gorilla")
		backBossHealthbar.visible = true
		bossHealthbar.visible = true
		backBossHealthbar.value = Health
		animation_player.play("walk")

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
			animation_player.stop
			animation_player.play("idle")


func on_restart():
	aggro = false
	Health = bossHealthbar.max_value
	backBossHealthbar.value = Health
	bossHealthbar.value = Health
	Global.isFighting = false
	music.playing = false
	backBossHealthbar.visible = false
	bossHealthbar.visible = false
	animation_player.stop()	
	animation_player.play("idle")
	jump_attack_timer = randi_range(480, 720)
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
		self.rotation.y = lerp_angle(self.rotation.y, target_rotation_y, rotationSpeed)


# Handle attacking logic
func handle_attack(delta):
	var attackAnim = ["attack1", "attack2", "attack3", "attack4", "attack5", "attack6", "attack7", "attack7interrupted"] #Array med liste av alle attacks
	$Node/root/body/chest/armRight/elbowRight/handRight/rockSpawner.look_at(-Global.player_position)
	if self.global_position.distance_to(Global.player_position) > 7.5:
		jump_attack_timer -= randi_range(3, 9)
	else:
		jump_attack_timer -= randi_range(1, 3)

#Jump attack
	if jump_attack_timer <= 0 and animation_player.current_animation not in attackAnim:
		jump_attack_timer = 9999
		speed = 0
		animation_player.play("attack4")
		attackstop_distance = 0
		await animation_player.animation_finished
		
		#kanskje han gjør follow up
		if self.global_position.distance_to(Global.player_position) > 10:
			var random_ranged_attack = randi_range(1, 8)
			if random_ranged_attack <= 5 and animation_player.current_animation not in attackAnim:
				animation_player.play("attack5")
				var instance = Rock.instantiate()
				$Node/root/body/chest/armRight/elbowRight/handRight/rockSpawner.add_child(instance)
				await animation_player.animation_finished
			else:
				animation_player.play("attack7")
				await animation_player.animation_finished
		
		speed = 3
		attackstop_distance = 2.5
		jump_attack_timer = randi_range(720, 1200)
		animation_player.play("walk")

#Close range attack
	if self.global_position.distance_to(Global.player_position) <= attack1_range and animation_player.current_animation not in attackAnim and randi_range(1, 3) > 1:
		speed = 0
		animation_player.play("attack1")
		await animation_player.animation_finished
		speed = 3
		animation_player.play("walk")

#Mid range attacks
	if self.global_position.distance_to(Global.player_position) <= attack23_range and animation_player.current_animation not in attackAnim:
		var random_animation = attacks[randi() % attacks.size()]
		speed = 0
		animation_player.play(random_animation)
		attacks = ["attack2", "attack3", "attack6"]
		attacks.erase(random_animation)
		print(attacks)
		await animation_player.animation_finished
		speed = 3
		animation_player.play("walk")


# Handle when the sword hits an area
func _on_handL_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !handL.disabled:
		Global.playerTakeDamage.emit(40)

func _on_handR_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !handR.disabled:
		Global.playerTakeDamage.emit(40)

func _on_handLboom_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !handLboom.disabled:
		Global.playerTakeDamage.emit(20)

func _on_handRboom_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !handRboom.disabled:
		Global.playerTakeDamage.emit(20)

func _on_body_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !body.disabled:
		Global.playerTakeDamage.emit(60)

func _on_bigBoom_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !bigBoom.disabled:
		Global.playerTakeDamage.emit(80)

func on_playerDealDamage(area):
	if area == self.hitArea and !hitbox.disabled:
		Health -= Global.weaponDamage
		print("Robert hit! Health remaining: " + str(Health))
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
		elif animation_player.current_animation == "attack7" and interruptable:
			animation_player.play("attack7interrupted")
			await animation_player.animation_finished
