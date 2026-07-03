extends Node
## Outil de vérification : charge l'île, simule des entrées et sauvegarde
## des captures d'écran. Lancer :
##   godot --path . res://tools/capture.tscn

const OUT_DIR := "/tmp/claude-1000/-home-fariz-Perso-zeldalike-isometric-island/8491123a-3df4-442a-9126-0af7f529dab6/scratchpad"


func _ready() -> void:
	var island: Node = load("res://scenes/island.tscn").instantiate()
	add_child(island)
	await _wait(40)
	_shot("shot_1_intro.png")
	# avance tout le dialogue d'intro (2 appuis max par ligne)
	for i in range(14):
		_press("confirm")
		await _wait(6)
	await _wait(20)
	_shot("shot_2_ambush.png")
	# monte vers le chemin et attaque
	Input.action_press("move_up")
	await _wait(150)
	Input.action_release("move_up")
	_press("attack")
	await _wait(6)
	_shot("shot_3_combat.png")
	# élimine tous les kobolds pour vérifier la séquence de victoire
	for k in get_tree().get_nodes_in_group("kobolds"):
		k.take_hit(99, k.global_position + Vector2(0, 8))
	await _wait(80)
	for i in range(10):
		_press("confirm")
		await _wait(6)
	await _wait(30)
	_shot("shot_4_victory.png")
	await _wait(10)
	get_tree().quit()


func _wait(frames: int) -> void:
	for i in range(frames):
		await get_tree().process_frame


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new()
	ev2.action = action
	ev2.pressed = false
	Input.parse_input_event(ev2)


func _shot(file_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR.path_join(file_name))
	print("capture -> ", file_name)
