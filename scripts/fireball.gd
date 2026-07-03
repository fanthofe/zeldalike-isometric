extends Area2D
## Souffle d'Ahi : projectile de feu tiré par l'orbe rouge.

const SPEED := 150.0
const LIFETIME := 0.9

var dir := Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += dir * SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit(2, global_position)
	FX.puff(get_parent(), global_position)
	queue_free()
