extends CanvasLayer
## Menu de l'arbre de compétences « Les Dons des Esprits » (Tab / M).
## Met le jeu en pause ; navigation clavier ; déblocage contre de l'essence.
## Entièrement construit en code, comme le reste de l'UI du jeu.

const COL_UNLOCKED_BG := Color(0.10, 0.14, 0.12, 0.95)
const COL_LOCKED_BG := Color(0.06, 0.08, 0.10, 0.95)
const COL_SELECT := Color(1.0, 0.85, 0.3)
const COL_AVAILABLE := Color(0.9, 0.9, 0.9)
const COL_LOCKED := Color(0.35, 0.38, 0.42)

var _sel_branch := 0
var _sel_row := 0
var _root: Control
var _essence_label: Label
var _desc_name: Label
var _desc_status: Label
var _desc_text: Label
var _panels := {}  # id de compétence -> PanelContainer


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false
	GameState.essence_changed.connect(func(_a: int) -> void: _refresh())
	GameState.skills_changed.connect(_refresh)
	GameState.spirits_changed.connect(_refresh)


func is_open() -> bool:
	return _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skills"):
		get_viewport().set_input_as_handled()
		_close() if is_open() else _open()
		return
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("move_down"):
		_move_selection(1, 0)
	elif event.is_action_pressed("move_up"):
		_move_selection(-1, 0)
	elif event.is_action_pressed("move_left"):
		_move_selection(0, -1)
	elif event.is_action_pressed("move_right"):
		_move_selection(0, 1)
	elif event.is_action_pressed("confirm"):
		_try_unlock()
	else:
		return
	get_viewport().set_input_as_handled()


func _open() -> void:
	if GameState.dialogue_active:
		return
	_root.visible = true
	get_tree().paused = true
	_refresh()


func _close() -> void:
	_root.visible = false
	get_tree().paused = false


func _move_selection(drow: int, dbranch: int) -> void:
	_sel_branch = clampi(_sel_branch + dbranch, 0, SkillTree.BRANCHES.size() - 1)
	var count := SkillTree.branch_skills(_sel_branch).size()
	_sel_row = clampi(_sel_row + drow, 0, count - 1)
	_refresh()


func _selected_def() -> Dictionary:
	return SkillTree.branch_skills(_sel_branch)[_sel_row]


func _try_unlock() -> void:
	var def := _selected_def()
	if GameState.has_skill(def.id) or not def.impl:
		return
	if def.prereq != "" and not GameState.has_skill(def.prereq):
		return
	if GameState.unlock_skill(def.id, def.cout):
		Sfx.play("pickup", -8.0, 1.3)


# ------------------------------------------------------------- construction

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.07, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 5)
	_root.add_child(margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 3)
	margin.add_child(main)

	var header := HBoxContainer.new()
	main.add_child(header)
	var title := Label.new()
	title.text = "LES DONS DES ESPRITS"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45))
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_essence_label = Label.new()
	_essence_label.add_theme_font_size_override("font_size", 9)
	_essence_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	header.add_child(_essence_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(columns)
	for b in range(SkillTree.BRANCHES.size()):
		columns.add_child(_build_branch_column(b))

	var desc_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.16, 0.95)
	style.border_color = Color(0.95, 0.88, 0.62)
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	desc_panel.add_theme_stylebox_override("panel", style)
	desc_panel.custom_minimum_size = Vector2(0, 38)
	main.add_child(desc_panel)
	var desc_box := VBoxContainer.new()
	desc_box.add_theme_constant_override("separation", 0)
	desc_panel.add_child(desc_box)
	_desc_name = Label.new()
	_desc_name.add_theme_font_size_override("font_size", 8)
	desc_box.add_child(_desc_name)
	_desc_text = Label.new()
	_desc_text.add_theme_font_size_override("font_size", 8)
	_desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_text.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	desc_box.add_child(_desc_text)
	_desc_status = Label.new()
	_desc_status.add_theme_font_size_override("font_size", 8)
	desc_box.add_child(_desc_status)


func _build_branch_column(branch: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = SkillTree.BRANCHES[branch].nom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", SkillTree.BRANCHES[branch].couleur)
	col.add_child(label)
	for def in SkillTree.branch_skills(branch):
		var panel := PanelContainer.new()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		panel.add_child(row)
		var icon := TextureRect.new()
		icon.texture = load(def.icone)
		icon.custom_minimum_size = Vector2(10, 10)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(icon)
		var name_label := Label.new()
		name_label.text = def.nom
		name_label.add_theme_font_size_override("font_size", 7)
		name_label.clip_text = true
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		_panels[def.id] = panel
		col.add_child(panel)
	return col


# -------------------------------------------------------------- rafraîchit

func _refresh() -> void:
	if not is_open():
		return
	_essence_label.text = "Essence : %d" % GameState.essence
	for branch in range(SkillTree.BRANCHES.size()):
		var skills := SkillTree.branch_skills(branch)
		for row in range(skills.size()):
			_style_panel(skills[row], branch == _sel_branch and row == _sel_row)
	_refresh_desc()


func _style_panel(def: Dictionary, selected: bool) -> void:
	var panel: PanelContainer = _panels[def.id]
	var unlocked := GameState.has_skill(def.id)
	var available: bool = def.impl and not unlocked \
			and (def.prereq == "" or GameState.has_skill(def.prereq))
	var style := StyleBoxFlat.new()
	style.set_content_margin_all(2)
	style.set_corner_radius_all(2)
	style.bg_color = COL_UNLOCKED_BG if unlocked else COL_LOCKED_BG
	if selected:
		style.border_color = COL_SELECT
		style.set_border_width_all(2)
	elif unlocked:
		style.border_color = SkillTree.BRANCHES[def.branche].couleur
		style.set_border_width_all(1)
	elif available:
		style.border_color = COL_AVAILABLE
		style.set_border_width_all(1)
	else:
		style.border_color = COL_LOCKED
		style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color.WHITE if (unlocked or available or selected) else Color(1, 1, 1, 0.55)


func _refresh_desc() -> void:
	var def := _selected_def()
	_desc_name.text = "%s — %s" % [def.nom.to_upper(), def.type]
	_desc_name.add_theme_color_override("font_color", SkillTree.BRANCHES[def.branche].couleur)
	_desc_text.text = def.desc
	if GameState.has_skill(def.id):
		_desc_status.text = "Débloqué"
		_desc_status.add_theme_color_override("font_color", Color(0.5, 0.9, 0.55))
	elif not def.impl:
		_desc_status.text = "Bientôt disponible (voir docs/arbre-competences.md)"
		_desc_status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	elif def.prereq != "" and not GameState.has_skill(def.prereq):
		_desc_status.text = "Requiert : %s" % SkillTree.get_def(def.prereq).nom
		_desc_status.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	elif GameState.essence < def.cout:
		_desc_status.text = "Essence insuffisante (coût : %d)" % def.cout
		_desc_status.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	else:
		_desc_status.text = "Entrée : débloquer (%d essence)" % def.cout
		_desc_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
