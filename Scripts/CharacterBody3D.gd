extends CharacterBody3D

#-----------------------------------------------------------------------------------------------------#


@onready var skill_tree = $skillTree
@onready var cam_origin = $CamOrigin
@export var sensitivity = 0.05
@onready var death_timer = $deathTimer
@onready var animation_player = $AnimationPlayer
@onready var character_body_3d = $"." 
@onready var spawn_point = $".".global_position
@onready var currentHealth = $Health
@onready var currentStamina = $Stamina
@onready var death_counter = $deathCounter
@onready var menu = $Menu
@onready var blockbench_export = $blockbench_export
@onready var sword_area = $blockbench_export/Node/Pelvis/Body/Rarm/Relbow/Sword/Area3D
@onready var sword_collision = $blockbench_export/Node/Pelvis/Body/Rarm/Relbow/Sword/Area3D/CollisionShape3D
@onready var music = $Music


#-----------------------------------------------------------------------------------------------------#


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


#-----------------------------------------------------------------------------------------------------#

signal biGayDamage

#-----------------------------------------------------------------------------------------------------#
func _ready():
	rotation.y = 135

	# Connect the `area_entered` signal for detecting hits with the sword
	sword_area.connect("area_entered", Callable(self, "_on_sword_hit_area"))

	
	menu.visible = false
	currentStamina.max_value = Global.maxStamina
	currentStamina.value = currentStamina.max_value
	currentHealth.max_value = Global.maxHealth
	currentHealth.value = currentHealth.max_value

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


#-----------------------------------------------------------------------------------------------------#


# This is the code for how the camera moves.
func _input(event):
	if event is InputEventMouseMotion and !Global.Menu_open:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		cam_origin.rotate_x(deg_to_rad(event.relative.y * -sensitivity))
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-80), deg_to_rad(40))

#-----------------------------------------------------------------------------------------------------#


func _physics_process(delta):
	# Set the player's global position
	Global.player_position = $".".global_position
	# Add gravity to the character's velocity
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Global.isFightingBoss:
		music.playing = false
	
	
	# Attack logic
	if Input.is_action_just_pressed("attack") and !Global.playerIsDying and !Global.Menu_open and !Global.isDodging: 
		if Global.attackTimer <= 0 and currentStamina.value >= 40:
			currentStamina.value -= 40
			Global.attackTimer = 120
			$blockbench_export/AnimationPlayer.stop()
			$blockbench_export/AnimationPlayer.play("attack1")
			velocity.x = 0  # Reset horizontal movement velocity
			velocity.z = 0  # Reset forward/backward movement velocity
			
	# Disable sword hitbox when the attack finishes
	if Global.attackTimer > 0:
		Global.attackTimer -= 1
		Global.isAttacking = true

	elif Global.attackTimer <= 0:
		Global.isAttacking = false


	if Global.enemyIFrames > 0:
		Global.enemyIFrames -= 1


	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !Global.playerIsDying:
		velocity.y = Global.JUMP_VELOCITY
		$blockbench_export/AnimationPlayer.play("jump")


	# Toggle menu with escape key
	if Input.is_action_just_pressed("escape") and is_on_floor() and !Global.playerIsDying:
		if Global.Menu_open == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Global.Menu_open = true
			Engine.time_scale = 0.3
			animation_player.play("Menu") 

		else:
			Engine.time_scale = 1
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Global.Menu_open = false
			animation_player.play("menuClose")
			skill_tree.visible = false



	# Get input direction for movement (left, right, forward, backward)
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Global.dodgeCooldown > 0:
		Global.dodgeCooldown -= 1


	if direction == Vector3.ZERO and !Global.isDodging and !Global.isAttacking and !Global.playerIsDying:
		velocity.x = 0  # Reset horizontal movement velocity
		velocity.z = 0  # Reset forward/backward movement velocity
		$blockbench_export/AnimationPlayer.play("idle")

	
	if Global.attackTimer > 0:
		$blockbench_export/Node/Pelvis/Body/Rarm/Relbow/Sword/Area3D/CollisionShape3D.disabled = false
		Global.attackTimer -= 1

	elif Global.attackTimer < 0:
		$blockbench_export/Node/Pelvis/Body/Rarm/Relbow/Sword/Area3D/CollisionShape3D.disabled = true
		
		
	if Global.Iframes > 0:
		Global.Iframes -= 1



	if !Input.is_action_pressed("run") and !Global.isDodging and !Global.isAttacking and currentStamina.value < Global.maxStamina:
		currentStamina.value += 1


	if direction and !Global.Menu_open and !Global.playerIsDying and !Global.isAttacking:
		# Movement velocity
		velocity.x = direction.x * Global.SPEED
		velocity.z = direction.z * Global.SPEED

		# Running logic
	# Handle movement and reset sliding issues
	if direction and !Global.Menu_open and !Global.playerIsDying and !Global.isDodging and !Global.isAttacking:
		# Set velocity based on input direction and speed
		velocity.x = direction.x * Global.SPEED
		velocity.z = direction.z * Global.SPEED

		# Handle running logic
		if Input.is_action_pressed("run") and currentStamina.value > 0:
			currentStamina.value -= 1
			velocity.x *= Global.runSpeed
			velocity.z *= Global.runSpeed
			$blockbench_export/AnimationPlayer.play("running")  # Play running animation
		else:
			$blockbench_export/AnimationPlayer.play("walking")  # Play walking animation


	# Dodge logic
	if Input.is_action_just_pressed("dodge") and is_on_floor() and direction and Global.dodgeCooldown < 1 and !Global.isDodging:
		if currentStamina.value >= 60:  # Ensure the player has enough stamina
			currentStamina.value -= 60
			Global.dashDirection = direction
			Global.dashStartTime = 0  # Reset the dash timer
			Global.isDodging = true
			$blockbench_export/AnimationPlayer.play("dodge")  # Play dodge animation
			Global.dodgeCooldown = 45  # Reset dodge cooldown

	# Smooth dodging
	if Global.isDodging:
		Global.dashStartTime += delta
		if Global.dashStartTime < Global.dashDuration:
			var dashProgress = Global.dashStartTime / Global.dashDuration
			velocity.x = lerp(velocity.x, Global.dashDirection.x * Global.dogdeSpeed, dashProgress)
			velocity.z = lerp(velocity.z, Global.dashDirection.z * Global.dogdeSpeed, dashProgress)
			Global.Iframes = 2
		else:
			Global.isDodging = false


	# Move the character
	move_and_slide()

#-----------------------------------------------------------------------------------------------------#
func playertakeDamage():
	if Global.Iframes < 1:
		currentHealth.value -= Global.enemyDamage
		Global.Iframes = 15

		if currentHealth.value <= 0:
			Global.playerIsDying = true
			Global.deathCount += 1
			death_counter.text = "Deaths:  " + str(Global.deathCount)
			death_timer.start()
			Engine.time_scale = 0.3
			velocity = Vector3.ZERO
			$blockbench_export/AnimationPlayer.stop()
			$blockbench_export/AnimationPlayer.play("death")
			animation_player.play("deathScreen")
			sensitivity = 0





# This is what happens when you touch the deathBox and die
func _on_area_3d_body_entered(body):
	playertakeDamage()

#-----------------------------------------------------------------------------------------------------#

# When the death timer ends and you respawn
func _on_death_timer_timeout():
	sensitivity = 0.05
	rotation.y = 135
	character_body_3d.global_position = spawn_point
	death_timer.stop()
	Engine.time_scale = 1
	animation_player.play("RESET")
	$blockbench_export/AnimationPlayer.play("idle")
	currentHealth.value = Global.maxHealth
	Global.playerIsDying = false
	menu.visible = false

#-----------------------------------------------------------------------------------------------------#

# When you touch a checkpoint
func _on_spawn_point_body_entered(body):
	spawn_point = $".".global_position


func _on_menu_show_skill_tree():
	menu.visible = false
	skill_tree.visible = true


func _on_skill_tree_health_up():
	currentHealth.max_value += 10
	currentHealth.value = currentHealth.max_value


func _on_skill_tree_stamina_up():
	currentStamina.max_value += 10
	currentStamina.value = currentStamina.max_value


func _on_blockbench_export_attack_finished():
	$blockbench_export/AnimationPlayer.play("idle")

func _on_sword_hit_area(area):
	# Only trigger during attack when sword collision is enabled
	if !sword_collision.disabled:
		if area.name == "BiGay" or area.get_parent().name == "BiGay":
			if Global.enemyIFrames <= 0:
				Global.enemyIFrames = 30
				emit_signal("biGayDamage")


func _on_bi_gay_player_shank() -> void:
	playertakeDamage()
