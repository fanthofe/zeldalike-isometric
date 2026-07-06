extends CharacterBody2D
## Kobold du clan des Crocs-Parjures : mi-loup mi-homme.
## Erre, repère Kaimana, se ramasse puis bondit sur lui.

signal died

enum State { WANDER, CHASE, WINDUP, LUNGE, HURT, DEAD }

const WANDER_SPEED := 22.0
const CHASE_SPEED := 46.0
const LUNGE_SPEED := 135.0
const WINDUP_TIME := 0.35
const LUNGE_TIME := 0.28
const HURT_TIME := 0.22

const HITSTOP_TIME := 0.1  # gel à l'impact : lisibilité du coup

var hp := 3
var state := State.WANDER
var _state_timer := 0.0
var _hitstop := 0.0
var _wander_dir := Vector2.ZERO
var _knockback := Vector2.ZERO
var _lunge_dir := Vector2.ZERO
var _target: Node2D = null

@onready var anim: AnimatedSprite2D = $Anim
@onready var detect: Area2D = $Detect
@onready var hitbox: Area2D = $HitBox


func _ready() -> void:
	add_to_group("kobolds")
	anim.sprite_frames = SpriteFramesBuilder.build("kobold")
	anim.play("idle_down")
	_pick_wander()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if _hitstop > 0.0:
		# hitstop : figé net (animation comprise) pendant l'encaissement
		_hitstop -= delta
		velocity = Vector2.ZERO
		anim.speed_scale = 0.0
		return
	anim.speed_scale = 1.0
	if GameState.dialogue_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_state_timer -= delta
	match state:
		State.WANDER:
			velocity = _wander_dir * WANDER_SPEED
			if _state_timer <= 0.0:
				_pick_wander()
			_look_for_player()
		State.CHASE:
			if not is_instance_valid(_target):
				state = State.WANDER
			else:
				var to_target := _target.global_position - global_position
				velocity = to_target.normalized() * CHASE_SPEED
				if to_target.length() < 26.0:
					_start_windup()
		State.WINDUP:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				state = State.LUNGE
				_state_timer = LUNGE_TIME
				velocity = _lunge_dir * LUNGE_SPEED
				# détente : le corps s'étire dans le bond puis revient
				anim.scale = Vector2(0.8, 1.2)
				create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
					.tween_property(anim, "scale", Vector2.ONE, LUNGE_TIME)
		State.LUNGE:
			velocity = _lunge_dir * LUNGE_SPEED
			if _state_timer <= 0.0:
				state = State.CHASE
		State.HURT:
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
			if _state_timer <= 0.0:
				state = State.CHASE if is_instance_valid(_target) else State.WANDER

	move_and_slide()
	_deal_contact_damage()
	_update_anim()


func _pick_wander() -> void:
	_state_timer = randf_range(0.8, 2.0)
	_wander_dir = Vector2.ZERO if randf() < 0.4 else Vector2.from_angle(randf() * TAU)


func _look_for_player() -> void:
	for body in detect.get_overlapping_bodies():
		if body is Player:
			_target = body
			state = State.CHASE
			FX.flash(anim, Color(2.0, 1.2, 1.2), 0.15)
			return


func _start_windup() -> void:
	state = State.WINDUP
	_state_timer = WINDUP_TIME
	_lunge_dir = (_target.global_position - global_position).normalized()
	FX.flash(anim, Color(2.5, 0.8, 0.8), WINDUP_TIME)
	# le kobold se ramasse sur lui-même avant de bondir
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim, "scale", Vector2(1.15, 0.82), WINDUP_TIME)


func _deal_contact_damage() -> void:
	for area in hitbox.get_overlapping_areas():
		var owner_node := area.get_owner()
		if owner_node is Player:
			owner_node.take_hit(1, global_position)


func take_hit(amount: int, from: Vector2, kb_strength := 170.0) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	state = State.HURT
	_hitstop = HITSTOP_TIME
	_state_timer = HURT_TIME
	_knockback = (global_position - from).normalized() * kb_strength
	Sfx.play("hit", -8.0)
	FX.flash(anim, Color(3.0, 1.0, 1.0), 0.15 + HITSTOP_TIME)
	if hp <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	FX.puff(get_parent(), global_position)
	if randf() < 0.5:
		FX.heart_drop(get_parent(), global_position)
	died.emit()
	queue_free()


func _update_anim() -> void:
	var v := velocity
	if v.length() < 2.0:
		var cur := String(anim.animation)
		if not cur.begins_with("idle"):
			anim.play("idle_" + cur.trim_prefix("walk_"))
		return
	var dir_name := "down"
	if absf(v.x) > absf(v.y):
		dir_name = "side"
		anim.flip_h = v.x < 0.0
	else:
		dir_name = "up" if v.y < 0.0 else "down"
		anim.flip_h = false
	anim.play("walk_" + dir_name)
