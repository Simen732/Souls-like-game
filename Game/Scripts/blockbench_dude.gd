extends Node3D


@export var rotatable = true
# Called when the node enters the scene tree for the first time.
func _ready():
	rotatable = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !Global.isAttacking:
		rotatable = true
