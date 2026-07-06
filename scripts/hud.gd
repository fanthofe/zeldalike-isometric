extends CanvasLayer
## HUD : cœurs de vie et état des deux orbes-esprits.

var _hearts: Array[TextureRect] = []
var _orb_icons := {}
var _heart_full: Texture2D
var _heart_empty: Texture2D
var _essence_label: Label


static func _heart_frame(index: int) -> Texture2D:
	# heart.png (pack Ninja Adventure) : 5 états de 16x16, de vide (0) à plein (4)
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/external/ninja/heart.png")
	at.region = Rect2(index * 16, 0, 16, 16)
	return at


func _ready() -> void:
	_heart_full = _heart_frame(4)
	_heart_empty = _heart_frame(0)
	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 6)
	root.add_theme_constant_override("margin_top", 6)
	add_child(root)

	var box := VBoxContainer.new()
	root.add_child(box)

	var hearts_row := HBoxContainer.new()
	hearts_row.add_theme_constant_override("separation", 1)
	box.add_child(hearts_row)
	for i in range(GameState.MAX_HP):
		var h := TextureRect.new()
		h.texture = _heart_full
		h.stretch_mode = TextureRect.STRETCH_KEEP
		hearts_row.add_child(h)
		_hearts.append(h)

	var orbs_row := HBoxContainer.new()
	orbs_row.add_theme_constant_override("separation", 2)
	box.add_child(orbs_row)
	for kind in ["green", "red"]:
		var icon := TextureRect.new()
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		orbs_row.add_child(icon)
		_orb_icons[kind] = icon

	# essence spirituelle ✦ (monnaie de l'arbre de compétences, menu : Tab)
	var essence_row := HBoxContainer.new()
	essence_row.add_theme_constant_override("separation", 2)
	box.add_child(essence_row)
	var essence_icon := TextureRect.new()
	essence_icon.texture = load("res://assets/sprites/orb_dim.png")
	essence_icon.modulate = Color(0.6, 1.4, 1.8)
	essence_icon.stretch_mode = TextureRect.STRETCH_KEEP
	essence_row.add_child(essence_icon)
	_essence_label = Label.new()
	_essence_label.add_theme_font_size_override("font_size", 8)
	_essence_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	essence_row.add_child(_essence_label)

	GameState.hp_changed.connect(_on_hp_changed)
	GameState.spirits_changed.connect(_refresh_orbs)
	GameState.essence_changed.connect(_on_essence_changed)
	_on_hp_changed(GameState.hp, GameState.MAX_HP)
	_refresh_orbs()
	_on_essence_changed(GameState.essence)


func _on_essence_changed(amount: int) -> void:
	_essence_label.text = "x %d" % amount


func _on_hp_changed(hp: int, _max_hp: int) -> void:
	for i in range(_hearts.size()):
		_hearts[i].texture = _heart_full if i < hp else _heart_empty


func _refresh_orbs() -> void:
	var dim: Texture2D = load("res://assets/sprites/orb_dim.png")
	for kind in ["green", "red"]:
		var awake: bool = GameState.green_awake if kind == "green" else GameState.red_awake
		var icon: TextureRect = _orb_icons[kind]
		icon.texture = load("res://assets/sprites/orb_%s.png" % kind) if awake else dim
		icon.modulate = Color.WHITE if awake else Color(1, 1, 1, 0.5)
