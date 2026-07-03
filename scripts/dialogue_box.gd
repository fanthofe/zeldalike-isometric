extends CanvasLayer
## Boîte de dialogue avec effet machine à écrire.
## Avancer avec `confirm` (Entrée / X) ou `attack`.

signal finished

const CHARS_PER_SEC := 45.0

var _lines: Array = []
var _idx := 0
var _visible_chars := 0.0
var _on_done := Callable()

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 20
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 12
	_panel.offset_right = -12
	_panel.offset_top = -52
	_panel.offset_bottom = -8

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.16, 0.92)
	style.border_color = Color(0.95, 0.88, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 9)
	_panel.add_child(_label)

	add_child(_panel)
	_panel.visible = false
	set_process(false)


func show_lines(lines: Array, on_done := Callable()) -> void:
	_lines = lines
	_idx = 0
	_on_done = on_done
	GameState.dialogue_active = true
	_panel.visible = true
	_start_line()


func _start_line() -> void:
	_visible_chars = 0.0
	_label.text = _lines[_idx]
	_label.visible_characters = 0
	set_process(true)


func _process(delta: float) -> void:
	_visible_chars += CHARS_PER_SEC * delta
	_label.visible_characters = int(_visible_chars)
	if _label.visible_characters >= _label.text.length():
		_label.visible_characters = -1
		set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		if _label.visible_characters != -1 and _label.visible_characters < _label.text.length():
			_label.visible_characters = -1  # révèle tout
			set_process(false)
		else:
			_idx += 1
			if _idx < _lines.size():
				_start_line()
			else:
				_close()


func _close() -> void:
	_panel.visible = false
	# petit délai pour que l'appui de fermeture ne déclenche pas une attaque
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		GameState.dialogue_active = false
	)
	finished.emit()
	if _on_done.is_valid():
		_on_done.call()
