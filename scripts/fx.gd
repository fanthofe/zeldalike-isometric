class_name FX
## Petits effets visuels créés à la volée (nuage de fumée, éclat, cœur à ramasser).


static func _sheet_anim(sheet_path: String, frame_size: Vector2i, count: int, fps: float) -> SpriteFrames:
	var sheet: Texture2D = load(sheet_path)
	var sf := SpriteFrames.new()
	sf.add_animation("anim")
	sf.set_animation_speed("anim", fps)
	sf.set_animation_loop("anim", false)
	for i in range(count):
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		sf.add_frame("anim", at)
	return sf


static func puff(parent: Node, pos: Vector2) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _sheet_anim("res://assets/external/ninja/smoke.png", Vector2i(32, 32), 6, 16.0)
	s.global_position = pos
	parent.add_child(s)
	s.play("anim")
	s.animation_finished.connect(s.queue_free)


static func slash(parent: Node, pos: Vector2, rot: float) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _sheet_anim("res://assets/external/ninja/slash.png", Vector2i(26, 32), 5, 28.0)
	s.global_position = pos
	s.rotation = rot
	parent.add_child(s)
	s.play("anim")
	s.animation_finished.connect(s.queue_free)


static func flash(node: CanvasItem, color := Color(3.0, 3.0, 3.0), time := 0.12) -> void:
	var tw := node.create_tween()
	node.modulate = color
	tw.tween_property(node, "modulate", Color.WHITE, time)


static func heart_drop(parent: Node, pos: Vector2) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2  # joueur
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/heart_full.png")
	area.add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	area.add_child(shape)
	area.global_position = pos
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("pickup_heart"):
			body.pickup_heart()
			area.queue_free()
	)
	parent.add_child(area)
	var tw := area.create_tween().set_loops()
	tw.tween_property(sprite, "position:y", -2.0, 0.4)
	tw.tween_property(sprite, "position:y", 0.0, 0.4)
