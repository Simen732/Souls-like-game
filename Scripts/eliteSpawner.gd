extends Node3D

const TEMPLE_ELITE = preload("res://scenes/templeElite.tscn")

func _ready():
	Global.restart.connect(on_restart)
	var instance = TEMPLE_ELITE.instantiate()
	add_child(instance)

func on_restart():
	var instance = TEMPLE_ELITE.instantiate()
	add_child(instance)
