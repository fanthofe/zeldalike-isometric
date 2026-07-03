extends Node2D
## Orbe-esprit qui orbite autour de Kaimana.
## Éteinte (grise) tant que l'esprit correspondant est endormi.

@export_enum("green", "red") var kind := "green"
@export var angle_offset := 0.0

var _t := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var light: PointLight2D = $Light


func _ready() -> void:
	GameState.spirits_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	_t += delta
	var a := _t * 1.8 + angle_offset
	position = Vector2(cos(a) * 12.0, sin(a) * 5.0 - 15.0 + sin(_t * 3.0 + angle_offset) * 1.2)


func is_awake() -> bool:
	return GameState.green_awake if kind == "green" else GameState.red_awake


func _refresh() -> void:
	if is_awake():
		sprite.texture = load("res://assets/sprites/orb_%s.png" % kind)
		sprite.modulate = Color(1.6, 1.6, 1.6)  # HDR : alimente le glow
		light.color = Color(0.4, 1.0, 0.5) if kind == "green" else Color(1.0, 0.45, 0.35)
		light.energy = 1.0
	else:
		sprite.texture = load("res://assets/sprites/orb_dim.png")
		sprite.modulate = Color.WHITE
		light.color = Color(0.7, 0.7, 0.8)
		light.energy = 0.15


func pulse() -> void:
	var tw := create_tween()
	tw.tween_property(light, "energy", 2.5, 0.1)
	tw.tween_property(light, "energy", 1.0 if is_awake() else 0.15, 0.5)


## Petit frémissement utilisé en cinématique (teaser de l'éveil).
func flicker() -> void:
	var tw := create_tween()
	for i in range(4):
		tw.tween_property(light, "energy", 1.2, 0.12)
		tw.tween_property(light, "energy", 0.15, 0.18)
