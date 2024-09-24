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

#-----------------------------------------------------------------------------------------------------#






#-----------------------------------------------------------------------------------------------------#


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


#-----------------------------------------------------------------------------------------------------#

func _ready():
	menu.visible = false
	currentStamina.max_value = Global.maxStamina
	currentStamina.value = currentStamina.max_value

	currentHealth.max_value = Global.maxHealth
	currentHealth.value = currentHealth.max_value

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	
	Global.idkKerft = true
	
	
#-----------------------------------------------------------------------------------------------------#



# This is the code for how the camera moves.
func _input(event):
	if event is InputEventMouseMotion and !Global.Menu_open:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		cam_origin.rotate_x(deg_to_rad(event.relative.y * -sensitivity))
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-80), deg_to_rad(40))

#-----------------------------------------------------------------------------------------------------#

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta


	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !Global.playerIsDying:
		velocity.y = Global.JUMP_VELOCITY

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
			

	# Handle movement and dodging
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Global.dodgeCooldown > 0:
		Global.dodgeCooldown -= 1

	if Global.Iframes > 0:
		Global.Iframes -= 1

	if !Input.is_action_pressed("run") and currentStamina.value < Global.maxStamina:
		currentStamina.value += 1

	# Handle smooth dodging
	if Global.isDodging:
		Global.dashStartTime += delta
		if Global.dashStartTime < Global.dashDuration:
			var dashProgress = Global.dashStartTime / Global.dashDuration
			velocity.x = lerp(velocity.x, Global.dashDirection.x * Global.dogdeSpeed, dashProgress)
			velocity.z = lerp(velocity.z, Global.dashDirection.z * Global.dogdeSpeed, dashProgress)
		else:
			Global.isDodging = false
	elif direction and !Global.Menu_open and !Global.playerIsDying:
		velocity.x = direction.x * Global.SPEED
		velocity.z = direction.z * Global.SPEED
		if Input.is_action_pressed("run") and !Global.Menu_open and !Global.playerIsDying and currentStamina.value > 0:
			currentStamina.value -= 1
			velocity.x *= Global.runSpeed
			velocity.z *= Global.runSpeed
		if Input.is_action_just_pressed("dogde") and is_on_floor() and !Global.playerIsDying and direction and Global.dodgeCooldown < 1 and not Global.isDodging:
			if currentStamina.value >= 20:  # Ensure the player has enough stamina
				currentStamina.value -= 80
				Global.dashDirection = direction
				Global.dashStartTime = 0  # Reset the dash timer
				Global.isDodging = true
				Global.dodgeCooldown = 60  # Reset dodge cooldown

	else:
		velocity.x = move_toward(velocity.x, 0, Global.SPEED)
		velocity.z = move_toward(velocity.z, 0, Global.SPEED)

	move_and_slide()

#-----------------------------------------------------------------------------------------------------#

# This is what happens when you touch the deathBox and die
func _on_area_3d_body_entered(body):
	if Global.Iframes < 1:
		if !Global.idkKerft:
			currentHealth.value -= 33.333
			Global.Iframes = 60
			print(currentHealth.value)
			if currentHealth.value < 1:
				Global.playerIsDying = true
				Global.deathCount += 1
				death_counter.text = "Deaths:  " + str(Global.deathCount)
				death_timer.start()
				Engine.time_scale = 0.3
				animation_player.play("deathScreen")
				sensitivity = 0
	else:
		Global.idkKerft = false
		print("idk denne tingen funker")
		print("du har I frames")

#-----------------------------------------------------------------------------------------------------#

# When the death timer ends and you respawn
func _on_death_timer_timeout():
	sensitivity = 0.05
	print(Global.deathCount)
	character_body_3d.global_position = spawn_point
	death_timer.stop()
	Engine.time_scale = 1
	animation_player.play("RESET")
	currentHealth.value = Global.maxHealth
	Global.playerIsDying = false
	menu.visible = false	

#-----------------------------------------------------------------------------------------------------#

# When you touch a checkpoint
func _on_spawn_point_body_entered(body):
	spawn_point = $".".global_position
	print(spawn_point)


func _on_menu_show_skill_tree():
	menu.visible = false
	skill_tree.visible = true

	


func _on_skill_tree_health_up():
	currentHealth.max_value += 100
	currentHealth.value = currentHealth.max_value


func _on_skill_tree_stamina_up():
	currentStamina.max_value += 100
	currentStamina.value = currentStamina.max_value
