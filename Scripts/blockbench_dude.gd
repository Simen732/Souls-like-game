extends Node3D


@export var rotatable = true

func _ready():
	Global.restart.connect(_on_restart)
	rotatable = true

func _on_restart():
	rotatable = true
