# Kaimana : L'Île des Esprits Silencieux

Zelda-like 2D en pixel art (style *The Minish Cap*) réalisé avec **Godot 4.3+**.

## Le jeu

**Pitch** : Kaimana, prince guerrier polynésien (inspiré de Maui dans Vaiana), rentre
sur son île de **Motu Ora** après son rituel de passage. Mais il ne perçoit plus la
présence des esprits tribaux : les deux orbes de son crochet d'ivoire — **Rongo**
(orbe verte, esprit de la nature, soin) et **Ahi** (orbe rouge, esprit du feu,
projectile) — sont éteintes. À son arrivée, il est attaqué par des **kobolds**
(mi-loups mi-hommes, le clan des Crocs-Parjures, traîtres au serment de son clan).
Après les avoir repoussés, l'orbe verte frémit : les esprits sont retenus
prisonniers par les totems de l'île.

**Boucle de gameplay** (à la Minish Cap) : déplacement 8 directions, attaque au
crochet en arc, roulade avec invincibilité, cœurs de vie, ennemis à IA
(errance → poursuite → charge), pouvoirs d'orbes à débloquer.

## Commandes

| Action | Touches |
|---|---|
| Déplacement | ZQSD / WASD (position physique) ou flèches |
| Attaque crochet | X ou J |
| Roulade | C, K ou Espace |
| Orbe verte (soin, une fois éveillée) | E |
| Orbe rouge (boule de feu, une fois éveillée) | R |
| Dialogue / confirmer | Entrée ou X |

## Lancer le jeu

Ouvrir le projet dans Godot 4.3+ (`project.godot`), ou en CLI :

```bash
godot --path .                      # lance la scène principale (écran titre)
godot --headless --path . --import  # (ré)importe les assets sans ouvrir l'éditeur
```

Le rendu utilise **Forward+** avec `viewport/hdr_2d=true` : le glow 2D
(WorldEnvironment dans `island.tscn`) fait briller tout ce qui a un
`modulate` > 1.0 (orbes, effets).

## Architecture

```
assets/sprites/         PNG générés par tools/generate_sprites.py (héros, kobolds, orbes)
assets/external/ninja/  extraits du pack CC0 « Ninja Adventure » (tuiles, FX, UI, audio)
scenes/                 title, island, player, kobold, orb, fireball (.tscn minimalistes)
scripts/                logique GDScript ; le maximum est construit en code
tools/                  générateur de sprites (Python/PIL) + scène de capture de test
```

Choix structurants :

- **`scripts/game_state.gd`** : autoload `GameState` — PV, éveil des esprits
  (`green_awake` / `red_awake`), `dialogue_active`, signaux (`hp_changed`,
  `spirits_changed`, `player_died`). Autoload `Sfx` (`scripts/sfx.gd`) pour les sons.
- **La carte est une chaîne ASCII** dans `scripts/island.gd` (const `MAP`,
  légende en tête de fichier). Le `TileSet` (2 sources atlas : `field.png` sols,
  `water.png` océan/rivage + collisions) est construit **en code au runtime** —
  il n'y a pas de `.tres`. Important : la source atlas doit être ajoutée au
  TileSet (`add_source`) **avant** de définir les polygones de collision.
- **Les décors** (palmier, totem-statue, rochers, buissons) sont des
  `StaticBody2D` + `AtlasTexture` découpés dans `nature.png`/`desert.png`
  (régions px dans la const `PROPS` d'`island.gd`).
- **Les `SpriteFrames` sont construits en code** (`sprite_frames_builder.gd`)
  à partir des PNG `<prefix>_<anim>_<dir>_<i>.png` → `idle_<dir>` (2 frames,
  respiration), `walk_<dir>` (4 frames avec rebond), `attack_<dir>` (4 frames,
  héros : armé → frappe → frappe accentuée → retour), dir ∈ down/up/side
  (side = droite, `flip_h` pour la gauche). Les frames sont composées par
  calques (tête/torse/jambes + décalages + poing) dans `generate_sprites.py`.
  Fluidité complétée en code par du **squash & stretch** en tween :
  roulade du héros, ramassé/détente du bond kobold.
- **Le crochet n'est pas une frame d'animation** : c'est un `Sprite2D` sous
  `HookPivot` (Node2D) dont la rotation est animée en tween pendant l'attaque ;
  la hitbox est un `Area2D` sondé par `get_overlapping_bodies()` pendant le swing.
- **Couches physiques** : 1 = monde (tuiles solides, décors), 2 = joueur,
  3 (val. 4) = ennemis. Dégâts au contact : `HitBox` du kobold (mask 2) sonde la
  `HurtBox` du joueur chaque frame physique.
- L'UI (HUD, boîte de dialogue, écran titre) est **construite en code** dans
  `_ready()` — les `.tscn` ne portent que la structure minimale.
- Les kobolds sont dans le groupe `"kobolds"` ; l'île compte les morts via le
  signal `died` pour déclencher la séquence de victoire.

## Direction artistique

Style Minish Cap + île tropicale « glow » (recherches Pinterest/Lospec) :

- Proportions **chibi** (tête ≈ moitié du corps), sprites 16×24, tuiles 16×16.
- Contours **sombres et chauds** (`#2b1a12`), jamais noir pur.
- Environnement/FX/UI/audio : pack **CC0 « Ninja Adventure »** (pixel-boy),
  extraits dans `assets/external/ninja/` (licence et attribution incluses).
  Le pack complet (94 Mo, 60+ monstres, donjons, musiques) n'est PAS commité —
  le retélécharger depuis itch.io si besoin d'autres éléments.
- Glow : `PointLight2D` avec `glow.png` (halo radial) + `modulate` HDR > 1.0.
- Personnages custom (héros, kobolds) : palette `PAL` de `tools/generate_sprites.py`.

### Récupérer des références et des assets

- **Pinterest** : la recherche et les boards exigent une connexion, mais les
  pages de **pins individuels** (`pinterest.com/pin/<id>/`) exposent les URLs
  directes `i.pinimg.com/736x/...` qui se téléchargent sans authentification
  (WebFetch de la page du pin → URL image → curl → analyse visuelle).
- **itch.io** (téléchargement CLI d'un pack gratuit) : avec cookies de session,
  1) GET la page du jeu (cookie jar + csrf_token), 2) POST `<jeu>/download_url`
  → URL signée, 3) GET cette URL → page listant les `data-upload_id`,
  4) POST `<jeu>/file/<upload_id>` → JSON avec l'URL CDN du zip.
  Toujours vérifier `LICENSE.txt` et ne copier dans le repo que les fichiers
  utilisés + licence + attribution.

### Régénérer les sprites custom

```bash
python3 tools/generate_sprites.py        # nécessite Pillow
godot --headless --path . --import       # OBLIGATOIRE avant un run CLI
```

Les personnages sont des grilles ASCII dans le script (une lettre = une couleur
de `PAL`) ; `preview.png` est une planche contact de contrôle. Ces sprites sont
des **placeholders** destinés à être remplacés par de vrais assets.

## Tester / vérifier

```bash
# valider les scripts sans affichage (les erreurs de parse sortent ici)
godot --headless --path . res://scenes/island.tscn --quit-after 300

# partie automatisée avec captures d'écran (intro → combat → victoire)
godot --path . res://tools/capture.tscn   # écrit shot_*.png (chemin dans capture.gd)
```

`tools/capture.gd` simule les entrées (`Input.parse_input_event` /
`Input.action_press`) : dialogue, déplacement, attaque, mise à mort des kobolds,
puis capture la séquence de victoire (éveil de l'orbe verte).

## Conventions

- GDScript **typé** (`:=`, annotations), indentation tabulations.
- Attention : pas de constantes typées `Array[String]`/`PackedStringArray`
  (limites GDScript 4.3) — utiliser `const X := [...]` non typé.
- Textes du jeu et commentaires **en français**.
- Ne pas committer `.godot/` (cache d'import).

## Roadmap (non implémenté)

- Éveil d'Ahi (orbe rouge) : donjon/totem à libérer, boss kobold.
- Objets à la Minish Cap (grappin avec le crochet, rétrécissement ?).
- Village, PNJ, quêtes (le pack Ninja Adventure contient maisons, PNJ, donjons).
- Vrais sprites pour Kaimana et les kobolds (seuls persos encore en placeholder) ;
  le pack n'a pas de loup-garou, d'où les kobolds custom conservés.
- Eau animée (dossier `Backgrounds/Animated` du pack).
