extends Node2D
## Motu Ora : construit l'île (tuiles + décors) à partir d'une carte ASCII,
## place Kaimana et les kobolds, et déroule la séquence d'introduction.

const TILE := 16
const KOBOLD_SCENE := preload("res://scenes/kobold.tscn")

## Légende :
##  . grass1   , grass2   s sand1   S sand2   p chemin
##  w eau      f écume    b buisson c falaise   (w f b c = solides)
##  P palmier  T totem    R rocher  K kobold   @ départ du joueur
const MAP := [
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	"wwwwwcccccccccccccccccccccccccccccwwwwww",
	"wwwwwc,...P.......,......,....P..cwwwwww",
	"wwwwwc...........................cwwwwww",
	"wwwwwc..R....,...T...T.....,...R.cwwwwww",
	"wwwwwc...........................cwwwwww",
	"wwwwwc....,....K......K....,.....cwwwwww",
	"wwwwwc..........,pp,.............cwwwwww",
	"wwwwwc..P.......pp........,....P.cwwwwww",
	"wwwwwc.....K....pp....K..........cwwwwww",
	"wwwwwc..........pp...............cwwwwww",
	"wwwwwc..,.......pp.......,.......cwwwwww",
	"wwwwwc....bb....pp....bb.........cwwwwww",
	"wwwwwc...bbb....pp....bbb....,...cwwwwww",
	"wwwwwc..........pp...............cwwwwww",
	"wwwwwcccccccccc.pp.cccccccccccccccwwwwww",
	"wwwwsssssssssss.@p.ssssssssssssssswwwwww",
	"wwwwsSssssRssss..ssssssSsssssRsssswwwwww",
	"wwwssssSssssssssssssssssssssssSssssswwww",
	"wwwfffffffffffffffffffffffffffffffffwwww",
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
]

## Tuiles du pack CC0 Ninja Adventure : [id de source atlas, coordonnées].
## Source 0 = field.png (sols pleins), source 1 = water.png (océan + rivage).
const ATLAS := {
	".": [0, Vector2i(4, 3)], ",": [0, Vector2i(3, 4)],
	"s": [0, Vector2i(3, 0)], "S": [0, Vector2i(3, 0)],
	"p": [0, Vector2i(3, 9)],
	"w": [1, Vector2i(1, 1)], "f": [1, Vector2i(1, 0)],
}
const SOLID := "wf"

const NATURE := "res://assets/external/ninja/nature.png"
const DESERT := "res://assets/external/ninja/desert.png"

## Décors : [texture, région (px), rayon de collision, décalage de collision].
const PROPS := {
	"P": [DESERT, Rect2(160, 62, 64, 50), 5.0, Vector2(0, -4)],   # palmier
	"T": [DESERT, Rect2(0, 96, 32, 48), 7.0, Vector2(0, -6)],     # totem (statue)
	"R": [NATURE, Rect2(272, 128, 16, 16), 5.0, Vector2(0, -3)],  # rocher
	"b": [NATURE, Rect2(0, 160, 16, 16), 6.0, Vector2(0, -4)],    # buisson touffe
	"c": [NATURE, Rect2(96, 160, 16, 16), 7.0, Vector2(0, -5)],   # haie de jungle
}

const INTRO_LINES := [
	"Kaimana : Enfin de retour... Le rituel du passage est accompli. Me voilà prince de Motu Ora.",
	"Kaimana : Rongo ? Ahi ? ... Pourquoi ce silence ?",
	"Kaimana : Les orbes de mon crochet sont éteintes. Je ne sens plus les esprits de l'île...",
	"??? : Grrrrr... Le petit prince est rentré de sa promenade !",
	"Kobold : Le clan des Crocs-Parjures réclame cette île, humain. Vos esprits ne vous protègent plus !",
	"Kaimana : Des kobolds ! Traîtres au serment de nos ancêtres... Approchez, et goûtez à mon crochet d'ivoire !",
]
const OUTRO_LINES := [
	"Kaimana : Fuyez, chiens galeux ! Et ne revenez plus rôder près du village !",
	"Kaimana : ... L'orbe verte... Elle frémit ?",
	"Rongo : (une voix lointaine) ... Kaimana... les totems... ils nous retiennent... libère-nous...",
	"Kaimana : Rongo ?! Tiens bon, vieil ami. Par les totems de Motu Ora, je vous rendrai à l'île !",
]

var _kobold_spawns: Array[Vector2] = []
var _kobolds_alive := 0
var _victory := false

@onready var ground: TileMapLayer = $Ground
@onready var actors: Node2D = $Actors
@onready var player: Player = $Actors/Player
@onready var dialogue: CanvasLayer = $Dialogue


func _ready() -> void:
	GameState.reset_run()
	# lumière tropicale : légère teinte dorée sur toute la scène
	var tint := CanvasModulate.new()
	tint.color = Color(1.0, 0.98, 0.92)
	add_child(tint)
	_build_world()
	_setup_camera()
	if not GameState.intro_done:
		player.controls_enabled = false
		dialogue.show_lines(INTRO_LINES, _on_intro_done)
	else:
		_spawn_kobolds()


func _on_intro_done() -> void:
	GameState.intro_done = true
	player.controls_enabled = true
	_spawn_kobolds()


func _spawn_kobolds() -> void:
	for pos in _kobold_spawns:
		var k := KOBOLD_SCENE.instantiate()
		actors.add_child(k)
		k.global_position = pos
		k.died.connect(_on_kobold_died)
		FX.puff(actors, pos)
		_kobolds_alive += 1


func _on_kobold_died() -> void:
	_kobolds_alive -= 1
	if _kobolds_alive <= 0 and not _victory:
		_victory = true
		await get_tree().create_timer(0.9).timeout
		player.orb_green.flicker()
		dialogue.show_lines(OUTRO_LINES, _on_outro_done)


func _on_outro_done() -> void:
	GameState.awaken_green()
	player.orb_green.pulse()


# ------------------------------------------------------------- construction

func _build_world() -> void:
	ground.tile_set = _build_tileset()
	var ripples := TileMapLayer.new()
	ripples.tile_set = ground.tile_set
	ripples.name = "Ripples"
	ripples.modulate = Color(1, 1, 1, 0.7)  # ondulations douces, fondues dans l'océan
	add_child(ripples)
	move_child(ripples, ground.get_index() + 1)
	var decor := Node2D.new()
	decor.name = "Decor"
	add_child(decor)
	move_child(decor, ripples.get_index() + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260706  # décor stable d'une partie à l'autre
	var width: int = MAP[0].length()
	for y in range(MAP.size()):
		var row: String = MAP[y]
		row = (row + "w".repeat(width)).substr(0, width)  # tolère les largeurs inégales
		for x in range(width):
			var ch := row[x]
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			var ground_ch := ch
			if not ATLAS.has(ch):
				ground_ch = "s" if y >= 17 else "."
			ground.set_cell(Vector2i(x, y), ATLAS[ground_ch][0], ATLAS[ground_ch][1])
			if ground_ch == "w" and rng.randf() < 0.3:
				ripples.set_cell(Vector2i(x, y), 2, Vector2i(0, 0))
			elif ch == "." or ch == ",":
				_scatter_decor(decor, pos, rng)
			if PROPS.has(ch):
				_add_prop(ch, pos + Vector2(0, TILE / 2.0))
			elif ch == "K":
				_kobold_spawns.append(pos)
			elif ch == "@":
				player.global_position = pos
	_start_music()


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # couche "world"
	# rattacher les sources avant create_tile : les TileData héritent des couches physiques
	_add_atlas_source(ts, 0, "res://assets/external/ninja/field.png")
	_add_atlas_source(ts, 1, "res://assets/external/ninja/water.png")
	_add_atlas_source(ts, 2, "res://assets/external/ninja/water_ripples.png")
	# tuile d'ondulations animée (4 frames horizontales, sans collision)
	var ripple_src := ts.get_source(2) as TileSetAtlasSource
	ripple_src.create_tile(Vector2i(0, 0))
	ripple_src.set_tile_animation_columns(Vector2i(0, 0), 4)
	ripple_src.set_tile_animation_frames_count(Vector2i(0, 0), 4)
	for f in range(4):
		ripple_src.set_tile_animation_frame_duration(Vector2i(0, 0), f, 0.35)
	var half := TILE / 2.0
	for ch: String in ATLAS:
		var src := ts.get_source(ATLAS[ch][0]) as TileSetAtlasSource
		var coords: Vector2i = ATLAS[ch][1]
		if src.has_tile(coords):
			continue  # tuile partagée par plusieurs symboles (ex : s et S)
		src.create_tile(coords)
		if SOLID.contains(ch):
			var td := src.get_tile_data(coords, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-half, -half), Vector2(half, -half),
				Vector2(half, half), Vector2(-half, half),
			]))
	return ts


func _add_atlas_source(ts: TileSet, id: int, path: String) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = load(path)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, id)


## Petit décor non bloquant dispersé sur l'herbe : touffes, fleurs, marguerite animée.
const TUFTS := [
	Rect2(112, 160, 16, 16),  # herbes hautes
	Rect2(0, 176, 16, 16),    # fleurs jaunes
	Rect2(48, 160, 16, 16),   # touffe ronde
]


func _scatter_decor(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	if roll < 0.035:
		# marguerite animée (4 frames qui ondulent)
		var s := AnimatedSprite2D.new()
		s.sprite_frames = FX.sheet_anim("res://assets/external/ninja/plant_daisy.png",
				Vector2i(16, 16), 4, rng.randf_range(3.0, 5.0), true)
		s.position = pos
		s.frame = rng.randi_range(0, 3)
		parent.add_child(s)
		s.play("anim")
	elif roll < 0.11:
		var s := Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = load(NATURE)
		at.region = TUFTS[rng.randi_range(0, TUFTS.size() - 1)]
		s.texture = at
		s.position = pos
		parent.add_child(s)


func _add_prop(ch: String, base_pos: Vector2) -> void:
	var def: Array = PROPS[ch]
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var at := AtlasTexture.new()
	at.atlas = load(def[0])
	at.region = def[1]
	var sprite := Sprite2D.new()
	sprite.texture = at
	sprite.offset = Vector2(0, -at.region.size.y / 2.0)
	body.add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = def[2]
	shape.shape = circle
	shape.position = def[3]
	body.add_child(shape)
	body.position = base_pos
	actors.add_child(body)
	if ch == "T":
		_haunt_totem(body, def[1].size.y)


## Halo ambré vacillant + lucioles-esprits autour d'un totem.
func _haunt_totem(totem: Node2D, sprite_height: float) -> void:
	var light := PointLight2D.new()
	light.texture = load("res://assets/sprites/glow.png")
	light.texture_scale = 0.6
	light.color = Color(1.0, 0.75, 0.4)
	light.energy = 0.5
	light.position = Vector2(0, -sprite_height * 0.55)
	totem.add_child(light)
	var tw := light.create_tween().set_loops()
	tw.tween_property(light, "energy", 0.75, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(light, "energy", 0.45, 1.3).set_trans(Tween.TRANS_SINE)

	var motes := CPUParticles2D.new()
	motes.amount = 6
	motes.lifetime = 4.0
	motes.preprocess = 4.0
	motes.texture = load("res://assets/sprites/glow.png")
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(24, 18)
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = 2.0
	motes.initial_velocity_max = 6.0
	motes.scale_amount_min = 0.04
	motes.scale_amount_max = 0.09
	motes.color = Color(1.6, 1.2, 0.5, 0.8)  # HDR : les motes participent au glow
	motes.position = Vector2(0, -sprite_height * 0.5)
	totem.add_child(motes)


func _start_music() -> void:
	var music := AudioStreamPlayer.new()
	music.stream = load("res://assets/external/ninja/audio/music_sunny.ogg")
	music.stream.loop = true
	music.volume_db = -10.0
	music.process_mode = Node.PROCESS_MODE_ALWAYS  # continue dans le menu pause
	add_child(music)
	music.play()


func _setup_camera() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(MAP[0].length()) * TILE
	cam.limit_bottom = MAP.size() * TILE
