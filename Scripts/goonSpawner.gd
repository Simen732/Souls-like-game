extends Node3D

const TEMPLE_GOON = preload("res://scenes/templeGoon.tscn")

func _ready():
	Global.restart.connect(on_restart)
	var instance = TEMPLE_GOON.instantiate()
	add_child(instance)

func on_restart():
	var instance = TEMPLE_GOON.instantiate()
	add_child(instance)
