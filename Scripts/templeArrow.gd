extends Node3D

@onready var hurtbox = $Node/hurtbox

var speed = 25
var lifetime = 300

# Called when the node enters the scene tree for the first time.
func _ready():
	if not hurtbox.is_connected("area_entered", Callable(self, "_on_hurtbox_area_entered")):
		hurtbox.connect("area_entered", Callable(self, "_on_hurtbox_area_entered"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if lifetime > 0:
		lifetime -= 1
	global_translate(transform.basis.z * speed * delta)
	if lifetime <= 0:
		queue_free()


func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.name == "Player" or area.get_parent().name == "Player" and !hurtbox.disabled:
		Global.playerTakeDamage.emit(20)
	$Node.visible = false
