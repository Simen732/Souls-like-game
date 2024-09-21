extends Control

signal showSkillTree


func _on_quit_game_pressed():
	get_tree().quit()


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_skill_tree_pressed():
	emit_signal("showSkillTree")
