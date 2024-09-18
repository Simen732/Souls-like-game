extends CharacterBody3D

#-----------------------------------------------------------------------------------------------------#

@onready var cam_origin = $CamOrigin
@export var sensitivity = 0.05
@onready var death_timer = $deathTimer
@onready var animation_player = $AnimationPlayer
@onready var character_body_3d = $"." 
@onready var spawn_point = $".".global_position
@onready var currentHealth = $Health
@onready var currentStamina = $Stamina
@onready var death_counter = $deathCounter

#-----------------------------------------------------------------------------------------------------#

const SPEED = 5.0
const JUMP_VELOCITY = 5

#-----------------------------------------------------------------------------------------------------#

var maxStamina = 200
var maxHealth = 100
var idkKerft = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var Menu_open = false
var spawnPoint = Vector3(0,0,0)
var deathCount = 0
var runSpeed = 2
var playerIsDying = false
var dogdeSpeed = 10
var dodgeCooldown = 60
var Iframes = 60

var isDodging = false
var dashStartTime = 0.0
var dashDuration = 0.5  # Dash duration in seconds
var dashDirection = Vector3.ZERO

#-----------------------------------------------------------------------------------------------------#

func _ready():
	currentStamina.max_value = maxStamina
	currentStamina.value = currentStamina.max_value

	currentHealth.max_value = maxHealth
	currentHealth.value = currentHealth.max_value

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#-----------------------------------------------------------------------------------------------------#



# This is the code for how the camera moves.
func _input(event):
	if event is InputEventMouseMotion and !Menu_open:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		cam_origin.rotate_x(deg_to_rad(event.relative.y * -sensitivity))
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-80), deg_to_rad(40))

#-----------------------------------------------------------------------------------------------------#

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !playerIsDying:
		velocity.y = JUMP_VELOCITY

	# Toggle menu with escape key
	if Input.is_action_just_pressed("escape") and is_on_floor() and !playerIsDying:
		if Menu_open == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Menu_open = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Menu_open = false

	# Handle movement and dodging
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if dodgeCooldown > 0:
		dodgeCooldown -= 1

	if Iframes > 0:
		Iframes -= 1

	if !Input.is_action_pressed("run") and currentStamina.value < maxStamina:
		currentStamina.value += 1

	# Handle smooth dodging
	if isDodging:
		dashStartTime += delta
		if dashStartTime < dashDuration:
			var dashProgress = dashStartTime / dashDuration
			velocity.x = lerp(velocity.x, dashDirection.x * dogdeSpeed, dashProgress)
			velocity.z = lerp(velocity.z, dashDirection.z * dogdeSpeed, dashProgress)
		else:
			isDodging = false
	elif direction and !Menu_open and !playerIsDying:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if Input.is_action_pressed("run") and !Menu_open and !playerIsDying:
			currentStamina.value -= 1
			velocity.x *= runSpeed
			velocity.z *= runSpeed
		if Input.is_action_just_pressed("dogde") and is_on_floor() and !playerIsDying and direction and dodgeCooldown < 1 and not isDodging:
			if currentStamina.value >= 20:  # Ensure the player has enough stamina
				currentStamina.value -= 80
				dashDirection = direction
				dashStartTime = 0  # Reset the dash timer
				isDodging = true
				dodgeCooldown = 60  # Reset dodge cooldown

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

#-----------------------------------------------------------------------------------------------------#

# This is what happens when you touch the deathBox and die
func _on_area_3d_body_entered(body):
	if Iframes < 1:
		if !idkKerft:
			currentHealth.value -= 33.333
			Iframes = 60
			print(currentHealth.value)
			if currentHealth.value < 1:
				playerIsDying = true
				deathCount += 1
				death_counter.text = "Deaths:  " + str(deathCount)
				death_timer.start()
				Engine.time_scale = 0.3
				animation_player.play("deathScreen")
				sensitivity = 0
	else:
		idkKerft = false
		print("idk denne tingen funker")
		print("du har I frames")

#-----------------------------------------------------------------------------------------------------#

# When the death timer ends and you respawn
func _on_death_timer_timeout():
	sensitivity = 0.05
	print(deathCount)
	character_body_3d.global_position = spawn_point
	death_timer.stop()
	Engine.time_scale = 1
	animation_player.play("RESET")
	currentHealth.value = maxHealth
	playerIsDying = false

#-----------------------------------------------------------------------------------------------------#

# When you touch a checkpoint
func _on_spawn_point_body_entered(body):
	spawn_point = $".".global_position
	print(spawn_point)
