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
var pitch = 0.0
var locked_on = false
var lock_on_position = Vector3(0, 0, 0)

#-----------------------------------------------------------------------------------------------------#

signal biGayDamage

#-----------------------------------------------------------------------------------------------------#

func _ready():
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


func _input(event):
	if event is InputEventMouseMotion and !Global.Menu_open and !locked_on:
		# Rotate the camera around the player without affecting the player's rotation
		cam_origin.rotate_y(deg_to_rad(-event.relative.x * sensitivity))  # Horizontal camera movement
		# Clamp vertical camera movement to avoid flipping
		pitch -= (deg_to_rad(event.relative.y * sensitivity))  # Invert the input to make up/down feel natural
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(40))
		cam_origin.rotation.x = pitch
		cam_origin.rotation.z = 0


#-----------------------------------------------------------------------------------------------------#


func _physics_process(delta):
	# Set the player's global position
	Global.player_position = $".".global_position
	# Add gravity to the character's velocity
	if not is_on_floor():
		velocity.y -= gravity * delta


	if Global.isFightingBoss:
		music.playing = false
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var cam_forward = cam_origin.transform.basis.z.normalized() # Forward direction of the camera
	cam_forward.y = 0
	var cam_right = cam_origin.transform.basis.x.normalized() # Right direction of the camera
	var direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()


	if direction != Vector3.ZERO and !Global.isDodging and !Global.playerIsDying and !Global.Menu_open and $blockbench_export.rotatable:
		var target_rotation_y = atan2(-direction.x, -direction.z)
		$blockbench_export.rotation.y = lerp_angle($blockbench_export.rotation.y, target_rotation_y, 0.1)

#Lock on logic
	if Input.is_action_just_pressed("lock on"):
		locked_on = true
	
	if locked_on:
		lock_on_position = $"../BiGay/playerLockOn".global_position
		var lock_on_direction = Vector3(lock_on_position - cam_origin.global_position)
		lock_on_direction = lock_on_direction.normalized()
		var target_rotation = atan2(-lock_on_direction.x, -lock_on_direction.z)
		cam_origin.rotation.y = lerp_angle(cam_origin.rotation.y, target_rotation, 0.5)


	# Attack logic
	if Input.is_action_just_pressed("attack") and !Global.playerIsDying and !Global.Menu_open and !Global.isDodging: 
		if Global.attackTimer <= 0 and currentStamina.value >= 40:
			currentStamina.value -= 40
			Global.attackTimer = 120
			$blockbench_export/AnimationPlayer.stop()
			$blockbench_export/AnimationPlayer.play("attack1")
			velocity.z = 0
			velocity.x = 0
	# Disable sword hitbox when the attack finishes
	if Global.attackTimer > 0:
		Global.attackTimer -= 1
		sword_collision.disabled = false
		Global.isAttacking = true  # Enable sword collision during attack
	else:
		Global.isAttacking = false  # Disable sword collision when not attacking
		sword_collision.disabled = true


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

	if Global.dashboost > 0:
		Global.dashboost -= 1

	if !Input.is_action_pressed("run") and is_on_floor() and !Global.isDodging and !Global.isAttacking and currentStamina.value < Global.maxStamina:
		currentStamina.value += 1


	if direction and !Global.Menu_open and !Global.playerIsDying and !Global.isAttacking and !Global.isDodging:
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
	if Input.is_action_just_pressed("dodge") and is_on_floor() and direction and Global.dodgeCooldown < 1 and !Global.isDodging and !Global.playerIsDying:
		if currentStamina.value >= 60:  # Ensure the player has enough stamina
			currentStamina.value -= 60
			Global.dashDirection = direction
			Global.dashStartTime = 0  # Reset the dash timer
			Global.isDodging = true
			Global.dashboost = 50
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
	cam_origin.look_at_from_position(cam_origin.global_position, character_body_3d.global_position, Vector3.UP)
	sensitivity = 0.05
	character_body_3d.global_position = spawn_point
	death_timer.stop()
	Engine.time_scale = 1
	animation_player.play("RESET")
	$blockbench_export/AnimationPlayer.play("idle")
	currentHealth.value = Global.maxHealth
	Global.playerIsDying = false
	Global.restart.emit()
	menu.visible = false

#-----------------------------------------------------------------------------------------------------#

# When you touch a checkpoint
func _on_spawn_point_body_entered(body):
	spawn_point = $".".global_position


func _on_menu_show_skill_tree():
	menu.visible = false
	skill_tree.visible = true


func _on_skill_tree_health_up():
	Global.maxHealth *= 1.1
	currentHealth.max_value = Global.maxHealth


func _on_skill_tree_stamina_up():
	Global.maxStamina *= 1.1
	currentStamina.max_value = Global.maxStamina


func _on_blockbench_export_attack_finished():
	$blockbench_export/AnimationPlayer.play("idle")

func _on_sword_hit_area(area):
	# Only trigger damage during attack animation when sword collision is enabled
	if !sword_collision.disabled:
		if area.name == "BiGay" or area.get_parent().name == "BiGay":
			if Global.enemyIFrames <= 0:
				Global.enemyIFrames = 50  # Add invincibility frames to the enemy
				emit_signal("biGayDamage")  # Emit damage signal



func _on_bi_gay_player_shank() -> void:
	playertakeDamage()
