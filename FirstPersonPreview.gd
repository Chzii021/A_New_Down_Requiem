extends "res://main.gd"

# Optional F6 showroom for the assembled rifle; F5 starts at map 1 without a weapon.
func _ready() -> void:
	super._ready()
	has_pistol=true
	avatar.gun.visible=true
	first_weapon.visible=first_person
	assembled=true
	avatar.call("set_rifle",true)
	first_weapon.call("set_rifle",true)
	ammo=20
	reserve=100
	message_time=0.0
	message_label.text=""
	_update_ui()
