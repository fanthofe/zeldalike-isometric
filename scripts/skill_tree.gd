class_name SkillTree
## Définitions statiques de l'arbre de compétences « Les Dons des Esprits ».
## Design complet : docs/arbre-competences.md. `impl` = câblé dans le gameplay ;
## les autres apparaissent dans le menu comme « Bientôt disponible ».

const BRANCHES := [
	{"nom": "Crochet d'Ivoire", "couleur": Color(0.95, 0.85, 0.55)},
	{"nom": "Rongo — Nature", "couleur": Color(0.5, 0.9, 0.55)},
	{"nom": "Ahi — Feu", "couleur": Color(1.0, 0.55, 0.4)},
]

const HOOK_ICON := "res://assets/sprites/hook.png"
const GREEN_ICON := "res://assets/sprites/orb_green.png"
const RED_ICON := "res://assets/sprites/orb_red.png"

const SKILLS := [
	# --- Branche 0 : Crochet d'Ivoire -------------------------------------
	{"id": "balayage", "branche": 0, "nom": "Balayage", "type": "combo",
		"cout": 0, "prereq": "", "impl": true, "icone": HOOK_ICON,
		"desc": "Premier coup du combo : large arc de crochet devant Kaimana."},
	{"id": "revers", "branche": 0, "nom": "Revers du Guerrier", "type": "combo",
		"cout": 2, "prereq": "balayage", "impl": true, "icone": HOOK_ICON,
		"desc": "Deuxième coup : revers en arc inverse, enchaînable au buffer après le Balayage."},
	{"id": "estoc", "branche": 0, "nom": "Estoc du Requin", "type": "combo",
		"cout": 4, "prereq": "revers", "impl": true, "icone": HOOK_ICON,
		"desc": "Finisher : estoc à deux mains. Dégâts doublés, gros recul, secousse d'écran."},
	{"id": "poigne", "branche": 0, "nom": "Poigne Ferme", "type": "passif",
		"cout": 3, "prereq": "balayage", "impl": true, "icone": HOOK_ICON,
		"desc": "La projection des coups est augmentée de 20 %."},
	{"id": "danse", "branche": 0, "nom": "Danse du Guerrier", "type": "passif",
		"cout": 5, "prereq": "estoc", "impl": true, "icone": HOOK_ICON,
		"desc": "Récupération après l'Estoc du Requin réduite de moitié."},
	{"id": "cyclone", "branche": 0, "nom": "Cyclone Marin", "type": "actif",
		"cout": 6, "prereq": "estoc", "impl": false, "icone": HOOK_ICON,
		"desc": "Maintenir X : attaque chargée tournoyante à 360° qui repousse tous les ennemis."},
	# --- Branche 1 : Rongo -------------------------------------------------
	{"id": "eveil_rongo", "branche": 1, "nom": "Éveil de Rongo", "type": "actif",
		"cout": 0, "prereq": "", "impl": true, "icone": GREEN_ICON,
		"desc": "Don d'histoire. Soin de Rongo (E) : restaure 1 cœur, recharge 6 s."},
	{"id": "seve", "branche": 1, "nom": "Sève Vive", "type": "passif",
		"cout": 3, "prereq": "eveil_rongo", "impl": true, "icone": GREEN_ICON,
		"desc": "Le soin de Rongo restaure un cœur supplémentaire."},
	{"id": "ecorce", "branche": 1, "nom": "Peau d'Écorce", "type": "passif",
		"cout": 5, "prereq": "seve", "impl": false, "icone": GREEN_ICON,
		"desc": "L'écorce des banians durcit la peau : +1 cœur maximum."},
	{"id": "lianes", "branche": 1, "nom": "Bouclier de Lianes", "type": "actif",
		"cout": 7, "prereq": "ecorce", "impl": false, "icone": GREEN_ICON,
		"desc": "Un bouclier végétal absorbe le prochain coup reçu (recharge 10 s)."},
	{"id": "etreinte", "branche": 1, "nom": "Étreinte de la Forêt", "type": "actif",
		"cout": 9, "prereq": "lianes", "impl": false, "icone": GREEN_ICON,
		"desc": "Des racines jaillissent et immobilisent les ennemis proches pendant 2 s."},
	# --- Branche 2 : Ahi ---------------------------------------------------
	{"id": "eveil_ahi", "branche": 2, "nom": "Éveil d'Ahi", "type": "actif",
		"cout": 0, "prereq": "", "impl": true, "icone": RED_ICON,
		"desc": "Don d'histoire. Souffle d'Ahi (R) : boule de feu, recharge 0,8 s."},
	{"id": "braises", "branche": 2, "nom": "Braises", "type": "passif",
		"cout": 3, "prereq": "eveil_ahi", "impl": false, "icone": RED_ICON,
		"desc": "La boule de feu enflamme sa cible : 1 dégât par seconde pendant 2 s."},
	{"id": "fournaise", "branche": 2, "nom": "Double Fournaise", "type": "passif",
		"cout": 5, "prereq": "braises", "impl": false, "icone": RED_ICON,
		"desc": "Le souffle d'Ahi projette deux boules de feu en éventail."},
	{"id": "ruee", "branche": 2, "nom": "Ruée Ardente", "type": "actif",
		"cout": 7, "prereq": "braises", "impl": false, "icone": RED_ICON,
		"desc": "La roulade s'enflamme et blesse les ennemis traversés."},
	{"id": "volcan", "branche": 2, "nom": "Colère du Volcan", "type": "actif",
		"cout": 10, "prereq": "ruee", "impl": false, "icone": RED_ICON,
		"desc": "Nova de feu autour de Kaimana : lourds dégâts de zone, longue recharge."},
]


static func branch_skills(branch: int) -> Array:
	var out := []
	for def in SKILLS:
		if def.branche == branch:
			out.append(def)
	return out


static func get_def(id: String) -> Dictionary:
	for def in SKILLS:
		if def.id == id:
			return def
	return {}
