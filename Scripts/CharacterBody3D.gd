extends CharacterBody3D

#-----------------------------------------------------------------------------------------------------#

@onready var skill_tree = $skillTree
@onready var cam_origin = $CamOrigin
@export var sensitivity = 0.05
@onready var death_timer = $deathTimer
@onready var animation_player = $AnimationPlayer
@onready var character_body_3d = self 
@onready var spawn_point = self.global_position
@onready var healthbar = $Health
@onready var currentStamina = $Stamina
@onready var death_counter = $deathCounter
@onready var menu = $Menu
@onready var blockbench_export = $blockbench_export
@onready var sword_area = $blockbench_export/Node/Pelvis/Body/Rarm/Relbow/Sword/Area3D
@onready var sword_collision = $blockbench_export/Node/Pelvis/Body/Rarm/Relbow/Sword/Area3D/CollisionShape3D
@onready var music = $Music


#-----------------------------------------------------------------------------------------------------#


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch = 0.0

var currentHealth = 200
var lockOnTarget = Vector3()
var lockOnRange = 30
var minTargetRange = INF  # Start with a very large number
var closestTarget = null
var motionValue = 1
var staminaLevel = 0
var isParrying = false
var parryTimer = 0
#-----------------------------------------------------------------------------------------------------#

signal playerDamage
signal playerSwordHitbox

#-----------------------------------------------------------------------------------------------------#

func _ready():
	Global.playerTakeDamage.connect(on_playerTakeDamage)
	
	if !Global.havePlayedGame:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		Global.havePlayedGame = true
	# Connect the `area_entered` signal for detecting hits with the sword
	sword_area.connect("area_entered", Callable(self, "_on_sword_hit_area"))

	menu.visible = false
	currentStamina.max_value = Global.maxStamina
	currentStamina.value = currentStamina.max_value
	healthbar.max_value = Global.maxHealth
	currentHealth = Global.maxHealth

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	fixCamera()


#-----------------------------------------------------------------------------------------------------#


func _input(event):
	if event is InputEventMouseMotion and !Global.Menu_open and !Global.locked_on:
		# Rotate the camera around the player without affecting the player's rotation
		cam_origin.rotate_y(deg_to_rad(-event.relative.x * sensitivity))  # Horizontal camera movement
		# Clamp vertical camera movement to avoid flipping
		pitch -= (deg_to_rad(event.relative.y * sensitivity))  # Invert the input to make up/down feel natural
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(40))
		cam_origin.rotation.x = pitch
		cam_origin.rotation.z = 0


func position_camera_behind_character():
	cam_origin.global_rotation = blockbench_export.global_rotation


#-----------------------------------------------------------------------------------------------------#


func _physics_process(delta):
	move_and_slide()
	if not is_on_floor():
		velocity.y -= gravity * delta
	if healthbar.value > currentHealth:
			healthbar.value -= Global.maxHealth/100
	if healthbar.value < currentHealth:
			healthbar.value += Global.maxHealth/100
	Global.player_position = self.global_position


	if self.global_position.y <= -1000:
		Global.playerTakeDamage.emit(42069)


	# Add gravity to the character's velocity
	if not is_on_floor():
		velocity.y -= gravity * delta


	if Global.isFighting:
		music.playing = false
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var cam_forward = cam_origin.transform.basis.z.normalized() # Forward direction of the camera
	cam_forward.y = 0
	var cam_right = cam_origin.transform.basis.x.normalized() # Right direction of the camera
	var direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()


	if direction != Vector3.ZERO and !Global.isDodging and !Global.playerIsDying and !Global.Menu_open and $blockbench_export.rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		$blockbench_export.rotation.y = lerp_angle($blockbench_export.rotation.y, target_rotation_y, 0.1)


	# Attack logic
	if Input.is_action_just_pressed("attack") and !Global.playerIsDying and !Global.Menu_open and !Global.isDodging and $blockbench_export/AnimationPlayer.current_animation != "attack1":
		if currentStamina.value >= 40:
			currentStamina.value -= 40
			$blockbench_export/AnimationPlayer.stop()
			$blockbench_export/AnimationPlayer.play("attack1")
			velocity.z = 0
			velocity.x = 0


	if Global.enemyIFrames > 0:
		Global.enemyIFrames -= 1

	if $blockbench_export/AnimationPlayer.current_animation == "attack1" and $blockbench_export.rotatable:
		$blockbench_export.rotation.y = lerp_angle($blockbench_export.rotation.y, cam_origin.rotation.y, 0.25)


	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !Global.playerIsDying:
		if currentStamina.value >= 20:
			currentStamina.value -= 20
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

		
		
	if  $blockbench_export/AnimationPlayer.current_animation == "hurt":
		Global.flinch = true
	else:
		Global.flinch = false
		
		
	if Global.dodgeCooldown > 0:
		Global.dodgeCooldown -= 1

	if parryTimer > 0:
		parryTimer -= 1
		isParrying = true
		
		
	if Input.is_action_just_pressed("Parry") and is_on_floor() and !Global.playerIsDying:
		parryTimer = 30
		print("parry")
		


	if !Global.flinch and direction == Vector3.ZERO and !Global.isDodging and !Global.playerIsDying and $blockbench_export/AnimationPlayer.current_animation != "attack1":
		velocity.x = 0  # Reset horizontal movement velocity
		velocity.z = 0  # Reset forward/backward movement velocity
		$blockbench_export/AnimationPlayer.play("idle")

	if Global.Iframes > 0:
		Global.Iframes -= 1

	if Global.dashboost > 0:
		Global.dashboost -= 1

	if Global.isFighting == false and currentStamina.value < Global.maxStamina:
		currentStamina.value += 1 + (staminaLevel/5)

	if !Input.is_action_pressed("run") and is_on_floor() and !Global.isDodging and currentStamina.value < Global.maxStamina and $blockbench_export/AnimationPlayer.current_animation != "attack1":
		currentStamina.value += 1 + (staminaLevel/5)


	# Handle movement and reset sliding issues
	if direction and !Global.Menu_open and !Global.playerIsDying and !Global.isDodging and !Global.flinch and $blockbench_export/AnimationPlayer.current_animation != "attack1":
		# Set velocity based on input direction and speed
		velocity.x = direction.x * Global.SPEED
		velocity.z = direction.z * Global.SPEED

		# Handle running logic
		if Input.is_action_pressed("run") and currentStamina.value > 0 and !Global.flinch and $blockbench_export/AnimationPlayer.current_animation != "attack1":
			if Global.isFighting:
				currentStamina.value -= 2.5
			velocity.x *= Global.runSpeed
			velocity.z *= Global.runSpeed
			$blockbench_export/AnimationPlayer.play("running")  # Play running animation
		else:
			$blockbench_export/AnimationPlayer.play("walking")  # Play walking animation

	# Dodge logic
	if Input.is_action_just_pressed("dodge") and is_on_floor() and direction and Global.dodgeCooldown < 1 and !Global.isDodging and !Global.playerIsDying and !Global.flinch and $blockbench_export/AnimationPlayer.current_animation != "attack1":
		if currentStamina.value >= 60:  # Ensure the player has enough stamina
			currentStamina.value -= 60
			Global.dashDirection = direction
			Global.dashStartTime = 0  # Reset the dash timer
			Global.isDodging = true
			Global.dashboost = 30
			$blockbench_export/AnimationPlayer.play("dodge")  # Play dodge animation
			Global.dodgeCooldown = 45  # Reset dodge cooldown


		
	# Smooth dodging
	if Global.isDodging:
		Global.dashStartTime += delta
		if Global.dashStartTime < Global.dashDuration:
			var dashProgress = Global.dashStartTime / Global.dashDuration
			if Global.dashboost > 0:
				velocity.x = lerp(velocity.x, Global.dashDirection.x * Global.dogdeSpeed, dashProgress)
				velocity.z = lerp(velocity.z, Global.dashDirection.z * Global.dogdeSpeed, dashProgress)
				Global.Iframes = 2
			else:
				velocity.x = lerp(velocity.x, Global.dashDirection.x * Global.SPEED * 0.25, dashProgress)
				velocity.z = lerp(velocity.z, Global.dashDirection.z * Global.SPEED * 0.25, dashProgress)
				Global.Iframes = 2
		else:
			Global.isDodging = false

#-----------------------------------------------------------------------------------------------------#


func on_playerTakeDamage(damageTaken):
	if Global.Iframes < 1 and !Global.playerIsDying and parryTimer < 1:
		currentHealth -= damageTaken
		$blockbench_export/AnimationPlayer.stop()
		$blockbench_export/AnimationPlayer.play("hurt")
		velocity.z = 0
		velocity.x = 0
		print("Player hit! Health remaining: " + str(currentHealth))
		Global.Iframes = 10

		if currentHealth <= 0:
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
	elif parryTimer > 1:
		print("Parry yiiiiipppppppppppppppiiiiiiiiiiiiiii")

#-----------------------------------------------------------------------------------------------------#



# When the death timer ends and you respawn
func _on_death_timer_timeout():
	cam_origin.look_at_from_position(cam_origin.global_position, character_body_3d.global_position, Vector3.UP)
	sensitivity = 0.05
	character_body_3d.global_position = spawn_point
	death_timer.stop()
	Engine.time_scale = 1
	animation_player.play("RESET")
	$blockbench_export/AnimationPlayer.play("idle")
	currentHealth = Global.maxHealth
	Global.playerIsDying = false
	Global.restart.emit()
	menu.visible = false
	Global.locked_on = false

#-----------------------------------------------------------------------------------------------------#

# When you touch a checkpoint
func _on_spawn_point_body_entered(body):
	spawn_point = self.global_position


func _on_menu_show_skill_tree():
	menu.visible = false
	skill_tree.visible = true


func _on_sword_hit_area(area):
	if !sword_collision.disabled:
		print(area)
		Global.playerDealDamage.emit(area) # Emit damage signal


func _on_skill_tree_stamina_up():
	Global.maxStamina *= 1.1
	staminaLevel += 1
	currentStamina.max_value = Global.maxStamina
	print("Stamina up")


func _on_skill_tree_health_up():
	Global.maxHealth += 50 * 1.05
	currentHealth = Global.maxHealth
	currentHealth += currentHealth.max_value/10 
	print(currentHealth)
	print(healthbar.max_value)


func fixCamera():
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
