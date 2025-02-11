extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var handL: Area3D = $Node/root/body/chest/armLeft/elbowLeft/Area3D2
@onready var handR: Area3D = $Node/root/body/chest/armRight/elbowRight/Area3D2
@onready var body: Area3D = $Node/root/body/Area3D3
@onready var boss_healthbar = $"../CharacterBody3D/BossHealthbar"
@onready var hitbox = $Node/root/body/hitBox/GorillaHitbox
@onready var hitArea = $Node/root/body/hitBox

@export var rotatable = true
@export var attackmove = 0
@export var attackstop_distance = 2.5

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
	
	if not body.is_connected("area_entered", Callable(self, "_on_body_area_entered")):
		body.connect("area_entered", Callable(self, "_on_body_area_entered"))


func _physics_process(delta):
	move_and_slide()
	if not is_on_floor():
		velocity.y -= gravity * delta
	if !aggro and self.global_position.distance_to(Global.player_position) <= aggro_range and !Global.playerIsDying and Health > 0:
		aggro = true
		Global.isFighting = true
		music.playing = true
		boss_healthbar.max_value = Health
		boss_healthbar.value = boss_healthbar.max_value
		boss_healthbar.visible = true
		boss_healthbar.value = Health
		animation_player.play("walk")

	if aggro:
		if boss_healthbar.value > Health:
			boss_healthbar.value -= boss_healthbar.max_value/100
		if boss_healthbar.value < Health:
			boss_healthbar.value += boss_healthbar.max_value/100
		if typeof(Global.enemy_lock_on_position) == TYPE_VECTOR3:
			move_towards_player(delta)
		handle_attack(delta)
		if self.global_position.distance_to(Global.player_position) > aggro_range:
			aggro = false
			Health = boss_healthbar.max_value
			Global.isFighting = false
			music.playing = false
			boss_healthbar.visible = false
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
	jump_attack_timer = randi_range(480, 720)
	self.position = spawnpoint



func move_towards_player(delta):
	var direction = Vector3(Global.enemy_lock_on_position.x - self.global_position.x, 0, Global.enemy_lock_on_position.z - self.global_position.z)
	direction = direction.normalized()
	if self.global_position.distance_to(Global.player_position) >= attackstop_distance and rotatable:
		self.global_position += (speed + attackmove) * direction * delta
	else:
		global_translate(transform.basis.z * -attackmove * delta)
	if rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		self.rotation.y = lerp_angle(self.rotation.y, target_rotation_y, 0.05)


# Handle attacking logic
func handle_attack(delta):
	var attackAnim = ["attack1", "attack2", "attack3", "attack4", "attack5", "attack6", "attack7", "attack7interrupted"] #Array med liste av alle attacks
	if self.global_position.distance_to(Global.player_position) > 7.5:
		jump_attack_timer -= randi_range(3, 9)
	else:
		jump_attack_timer -= randi_range(1, 3)
	print(jump_attack_timer)

#Jump attack
	if jump_attack_timer <= 0 and animation_player.current_animation not in attackAnim:
		jump_attack_timer = 9999
		speed = 0
		animation_player.play("attack4")
		attackstop_distance = 0
		await animation_player.animation_finished
		
		var random_ranged_attack = randi_range(1, 5)
		if random_ranged_attack <= 3 and animation_player.current_animation not in attackAnim:
			animation_player.play("attack5")
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

func _on_body_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !body.disabled:
		Global.playerTakeDamage.emit(60)


func on_playerDealDamage(area):
	if area == self.hitArea and !hitbox.disabled:
		Health -= Global.weaponDamage
		print("Robert hit! Health remaining: " + str(Health))
		if Health <= 0:
			boss_healthbar.visible = false
			hitbox.disabled = true
			aggro = false
			Global.isFighting = false
			Global.locked_on = false
			animation_player.stop()
			animation_player.play("death")
			await animation_player.animation_finished
			queue_free()
		elif animation_player.current_animation == "attack7":
			animation_player.play("attack7interrupted")
			await animation_player.animation_finished
