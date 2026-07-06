class_name SpriteFramesBuilder
## Construit les SpriteFrames à partir des PNG générés par
## tools/generate_sprites.py : <prefix>_<anim>_<dir>_<i>.png.
## idle = respiration (2 frames), walk = cycle avec rebond (4 frames),
## attack = armé / frappe / frappe accentuée / retour (4 frames, héros).

const DIRS := ["down", "up", "side"]


static func build(prefix: String, with_attack := false, walk_frames := 4) -> SpriteFrames:
	var sf := SpriteFrames.new()
	for dir in DIRS:
		_add_anim(sf, prefix, "idle", dir, 2, 2.0, true)
		_add_anim(sf, prefix, "walk", dir, walk_frames, 2.4 * walk_frames, true)
		if with_attack:
			# combo : balayage / revers / estoc (le finisher est un peu plus lent)
			_add_anim(sf, prefix, "attack", dir, 4, 18.0, false)
			_add_anim(sf, prefix, "attack2", dir, 4, 18.0, false)
			_add_anim(sf, prefix, "attack3", dir, 4, 14.0, false)
	sf.remove_animation("default")
	return sf


static func _add_anim(sf: SpriteFrames, prefix: String, anim: String, dir: String,
		count: int, fps: float, loop: bool) -> void:
	var anim_name := "%s_%s" % [anim, dir]
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i in range(count):
		sf.add_frame(anim_name, load("res://assets/sprites/%s_%s_%s_%d.png" % [prefix, anim, dir, i]))
