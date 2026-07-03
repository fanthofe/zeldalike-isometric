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


func _start_music() -> void:
	var music := AudioStreamPlayer.new()
	music.stream = load("res://assets/external/ninja/audio/music_sunny.ogg")
	music.stream.loop = true
	music.volume_db = -10.0
	add_child(music)
	music.play()


func _setup_camera() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(MAP[0].length()) * TILE
	cam.limit_bottom = MAP.size() * TILE
