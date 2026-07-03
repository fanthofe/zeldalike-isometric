extends Node
## Autoload : état global du jeu (vie, éveil des esprits, progression).

signal hp_changed(hp: int, max_hp: int)
signal spirits_changed
signal player_died

const MAX_HP := 4

var hp := MAX_HP
var green_awake := false   # Rongo, esprit de la nature (soin)
var red_awake := false     # Ahi, esprit du feu (projectile)
var intro_done := false
var dialogue_active := false


func reset_run() -> void:
	hp = MAX_HP
	hp_changed.emit(hp, MAX_HP)


func damage(amount: int = 1) -> void:
	hp = clampi(hp - amount, 0, MAX_HP)
	hp_changed.emit(hp, MAX_HP)
	if hp == 0:
		player_died.emit()


func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, MAX_HP)
	hp_changed.emit(hp, MAX_HP)


func awaken_green() -> void:
	green_awake = true
	spirits_changed.emit()


func awaken_red() -> void:
	red_awake = true
	spirits_changed.emit()
