extends Node3D


@export var rotatable = true
@export var invulnerable = true
@export var parrying = false
@export var attackMove = 0

func _ready():
	Global.restart.connect(_on_restart)
	rotatable = true

func _on_restart():
	rotatable = true
