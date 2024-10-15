extends Control
@onready var rich_text_label = $RichTextLabel
@onready var spirit_label = $MarginContainer5/spiritUp/MarginContainer/SpiritLabel
@onready var spirit_panel = $MarginContainer5/SpiritPanel
@onready var damage_panel = $MarginContainer2/DamagePanel
@onready var damage_label = $MarginContainer2/damageUp/MarginContainer/damageLabel
@onready var stamina_panel = $MarginContainer4/StaminaPanel
@onready var stamina_label = $MarginContainer4/StaminaUp/MarginContainer/StaminaLabel
@onready var health_panel = $MarginContainer6/healthPanel
@onready var health_label = $MarginContainer6/healthUp/healthContainer/healthLabel




signal healthUp
signal staminaUp

var spiritLevel : int = 0:
	set(value):
		spiritLevel = value
		spirit_label.text = str(spiritLevel) + "/10"

var damageLevel : int = 0:
	set(value):
		damageLevel = value
		damage_label.text = str(damageLevel) + "/10"

var staminaLevel : int = 0:
	set(value):
		staminaLevel = value
		stamina_label.text = str(staminaLevel) + "/10"
		
var healthLevel : int = 0:
	set(value):
		healthLevel = value
		health_label.text = str(healthLevel) + "/10"

func _ready():
	rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)








func _on_spirit_up_pressed():
	if Global.SkillPoints > 0:
		if spiritLevel < 10:
			spiritLevel = min ( spiritLevel+1, 10)
			spirit_panel.show_behind_parent = true
			Global.Spirit += 5
			Global.SkillPoints -= 1
			rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)
			print("Du har nå " + str(Global.Spirit) + " Spirit. Spiritlevel er nå" + str(spiritLevel))


func _on_damage_up_pressed():
	if Global.SkillPoints > 0:
		if damageLevel < 10:
			damageLevel = min ( damageLevel+1, 10)
			spirit_panel.show_behind_parent = true
			Global.weaponDamage += 5 * 1.025
			Global.SkillPoints -= 1
			rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)
			print("Du har nå " + str(Global.weaponDamage) + " damage. DamageLevel er nå" + str(damageLevel))



func _on_stamina_up_pressed():
	if Global.SkillPoints > 0 and staminaLevel < 10:
		emit_signal("staminaUp")
		Global.SkillPoints -= 1
		rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)
		stamina_panel.show_behind_parent = true
		staminaLevel = min ( staminaLevel+1, 10)
		print("Staminalevel er nå" + str(staminaLevel))


func _on_health_up_pressed():
	if Global.SkillPoints > 0 and healthLevel < 10:
		emit_signal("healthUp")
		Global.SkillPoints -= 1
		rich_text_label.text = "Skill Points:" + str(Global.SkillPoints)
		health_panel.show_behind_parent = true
		healthLevel = min ( healthLevel+1, 10)
		print("healthlevel er nå" + str(healthLevel))
