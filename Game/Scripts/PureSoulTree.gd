extends Control
@onready var go_back = $"."

signal ShowSkillTree

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass




func _on_pressed():
	print("DU trykket på denne tingen")


func _on_skill_tree_show_pure_soul():
	go_back.visible = true


func _on_button_pressed():
	go_back.visible = false
	emit_signal("ShowSkillTree")
