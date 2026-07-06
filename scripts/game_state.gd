extends Node
## Autoload : état global du jeu (vie, éveil des esprits, progression).

signal hp_changed(hp: int, max_hp: int)
signal spirits_changed
signal player_died
signal essence_changed(amount: int)
signal skills_changed

const MAX_HP := 4

var hp := MAX_HP
var green_awake := false   # Rongo, esprit de la nature (soin)
var red_awake := false     # Ahi, esprit du feu (projectile)
var intro_done := false
var dialogue_active := false

## Arbre de compétences (docs/arbre-competences.md).
var essence := 6                        # essence spirituelle ✦ (6 de départ)
var skills := {"balayage": true}        # id -> débloqué


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


# ------------------------------------------------------ arbre de compétences

## Les éveils d'esprits sont des dons d'histoire : mappés sur l'état narratif.
func has_skill(id: String) -> bool:
	match id:
		"eveil_rongo":
			return green_awake
		"eveil_ahi":
			return red_awake
		_:
			return skills.get(id, false)


func add_essence(amount: int) -> void:
	essence += amount
	essence_changed.emit(essence)


func unlock_skill(id: String, cost: int) -> bool:
	if has_skill(id) or essence < cost:
		return false
	essence -= cost
	skills[id] = true
	essence_changed.emit(essence)
	skills_changed.emit()
	return true
