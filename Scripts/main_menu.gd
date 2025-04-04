extends Control



signal FixMouse

func _on_play_pressed():
	emit_signal("FixMouse")
	get_tree().change_scene_to_file("res://scenes/main.tscn")



func _on_quit_game_pressed():
	get_tree().quit()


func _on_character_select_pressed():
	get_tree().change_scene_to_file("res://scenes/character_selection.tscn")
