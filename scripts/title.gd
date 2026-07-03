extends Control
## Écran titre : logo, héros et invite de démarrage.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.11, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var title := Label.new()
	title.text = "KAIMANA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "L'Île des Esprits Silencieux"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.85, 0.85))
	box.add_child(subtitle)

	var hero := TextureRect.new()
	hero.texture = load("res://assets/sprites/hero_idle_down_0.png")
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.custom_minimum_size = Vector2(48, 60)
	hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(hero)

	var prompt := Label.new()
	prompt.text = "Appuyez sur Entrée"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 9)
	box.add_child(prompt)

	var tw := create_tween().set_loops()
	tw.tween_property(prompt, "modulate:a", 0.2, 0.6)
	tw.tween_property(prompt, "modulate:a", 1.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("attack"):
		get_tree().change_scene_to_file("res://scenes/island.tscn")
