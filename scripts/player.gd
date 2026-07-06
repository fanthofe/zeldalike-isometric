class_name Player
extends CharacterBody2D
## Kaimana, prince guerrier de Motu Ora. Déplacement 8 directions,
## attaque au crochet d'ivoire, roulade, pouvoirs des orbes-esprits.

enum State { MOVE, ATTACK, ROLL, HURT, DEAD }

const SPEED := 72.0
const ROLL_SPEED := 150.0
const ROLL_TIME := 0.28
const HURT_TIME := 0.25
const HEAL_COOLDOWN := 6.0
const FIREBALL_COOLDOWN := 0.8

const FIREBALL_SCENE := "res://scenes/fireball.tscn"

## Combo de 3 coups : balayage → revers → estoc (finisher).
## swing = [angle départ, angle arrivée] relatif au regard ; null = estoc.
const ATTACKS := [
	{"anim": "attack", "time": 0.22, "dmg": 1, "lunge": 55.0,
		"swing": [-1.3, 1.4], "pitch": 1.0, "kb": 170.0},
	{"anim": "attack2", "time": 0.22, "dmg": 1, "lunge": 75.0,
		"swing": [1.4, -1.3], "pitch": 1.15, "kb": 170.0},
	{"anim": "attack3", "time": 0.30, "dmg": 2, "lunge": 120.0,
		"swing": null, "pitch": 0.85, "kb": 280.0},
]
const COMBO_WINDOW := 0.35    # délai pour enchaîner après la fin d'un coup
const COMBO_COOLDOWN := 0.35  # récupération après le finisher

var state := State.MOVE
var facing := Vector2.DOWN
var controls_enabled := true

var _state_timer := 0.0
var _iframes := 0.0
var _heal_cd := 0.0
var _fire_cd := 0.0
var _knockback := Vector2.ZERO
var _hit_this_swing: Array[Node] = []
var _combo_stage := 0         # coup en cours / prochain coup à jouer
var _combo_window := 0.0
var _attack_cd := 0.0
var _attack_buffered := false

@onready var anim: AnimatedSprite2D = $Anim
@onready var hook_pivot: Node2D = $HookPivot
@onready var hook_sprite: Sprite2D = $HookPivot/Hook
@onready var hitbox: Area2D = $HookPivot/HitBox
@onready var camera: Camera2D = $Camera2D
@onready var orb_green: Node2D = $OrbGreen
@onready var orb_red: Node2D = $OrbRed


func _ready() -> void:
	anim.sprite_frames = SpriteFramesBuilder.build("hero", true, 6)
	anim.play("idle_down")
	hook_pivot.visible = false
	GameState.player_died.connect(_die)


func _physics_process(delta: float) -> void:
	_iframes = maxf(_iframes - delta, 0.0)
	_heal_cd = maxf(_heal_cd - delta, 0.0)
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if state != State.ATTACK:
		_combo_window = maxf(_combo_window - delta, 0.0)
		if _combo_window == 0.0:
			_combo_stage = 0  # fenêtre expirée : le combo repart du premier coup

	match state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.ROLL:
			_process_roll(delta)
		State.HURT:
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, 500.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.MOVE
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	_update_anim()


func _process_move(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled and not GameState.dialogue_active:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	if input.length() > 0.1:
		facing = input.normalized()

	if not controls_enabled or GameState.dialogue_active:
		return
	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		if _combo_window <= 0.0:
			_combo_stage = 0
		_start_attack()
	elif Input.is_action_just_pressed("roll"):
		_start_roll()
	elif Input.is_action_just_pressed("orb_green"):
		_use_green()
	elif Input.is_action_just_pressed("orb_red"):
		_use_red()


func _start_attack() -> void:
	var spec: Dictionary = ATTACKS[_combo_stage]
	state = State.ATTACK
	_state_timer = spec.time
	_hit_this_swing.clear()
	_attack_buffered = false
	velocity = facing * spec.lunge
	anim.play(spec.anim + "_" + _facing_name())
	hook_pivot.visible = true
	var base := facing.angle()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if spec.swing == null:
		# estoc : le crochet jaillit devant puis revient
		hook_pivot.rotation = base
		hook_sprite.position = Vector2(5, 0)
		tw.tween_property(hook_sprite, "position:x", 18.0, spec.time * 0.45)
		tw.tween_property(hook_sprite, "position:x", 12.0, spec.time * 0.55)
	else:
		hook_sprite.position = Vector2(12, 0)
		hook_pivot.rotation = base + spec.swing[0]
		tw.tween_property(hook_pivot, "rotation", base + spec.swing[1], spec.time)
	tw.tween_callback(func() -> void: hook_pivot.visible = false)
	Sfx.play("slash", -4.0, spec.pitch)
	FX.slash(get_parent(), global_position + facing * 14.0 + Vector2(0, -4),
			base + PI / 2.0, _combo_stage == 1, 1.0 if _combo_stage < 2 else 1.4)


func _process_attack(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	if controls_enabled and not GameState.dialogue_active:
		if Input.is_action_just_pressed("attack"):
			_attack_buffered = true  # mise en file du coup suivant : enchaînement fluide
		elif Input.is_action_just_pressed("roll"):
			# la roulade annule le combo (réactivité défensive)
			hook_pivot.visible = false
			_combo_stage = 0
			_combo_window = 0.0
			_start_roll()
			return
	var spec: Dictionary = ATTACKS[_combo_stage]
	var kb: float = spec.kb * (1.2 if GameState.has_skill("poigne") else 1.0)
	for body in hitbox.get_overlapping_bodies():
		if body != self and not _hit_this_swing.has(body) and body.has_method("take_hit"):
			_hit_this_swing.append(body)
			body.take_hit(spec.dmg, global_position, kb)
			if _combo_stage == ATTACKS.size() - 1:
				_shake_camera()
	_state_timer -= delta
	if _state_timer <= 0.0:
		_end_attack()


## Dernier coup de combo maîtrisé (arbre de compétences).
func _max_combo_stage() -> int:
	if GameState.has_skill("estoc"):
		return 2
	if GameState.has_skill("revers"):
		return 1
	return 0


func _end_attack() -> void:
	state = State.MOVE
	if _combo_stage >= _max_combo_stage():
		# fin du combo : récupération (pleine après un finisher complet)
		var full_combo := _combo_stage == ATTACKS.size() - 1
		_combo_stage = 0
		_combo_window = 0.0
		var cd := COMBO_COOLDOWN if full_combo else 0.15
		_attack_cd = cd * (0.5 if full_combo and GameState.has_skill("danse") else 1.0)
		return
	_combo_stage += 1
	_combo_window = COMBO_WINDOW
	if _attack_buffered:
		_start_attack()


func _shake_camera() -> void:
	var tw := create_tween()
	for i in range(3):
		tw.tween_property(camera, "offset",
				Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)), 0.03)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.05)


func _start_roll() -> void:
	state = State.ROLL
	_state_timer = ROLL_TIME
	_iframes = ROLL_TIME
	velocity = facing * ROLL_SPEED
	# squash & stretch : le corps s'écrase au départ puis se détend
	anim.scale = Vector2(1.15, 0.78)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim, "scale", Vector2.ONE, ROLL_TIME)


func _process_roll(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		state = State.MOVE


func _use_green() -> void:
	if not GameState.green_awake or _heal_cd > 0.0 or GameState.hp >= GameState.MAX_HP:
		return
	_heal_cd = HEAL_COOLDOWN
	GameState.heal(2 if GameState.has_skill("seve") else 1)  # Sève Vive
	orb_green.pulse()
	FX.flash(anim, Color(0.6, 2.2, 0.8), 0.3)


func _use_red() -> void:
	if not GameState.red_awake or _fire_cd > 0.0:
		return
	_fire_cd = FIREBALL_COOLDOWN
	orb_red.pulse()
	var fb: Node2D = load(FIREBALL_SCENE).instantiate()
	fb.dir = facing
	fb.global_position = global_position + facing * 8.0 + Vector2(0, -8)
	get_parent().add_child(fb)


func pickup_heart() -> void:
	GameState.heal(1)
	Sfx.play("pickup", -10.0)
	FX.flash(anim, Color(2.0, 1.4, 1.4), 0.2)


func pickup_essence() -> void:
	GameState.add_essence(1)
	Sfx.play("pickup", -14.0, 1.5)
	FX.flash(anim, Color(1.2, 1.8, 2.2), 0.2)


func take_hit(amount: int, from: Vector2) -> void:
	if _iframes > 0.0 or state == State.DEAD or state == State.ROLL:
		return
	_iframes = 0.8
	state = State.HURT
	_state_timer = HURT_TIME
	_knockback = (global_position - from).normalized() * 140.0
	Sfx.play("hurt")
	FX.flash(anim, Color(3.0, 0.6, 0.6), 0.25)
	GameState.damage(amount)


func _die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	FX.puff(get_parent(), global_position)
	var tw := create_tween()
	tw.tween_property(anim, "modulate:a", 0.0, 0.8)
	tw.tween_interval(0.6)
	tw.tween_callback(func() -> void:
		GameState.reset_run()
		get_tree().reload_current_scene()
	)


func _facing_name() -> String:
	if absf(facing.x) > absf(facing.y):
		anim.flip_h = facing.x < 0.0
		return "side"
	anim.flip_h = false
	return "up" if facing.y < 0.0 else "down"


func _update_anim() -> void:
	if state == State.ATTACK:
		return  # l'animation d'attaque du corps joue jusqu'au bout
	var dir_name := _facing_name()
	var moving := velocity.length() > 5.0 and (state == State.MOVE or state == State.ROLL)
	anim.play(("walk_" if moving else "idle_") + dir_name)
