extends Control


signal healthUp
signal staminaUp



func _on_button_pressed():
	if Global.SkillPoints > 0:
		Global.runSpeed = Global.runSpeed * 1.5


func _on_damage_up_pressed():
	Global.weaponDamage += 10
	print(Global.weaponDamage)


func _on_health_up_pressed():
	emit_signal("healthUp")
	

func _on_stamina_up_pressed():
	emit_signal("staminaUp")

