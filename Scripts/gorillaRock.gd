extends Node3D

@onready var hurtbox = $Node/Area3D
@onready var animation_player = $AnimationPlayer

var speed = 0
var lifetime = 360

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("idle")
	if not hurtbox.is_connected("area_entered", Callable(self, "_on_hurtbox_area_entered")):
		hurtbox.connect("area_entered", Callable(self, "_on_hurtbox_area_entered"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if lifetime > 0:
		lifetime -= 1
	global_translate(transform.basis.z * speed * delta)
	if lifetime <= 0:
		queue_free()
	
	if lifetime <= 345:
		visible = true
	
	if lifetime == 300:
		speed = 20
		animation_player.play("flying")


func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !hurtbox.disabled:
		Global.playerTakeDamage.emit(40)
	$Node.visible = false
