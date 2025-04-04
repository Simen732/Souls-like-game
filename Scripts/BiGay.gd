extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var music = $AudioStreamPlayer3D
@onready var biGaySword: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Sword/Area3D
@onready var biGayHilt: Area3D = $Node/Root/Body/ArmR/ElbowR/HandR/Area3D2
@onready var biGayFoot: Area3D = $Node/Root/LegL/KneeL/FootL/Area3D2
@onready var biGayHand: Area3D = $Node/Root/Body/ArmL/ElbowL/HandL/Area3D2
@onready var boss_healthbar = $"../CharacterBody3D/BossHealthbar"
@onready var hitbox = $Node/BiGay/BiguyHitbox
@onready var hitArea = $Node/BiGay

@export var rotatable = true
@export var attackmove = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var ranged_attack_timer = randi_range(60, 180)
var Health = 200
var aggro = false
var speed = 0.75
var attackstop_distance = 0
var attacks = ["attack1", "attack2", "attack4"]
var spawnpoint = Vector3(0, 0, 0)

const aggro_range = 30
const attack124_range = 3  # Distance at which bro uses 1st 2nd and 4th attack
const attack3_range = 6
const attack5_minrange = 8


func _ready():
	spawnpoint = self.position
	Global.restart.connect(on_restart)
	Global.playerDealDamage.connect(on_playerDealDamage)
	$Node/Root/LegL/KneeL/FootL/Area3D2/GPUParticles3D2.emitting = false
	boss_healthbar.max_value = Health
	boss_healthbar.value = boss_healthbar.max_value
	
	if not biGaySword.is_connected("area_entered", Callable(self, "_on_sword_area_entered")):
		biGaySword.connect("area_entered", Callable(self, "_on_sword_area_entered"))

	if not biGayFoot.is_connected("area_entered", Callable(self, "_on_foot_area_entered")):
		biGayFoot.connect("area_entered", Callable(self, "_on_foot_area_entered"))

	if not biGayHand.is_connected("area_entered", Callable(self, "_on_hand_area_entered")):
		biGayHand.connect("area_entered", Callable(self, "_on_hand_area_entered"))

	if not biGayHilt.is_connected("area_entered", Callable(self, "_on_hilt_area_entered")):
		biGayHilt.connect("area_entered", Callable(self, "_on_hilt_area_entered"))


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
		$"../CharacterBody3D/BossHealthbar/RichTextLabel".clear
		$"../CharacterBody3D/BossHealthbar/RichTextLabel".add_text("Biguy, the Big Guy")
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
		if self.global_position.distance_to(Global.player_position) > aggro_range or Health <= 1:
			aggro = false
			Health = boss_healthbar.max_value
			Global.isFighting = false
			music.playing = false
			boss_healthbar.visible = false
			if animation_player.current_animation != "walk":
				await animation_player.animation_finished
				animation_player.play("idle")
			else:
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
	self.position = spawnpoint
	self.rotation = Vector3(0, 0, 0)



func move_towards_player(delta):
	var direction = Vector3(Global.enemy_lock_on_position.x - self.global_position.x, 0, Global.enemy_lock_on_position.z - self.global_position.z)
	direction = direction.normalized()
	if self.global_position.distance_to(Global.player_position) >= attackstop_distance:
		self.global_position += (speed + attackmove) * direction * delta
	if rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		self.rotation.y = lerp_angle(self.rotation.y, target_rotation_y, 0.05)


# Handle attacking logic
func handle_attack(delta):
	var attackAnim = ["attack1", "attack2", "attack3", "attack4", "attack5"] #Array med liste av alle attacks

	if self.global_position.distance_to(Global.player_position) >= attack3_range:
		ranged_attack_timer -= 1


#Close range attacks
	if self.global_position.distance_to(Global.player_position) <= attack124_range and animation_player.current_animation not in attackAnim: #sjekker om den er i midten av et angrep
		var random_animation = attacks[randi() % attacks.size()]
		speed = 0
		animation_player.play(random_animation)
		attacks = ["attack1", "attack2", "attack4"]
		attacks.erase(random_animation)
		print(attacks)
		await animation_player.animation_finished
		speed = 0.75
		animation_player.play("walk")

#Attack3
	elif self.global_position.distance_to(Global.player_position) <= attack3_range and animation_player.current_animation not in attackAnim:
		attackstop_distance = 2
		speed = 0
		animation_player.play("attack3")
		await animation_player.animation_finished
		speed = 0.75
		attackstop_distance = 0
		ranged_attack_timer = randi_range(60, 180)
		animation_player.play("walk")

#ULTIMATE PERFECT ATTACK
	elif self.global_position.distance_to(Global.player_position) >= attack5_minrange and animation_player.current_animation not in attackAnim:
		if ranged_attack_timer <= 0:
			attackstop_distance = 5
			speed = 0
			animation_player.play("attack5")
			await animation_player.animation_finished
			speed = 0.75
			attackstop_distance = 6
			ranged_attack_timer = randi_range(60, 180)
			animation_player.play("walk")


# Handle when the sword hits an area
func _on_sword_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGaySword.disabled:
		Global.playerTakeDamage.emit(40)

func _on_foot_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGayFoot.disabled:
		Global.playerTakeDamage.emit(60)

func _on_hand_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGayHand.disabled:
		Global.playerTakeDamage.emit(20)

func _on_hilt_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !biGayHilt.disabled:
		Global.playerTakeDamage.emit(30)



func on_playerDealDamage(area):
	if area == self.hitArea and !hitbox.disabled:
		Health -= Global.weaponDamage
		print("Bigay hit! Health remaining: " + str(Health))
		if Health <= 0:
			boss_healthbar.visible = false
			hitbox.disabled = true
			aggro = false
			Global.isFighting = false
			Global.locked_on = false
			animation_player.stop()
			animation_player.play("dafeeted")
			await animation_player.animation_finished
			queue_free()
