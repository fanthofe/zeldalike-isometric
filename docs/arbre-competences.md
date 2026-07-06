# Arbre de compétences — « Les Dons des Esprits »

> Document de game design — Kaimana : L'Île des Esprits Silencieux.
> Statuts : ✅ implémenté · 🔜 proposition (à implémenter dans une itération future).

## Vision

Kaimana reconquiert les faveurs des esprits de Motu Ora. Chaque esprit libéré
et chaque ennemi vaincu abandonne de l'**essence spirituelle** ✦, que Kaimana
dépense pour raviver les *Dons* gravés dans son crochet d'ivoire. L'arbre
matérialise la progression du prince : guerrier d'abord, puis réceptacle des
esprits de la nature (Rongo) et du feu (Ahi).

Principes :

- **3 branches** courtes et lisibles (5-6 nœuds), pas de labyrinthe.
- Chaque branche mélange **combos**, **actifs** (déclenchés par une touche)
  et **passifs** (toujours actifs une fois débloqués).
- Les éveils de Rongo et d'Ahi restent **scénarisés** (récompenses d'histoire) ;
  l'arbre les prolonge mais ne les remplace pas.

## Ressource : l'essence spirituelle ✦

| Source | Gain |
|---|---|
| Kobold vaincu | +1 ✦ (mote lumineuse à ramasser) |
| Totem libéré (futur donjon) | +3 ✦ |
| Quêtes de PNJ (futur village) | variable |

L'essence est conservée entre les morts (l'esprit de Kaimana apprend, même
dans la défaite). Le joueur démarre avec **6 ✦** pour découvrir le système.

## Branche I — Crochet d'Ivoire (combat)

| # | Compétence | Type | Coût | Prérequis | Effet | Statut |
|---|---|---|---|---|---|---|
| C1 | **Balayage** | combo | — | — | 1er coup : arc de crochet devant Kaimana. | ✅ (de base) |
| C2 | **Revers du Guerrier** | combo | 2 ✦ | C1 | 2e coup : revers en arc inverse, enchaînable au buffer. | ✅ |
| C3 | **Estoc du Requin** | combo | 4 ✦ | C2 | Finisher : estoc à deux mains, dégâts ×2, gros recul, secousse d'écran. | ✅ |
| C4 | **Poigne Ferme** | passif | 3 ✦ | C1 | Projection des coups +20 %. | ✅ |
| C5 | **Danse du Guerrier** | passif | 5 ✦ | C3 | Récupération après le finisher réduite de moitié. | ✅ |
| C6 | **Cyclone Marin** | actif | 6 ✦ | C3 | Maintenir X : attaque chargée tournoyante à 360°, repousse tout. | 🔜 |

**Le combo (rappel des inputs)** : X → X → X (buffer accepté pendant chaque
coup ; fenêtre de 0,35 s entre deux coups ; roulade = annulation).
Sans C2/C3, le combo s'arrête au coup maîtrisé — l'arbre redonne au joueur
la montée en puissance du prologue.

## Branche II — Rongo, esprit de la nature 🌿

| # | Compétence | Type | Coût | Prérequis | Effet | Statut |
|---|---|---|---|---|---|---|
| R1 | **Éveil de Rongo** | actif | *histoire* | — | Soin (touche E) : restaure 1 cœur, recharge 6 s. | ✅ (scénarisé) |
| R2 | **Sève Vive** | passif | 3 ✦ | R1 | Le soin restaure 1 cœur de plus. | ✅ |
| R3 | **Peau d'Écorce** | passif | 5 ✦ | R2 | +1 cœur maximum. | 🔜 |
| R4 | **Bouclier de Lianes** | actif | 7 ✦ | R3 | Un bouclier végétal absorbe le prochain coup (recharge 10 s). | 🔜 |
| R5 | **Étreinte de la Forêt** | actif | 9 ✦ | R4 | Des racines immobilisent les ennemis proches 2 s. | 🔜 |

## Branche III — Ahi, esprit du feu 🔥

| # | Compétence | Type | Coût | Prérequis | Effet | Statut |
|---|---|---|---|---|---|---|
| A1 | **Éveil d'Ahi** | actif | *histoire* | — | Boule de feu (touche R), recharge 0,8 s. | ✅ (scénarisé) |
| A2 | **Braises** | passif | 3 ✦ | A1 | La boule de feu enflamme : 1 dégât/s pendant 2 s. | 🔜 |
| A3 | **Double Fournaise** | passif | 5 ✦ | A2 | Deux projectiles en éventail. | 🔜 |
| A4 | **Ruée Ardente** | actif | 7 ✦ | A2 | La roulade s'enflamme et blesse les ennemis traversés. | 🔜 |
| A5 | **Colère du Volcan** | actif | 10 ✦ | A4 | Nova de feu autour de Kaimana (gros dégâts de zone, longue recharge). | 🔜 |

## Le menu de compétences

Ouverture : **Tab** (ou **M**), n'importe quand hors dialogue. Le jeu se met
en pause (la musique continue).

```
┌──────────────────────────────────────────────────────────┐
│  LES DONS DES ESPRITS                       Essence : 6 ✦ │
│                                                          │
│  Crochet d'Ivoire     Rongo — Nature      Ahi — Feu      │
│  ┌────────────┐       ┌────────────┐      ┌────────────┐ │
│  │⚓ Balayage  │       │🌿 Éveil     │      │🔥 Éveil     │ │
│  │⚓ Revers    │       │🌿 Sève Vive │      │🔥 Braises   │ │
│  │⚓ Estoc     │       │🌿 Écorce    │      │🔥 Fournaise │ │
│  │⚓ Poigne    │       │🌿 Lianes    │      │🔥 Ruée      │ │
│  │⚓ Danse     │       │🌿 Étreinte  │      │🔥 Volcan    │ │
│  │⚓ Cyclone   │       └────────────┘      └────────────┘ │
│  └────────────┘                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ REVERS DU GUERRIER — combo                           ││
│  │ Revers en arc inverse, enchaînable après le Balayage.││
│  │ Entrée : débloquer (2 ✦)                             ││
│  └──────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

- **Navigation** : flèches / ZQSD (haut-bas dans une branche, gauche-droite
  entre branches) · **Entrée** : débloquer · **Tab / Échap** : fermer.
- **États visuels** : débloqué (couleur de branche), disponible (bordure
  blanche, coût affiché), verrouillé (grisé + prérequis), sélection (bordure
  dorée). Les 🔜 affichent « Bientôt disponible ».

## Architecture technique

| Fichier | Rôle |
|---|---|
| `scripts/skill_tree.gd` | Définitions statiques (`SKILLS`, `BRANCHES`) : id, nom, type, coût, prérequis, description, icône, `impl`. |
| `scripts/skill_menu.gd` | UI du menu (CanvasLayer construit en code, `process_mode = ALWAYS`, pause du jeu). |
| `scripts/game_state.gd` | `essence`, `skills` (déblocages), signaux `essence_changed` / `skills_changed` ; les éveils R1/A1 sont mappés sur `green_awake`/`red_awake`. |
| `scripts/player.gd` | Lecture des compétences : plafond de combo (C2/C3), knockback (C4), récupération (C5), soin amélioré (R2). |
| `scripts/kobold.gd` + `scripts/fx.gd` | Drop d'essence à la mort (mote cyan lumineuse). |

## Phases suivantes proposées

1. **Phase 2 (feu)** : câbler Braises, Double Fournaise, Ruée Ardente — le
   donjon d'Ahi devient le terrain de jeu de la branche feu.
2. **Phase 3 (nature)** : Peau d'Écorce (cœurs max dynamiques dans le HUD),
   Bouclier de Lianes, Étreinte de la Forêt.
3. **Cyclone Marin** : attaque chargée (maintenir X), nouvelle anim tournoyante
   du générateur de sprites.
4. **Équilibrage** : coûts à ajuster selon la densité d'ennemis des futures
   zones ; envisager un respec gratuit auprès d'un totem libéré.
