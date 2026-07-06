extends Node
## Autoload : lecture simple des effets sonores (pack CC0 Ninja Adventure).

const SOUNDS := {
	"slash": "res://assets/external/ninja/audio/sfx_slash.wav",
	"hit": "res://assets/external/ninja/audio/sfx_hit.wav",
	"hurt": "res://assets/external/ninja/audio/sfx_hurt.wav",
	"pickup": "res://assets/external/ninja/audio/sfx_pickup.wav",
}


func play(sound_name: String, volume_db := -4.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load(SOUNDS[sound_name])
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()
