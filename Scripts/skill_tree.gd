extends Control
@onready var rich_text_label = $RichTextLabel


signal healthUp
signal staminaUp

func _ready():
	rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)


func _on_button_pressed():
	print("denne kjører")
	if Global.SkillPoints > 0:
		Global.SkillPoints -= 1		
		rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)
		Global.runSpeed = Global.runSpeed * 1.5


func _on_damage_up_pressed():
	if Global.SkillPoints > 0:
		Global.weaponDamage *= 1.1
		print(Global.weaponDamage)
		Global.SkillPoints -= 1
		rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)


func _on_health_up_pressed():
	if Global.SkillPoints > 0:
		emit_signal("healthUp")
		Global.SkillPoints -= 1
		rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)

func _on_stamina_up_pressed():
	if Global.SkillPoints > 0:
		emit_signal("staminaUp")
		Global.SkillPoints -= 1
		rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)
