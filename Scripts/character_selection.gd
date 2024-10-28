extends Control




func _on_character_1_pressed():
	print("Du valgte Warrior")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_character_2_pressed():
	print("Du valgte Rouge")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_character_3_pressed():
	print("Du valgte Barbarian")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
