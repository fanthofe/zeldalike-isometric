#!/usr/bin/env python3
"""Générateur de sprites pixel art placeholder pour Kaimana.

Style visé : Zelda Minish Cap (contours sombres chauds, couleurs saturées,
proportions chibi) + palette tropicale avec accents lumineux (glow).
Régénérer : python3 tools/generate_sprites.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------- palette
PAL = {
    ".": None,
    "o": (43, 26, 18),      # contour chaud
    "h": (24, 18, 18),      # cheveux noirs bouclés
    "H": (58, 44, 42),      # reflet cheveux
    "s": (185, 119, 70),    # peau
    "S": (219, 160, 108),   # peau claire
    "d": (138, 79, 45),     # peau ombre
    "t": (84, 48, 32),      # tatouage tribal
    "g": (62, 137, 72),     # pagne feuilles
    "G": (110, 182, 100),   # feuilles claires
    "D": (38, 92, 51),      # feuilles sombres
    "e": (20, 14, 14),      # œil
    "w": (244, 231, 197),   # ivoire
    "W": (203, 181, 130),   # ivoire ombre
    "m": (245, 244, 236),   # blanc (dents / éclat)
    # kobold
    "f": (138, 132, 142),   # fourrure grise
    "F": (176, 168, 178),   # fourrure claire
    "k": (96, 90, 104),     # fourrure sombre
    "b": (168, 148, 128),   # ventre / museau
    "v": (226, 58, 48),     # yeux rouges
    "n": (30, 24, 30),      # truffe / griffes
    "c": (139, 90, 52),     # pagne cuir
    # environnement
    "T": (122, 74, 43),     # tronc
    "U": (158, 103, 62),    # tronc clair
    "L": (47, 158, 79),     # palme
    "l": (30, 112, 58),     # palme sombre
    "C": (108, 70, 40),     # noix de coco
    "A": (160, 95, 50),     # bois totem
    "a": (110, 62, 34),     # bois totem sombre
    "Y": (255, 214, 92),    # lueur jaune
    "R": (120, 113, 100),   # roche
    "r": (86, 80, 72),      # roche sombre
    "q": (150, 143, 128),   # roche claire
}


def img_from_map(rows, pal=PAL):
    w = len(rows[0])
    for i, r in enumerate(rows):
        assert len(r) == w, f"ligne {i}: largeur {len(r)} != {w}: {r!r}"
    im = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            col = pal[ch]
            if col is not None:
                px[x, y] = (*col, 255)
    return im


def save(im, name):
    im.save(OUT / f"{name}.png")
    return im

# ---------------------------------------------------------------- héros
# 16x24, ancré en bas. Proportions calquées sur assets/reference/
# sprite-linklike.jpg : tête ≈ 60 % du sprite, gros yeux sombres 2px bas
# sur le visage, bras détachés du torse (liseré), petites jambes.
# Identité Kaimana : afro à festons, collier + boucle d'ivoire, tatouages.

HERO_HEAD_DOWN = [
    "....oohhhhoo....",
    "..oohhhhhhhhoo..",
    ".ohhhhHHhhhhhho.",
    ".ohhHhhhhhhhhho.",
    "ohhhhhhhhhhhhhho",
    "ohhhhhhhhhhhhhho",
    "ohhossssssssohho",
    "ohhosessssesohho",
    "ohhoseSssSesohho",
    ".oohssssssshoo..",
    "...oosssssoo....",
]
HERO_HEAD_UP = [
    "....oohhhhoo....",
    "..oohhhhhhhhoo..",
    ".ohhhhHHhhhhhho.",
    ".ohhHhhhhhhhhho.",
    "ohhhhhhhhhhhhhho",
    "ohhhhhhhhhhhhhho",
    "ohhhhhhhhhhhhhho",
    "ohhhhhhhhhhhhhho",
    "ohhohhhhhhhhohho",
    ".oohhhhhhhhhoo..",
    "...oohhhhhoo....",
]
HERO_HEAD_SIDE = [  # regarde à droite
    "....oohhhhoo....",
    "..oohhhhhhhhoo..",
    ".ohhhhHHhhhhho..",
    ".ohhhhhhhhhhhho.",
    "ohhhhhhhhhhhhho.",
    "ohhhhhhhhosssso.",
    "ohhhhhhhosSseso.",
    "ohhhhhhhossseso.",
    ".ohhhhhhossssso.",
    ".ohhhhhhhsssso..",
    "..ohhhhhhssoo...",
]

HERO_BODY_DOWN = [
    ".oossssssssssoo.",
    ".ossowswswsosso.",
    ".ostossttssosto.",
    ".ossostsStsosso.",
    "..oggGggggGgo...",
    "..oDgDggggDgo...",
]
HERO_BODY_UP = [
    ".oossssssssssoo.",
    ".ossossssssosso.",
    ".ostosttttsosto.",
    ".ossossssssosso.",
    "..oggGggggGgo...",
    "..oDgDggggDgo...",
]
HERO_BODY_SIDE = [
    "...oossssssoo...",
    "...osssssosso...",
    "...ostsssosto...",
    "...osssssosso...",
    "...ogGgggGgo....",
    "...oDgDggDgo....",
]

# Colonnes des bras (à décaler pour le balancement de la marche).
HERO_ARMS = {
    "down": [(1, 4), (11, 14)],
    "up": [(1, 4), (11, 14)],
    "side": [(9, 12)],
}

# jambes : 0 repos, 1 appui gauche, 2 appui droit, 3 passage (serrées)
HERO_LEGS = {
    0: [
        "....oso..oso....",
        "....oso..oso....",
        "....odo..odo....",
        ".....o....o.....",
    ],
    1: [
        "...oso...oso....",
        "...oso...odo....",
        "...odo....o.....",
        "....o...........",
    ],
    2: [
        "....oso...oso...",
        "....odo...oso...",
        ".....o....odo...",
        "...........o....",
    ],
    3: [
        "....oso..oso....",
        "....oso..odo....",
        "....odo...o.....",
        ".....o..........",
    ],
}
HERO_LEGS_SIDE = {
    0: [
        "....oso.oso.....",
        "....oso.oso.....",
        "....odo.odo.....",
        ".....o...o......",
    ],
    1: [
        "...oso...oso....",
        "...oso....oso...",
        "...odo....odo...",
        "....o......o....",
    ],
    2: [
        ".....osooso.....",
        ".....osoodo.....",
        ".....odo.o......",
        "......o.........",
    ],
    3: [
        "....osooso......",
        "....osooso......",
        "....ododo.......",
        ".....o..o.......",
    ],
}


# ------------------------------------------------- composition des frames
# Chaque frame = calques (tête / torse / jambes) posés avec des décalages,
# ce qui permet rebond de marche, respiration et poses d'attaque.

def draw_fist(im, cx, cy):
    """Poing fermé 4x4 (contour + peau claire), dessiné par-dessus le calque."""
    d = ImageDraw.Draw(im)
    d.rectangle([cx - 1, cy - 1, cx + 2, cy + 2], fill=(*PAL["o"], 255))
    d.rectangle([cx, cy, cx + 1, cy + 1], fill=(*PAL["S"], 255))


def shift_columns(im, x0, x1, dy):
    """Décale verticalement une bande de colonnes (bras qui balancent)."""
    region = im.crop((x0, 0, x1 + 1, im.height))
    blank = Image.new("RGBA", region.size, (0, 0, 0, 0))
    im.paste(blank, (x0, 0))
    if dy < 0:
        region = region.crop((0, -dy, region.width, region.height))
        im.alpha_composite(region, (x0, 0))
    else:
        region = region.crop((0, 0, region.width, region.height - dy))
        im.alpha_composite(region, (x0, dy))


def build_frame(head, body, legs, ys, global_off=(0, 0), head_off=(0, 0),
                fist_at=None, arm_shift=None):
    """Assemble tête/torse/jambes (ancrées aux lignes `ys`) sur un canevas 16x24.

    `fist_at` : un (x, y) ou une liste de (x, y) — poings dessinés par-dessus.
    """
    tmp = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    ox, oy = 8, 4
    gx, gy = global_off
    body_img = img_from_map(body)
    if arm_shift:
        for (x0, x1), dy in arm_shift:
            shift_columns(body_img, x0, x1, dy)
    tmp.alpha_composite(img_from_map(legs), (ox + gx, oy + ys[2] + gy))
    tmp.alpha_composite(body_img, (ox + gx, oy + ys[1] + gy))
    tmp.alpha_composite(img_from_map(head), (ox + gx + head_off[0], oy + ys[0] + gy + head_off[1]))
    frame = tmp.crop((ox, oy, ox + 16, oy + 24))
    if fist_at:
        fists = fist_at if isinstance(fist_at[0], (list, tuple)) else [fist_at]
        for fx, fy in fists:
            draw_fist(frame, fx, fy)
    return frame


HERO_YS = (4, 15, 20)
HERO_HEADS = {"down": HERO_HEAD_DOWN, "up": HERO_HEAD_UP, "side": HERO_HEAD_SIDE}
HERO_BODIES = {"down": HERO_BODY_DOWN, "up": HERO_BODY_UP, "side": HERO_BODY_SIDE}

# Combo d'attaques : 3 coups aux poses distinctes, 4 frames chacun
# (armé → frappe → frappe accentuée → retour). Chaque frame = (jambes, kwargs).
# attack  : balayage      — poing dominant, torsion du buste
# attack2 : revers        — poing opposé, torsion inverse
# attack3 : estoc (final) — grand recul puis fente à deux poings
HERO_ATTACK_ANIMS = {
    "attack": {
        "down": [
            (0, dict(global_off=(0, -1), head_off=(1, 0), fist_at=(12, 11))),
            (1, dict(global_off=(0, 1), head_off=(0, 1), fist_at=(7, 21))),
            (1, dict(global_off=(0, 2), head_off=(0, 1), fist_at=(7, 22))),
            (0, dict()),
        ],
        "up": [
            (0, dict(global_off=(0, 1), fist_at=(12, 14))),
            (1, dict(global_off=(0, -2), fist_at=(11, 5))),
            (1, dict(global_off=(0, -3), fist_at=(11, 4))),
            (0, dict()),
        ],
        "side": [
            (0, dict(global_off=(-1, 0), head_off=(-1, 0), fist_at=(3, 13))),
            (1, dict(global_off=(2, 0), head_off=(1, 0), fist_at=(13, 15))),
            (1, dict(global_off=(3, 0), head_off=(1, 0), fist_at=(13, 15))),
            (0, dict()),
        ],
    },
    "attack2": {
        "down": [
            (0, dict(global_off=(0, -1), head_off=(-1, 0), fist_at=(3, 11))),
            (2, dict(global_off=(0, 1), head_off=(0, 1), fist_at=(8, 21))),
            (2, dict(global_off=(0, 2), head_off=(0, 1), fist_at=(8, 22))),
            (0, dict()),
        ],
        "up": [
            (0, dict(global_off=(0, 1), fist_at=(3, 14))),
            (2, dict(global_off=(0, -2), fist_at=(4, 5))),
            (2, dict(global_off=(0, -3), fist_at=(4, 4))),
            (0, dict()),
        ],
        "side": [
            (0, dict(global_off=(0, -1), fist_at=(13, 10))),
            (2, dict(global_off=(2, 0), head_off=(1, 0), fist_at=(13, 17))),
            (2, dict(global_off=(3, 0), head_off=(1, 0), fist_at=(13, 18))),
            (0, dict()),
        ],
    },
    "attack3": {
        "down": [
            (0, dict(global_off=(0, -2), head_off=(1, 0), fist_at=(12, 10))),
            (1, dict(global_off=(0, 1), head_off=(0, 2), fist_at=[(5, 21), (10, 21)])),
            (2, dict(global_off=(0, 2), head_off=(0, 2), fist_at=[(5, 22), (10, 22)])),
            (0, dict()),
        ],
        "up": [
            (0, dict(global_off=(0, 2), fist_at=(3, 15))),
            (1, dict(global_off=(0, -2), fist_at=[(5, 4), (10, 4)])),
            (2, dict(global_off=(0, -3), fist_at=[(5, 3), (10, 3)])),
            (0, dict()),
        ],
        "side": [
            (0, dict(global_off=(-2, 0), head_off=(-1, 0), fist_at=(2, 12))),
            (1, dict(global_off=(2, 0), head_off=(1, 0), fist_at=[(13, 13), (13, 16)])),
            (2, dict(global_off=(2, 0), head_off=(1, 0), fist_at=[(13, 13), (13, 16)])),
            (0, dict()),
        ],
    },
}


def hero_build(direction, legs_i, **kwargs):
    legs = (HERO_LEGS_SIDE if direction == "side" else HERO_LEGS)[legs_i]
    return build_frame(HERO_HEADS[direction], HERO_BODIES[direction], legs, HERO_YS, **kwargs)


def gen_hero():
    for d in ("down", "up", "side"):
        arms = HERO_ARMS[d]
        swing_a = [(span, (1 if i == 0 else -1)) for i, span in enumerate(arms)]
        swing_b = [(span, -dy) for span, dy in swing_a]
        relax = [(span, 1) for span in arms]
        # idle : respiration (tête et épaules s'affaissent d'un pixel)
        save(hero_build(d, 0), f"hero_idle_{d}_0")
        save(hero_build(d, 0, head_off=(0, 1), arm_shift=relax), f"hero_idle_{d}_1")
        # marche 6 frames : appui (bras balancés) / poids / passage, des deux côtés
        walk = [
            (1, (0, 0), swing_a), (1, (0, 1), swing_a), (3, (0, -1), None),
            (2, (0, 0), swing_b), (2, (0, 1), swing_b), (3, (0, -1), None),
        ]
        for i, (legs_i, goff, arm) in enumerate(walk):
            save(hero_build(d, legs_i, global_off=goff, arm_shift=arm), f"hero_walk_{d}_{i}")
        # combo : 3 attaques distinctes de 4 frames chacune
        for anim_name, dirs in HERO_ATTACK_ANIMS.items():
            for i, (legs_i, kwargs) in enumerate(dirs[d]):
                save(hero_build(d, legs_i, **kwargs), f"hero_{anim_name}_{d}_{i}")

# ---------------------------------------------------------------- crochet
HOOK = [
    "....ooo.....",
    "..oowwwoo...",
    ".owwwWWwwo..",
    ".owwoooowwo.",
    ".owo....owo.",
    ".owo.....oo.",
    ".owwo.......",
    "..owwo......",
    "...owwo.....",
    "...oWwo.....",
    "...oWwo.....",
    "...oWwo.....",
    "...owwo.....",
    "..owWWwo....",
    "..owwwwo....",
    "...oooo.....",
]


def gen_hook():
    save(img_from_map(HOOK), "hook")

# ---------------------------------------------------------------- kobold
# Kobolds redessinés aux proportions de assets/reference/sprite-linklike.jpg :
# grosse tête (oreilles hautes, yeux rouges 2px, museau), bras détachés.
KOBOLD_HEAD_DOWN = [
    ".oo..........oo.",
    "ofko........okfo",
    "ofkfo......ofkfo",
    "offffoooooofffFo",
    ".offffffffffffo.",
    ".ofFffffffffFfo.",
    ".offvvffffvvffo.",
    ".offvvffffvvffo.",
    ".offfffbbffffo..",
    "..offobbbbofo...",
    "...obnnnnbo.....",
]
KOBOLD_HEAD_UP = [
    ".oo..........oo.",
    "ofko........okfo",
    "ofkfo......ofkfo",
    "offffoooooofffFo",
    ".offffffffffffo.",
    ".ofkffffffffkfo.",
    ".offffFffFffffo.",
    ".offffffffffffo.",
    ".okffffffffffo..",
    "..offffffffko...",
    "...offffffo.....",
]
KOBOLD_HEAD_SIDE = [
    "...oo.....oo....",
    "..ofko...okfo...",
    "..ofkfo.ofkfo...",
    "..offffofffffo..",
    "...offffffffffo.",
    "...ofFfvvffffo..",
    "...offfvvfobbo..",
    "...okffffobnnno.",
    "...offffffbbo...",
    "....offffffo....",
    ".....offffo.....",
]
KOBOLD_BODY = [
    ".okffffffffffko.",
    ".offoffbbffoffo.",
    ".okfofbbbbfofko.",
    "..offoccccoffo..",
    "...onoccccono...",
]
KOBOLD_BODY_SIDE = [
    "...okffffffko...",
    "...offfbbofffo..",
    "...okffbbofko...",
    "....ofocccofo...",
    "....onocccono...",
]
KOBOLD_LEGS = {
    0: [
        "....oko..oko....",
        "....ofo..ofo....",
        "....ono..ono....",
    ],
    1: [
        "...oko...oko....",
        "...ofo...ono....",
        "...ono..........",
    ],
    2: [
        "....oko...oko...",
        "....ono...ofo...",
        "..........ono...",
    ],
}


KOBOLD_YS = (5, 16, 21)
KOBOLD_HEADS = {"down": KOBOLD_HEAD_DOWN, "up": KOBOLD_HEAD_UP, "side": KOBOLD_HEAD_SIDE}
KOBOLD_BODIES = {"down": KOBOLD_BODY, "up": KOBOLD_BODY, "side": KOBOLD_BODY_SIDE}


def kobold_build(direction, legs_i, **kwargs):
    return build_frame(KOBOLD_HEADS[direction], KOBOLD_BODIES[direction],
                       KOBOLD_LEGS[legs_i], KOBOLD_YS, **kwargs)


def gen_kobold():
    for d in ("down", "up", "side"):
        save(kobold_build(d, 0), f"kobold_idle_{d}_0")
        save(kobold_build(d, 0, global_off=(0, 1)), f"kobold_idle_{d}_1")
        walk = [(1, (0, 0)), (0, (0, -1)), (2, (0, 0)), (0, (0, -1))]
        for i, (legs_i, goff) in enumerate(walk):
            save(kobold_build(d, legs_i, global_off=goff), f"kobold_walk_{d}_{i}")

# ---------------------------------------------------------------- orbes & fx


def gen_orb(name, core, mid):
    im = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([1, 1, 10, 10], fill=(*mid, 255))
    d.ellipse([3, 3, 8, 8], fill=(*core, 255))
    d.ellipse([3, 3, 5, 5], fill=(255, 255, 255, 230))
    save(im, name)


def gen_glow():
    size = 64
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = im.load()
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            dist = math.hypot(x - c, y - c) / (size / 2)
            a = max(0.0, 1.0 - dist)
            px[x, y] = (255, 255, 255, int(255 * a * a))
    save(im, "glow")


def gen_shadow():
    im = Image.new("RGBA", (16, 6), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2, 0, 13, 5], fill=(20, 16, 24, 90))
    save(im, "shadow")


def gen_slash():
    for f in range(2):
        im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        w = 3 if f == 0 else 2
        col = (255, 255, 230, 220) if f == 0 else (180, 240, 255, 140)
        d.arc([2, 2, 21, 21], start=-70, end=70, fill=col, width=w)
        save(im, f"slash_{f}")


def gen_puff():
    for f in range(3):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        r = 3 + f * 2
        a = 220 - f * 70
        for ang in range(0, 360, 90):
            x = 8 + int(math.cos(math.radians(ang + f * 30)) * f * 2.2)
            y = 8 + int(math.sin(math.radians(ang + f * 30)) * f * 2.2)
            d.ellipse([x - r // 2, y - r // 2, x + r // 2, y + r // 2],
                      fill=(200, 200, 210, a))
        save(im, f"puff_{f}")


HEART = [
    ".oo.oo.",
    "oXXoXXo",
    "oXXXXXo",
    ".oXXXo.",
    "..oXo..",
    "...o...",
]


def gen_hearts():
    for name, col in [("heart_full", (226, 58, 66)), ("heart_empty", (68, 52, 60))]:
        pal = dict(PAL)
        pal["X"] = col
        save(img_from_map(HEART, pal), name)

# ---------------------------------------------------------------- tuiles
random.seed(7)


def tile(base, speck, n=14, speck2=None):
    im = Image.new("RGBA", (16, 16), (*base, 255))
    px = im.load()
    for _ in range(n):
        x, y = random.randrange(16), random.randrange(16)
        px[x, y] = (*speck, 255)
    if speck2:
        for _ in range(5):
            x, y = random.randrange(16), random.randrange(16)
            px[x, y] = (*speck2, 255)
    return im


def gen_tiles():
    grass = (88, 172, 82)
    tiles = {}
    tiles["grass1"] = tile(grass, (70, 150, 70))
    tiles["grass2"] = tile(grass, (70, 150, 70), speck2=(255, 130, 160))  # fleurs hibiscus
    tiles["sand1"] = tile((240, 212, 147), (222, 188, 118))
    tiles["sand2"] = tile((240, 212, 147), (222, 188, 118), speck2=(252, 240, 210))
    tiles["path"] = tile((196, 152, 103), (170, 127, 82))
    # eau : base + vaguelettes
    water = tile((43, 158, 199), (36, 140, 182), n=8)
    d = ImageDraw.Draw(water)
    for y in (4, 11):
        x0 = random.randrange(4)
        d.line([x0, y, x0 + 4, y], fill=(150, 226, 240, 255))
    tiles["water"] = water
    # écume (bord de plage)
    foam = tile((43, 158, 199), (36, 140, 182), n=6)
    d = ImageDraw.Draw(foam)
    d.line([0, 1, 15, 1], fill=(191, 238, 242, 255))
    d.line([0, 3, 15, 3], fill=(120, 205, 226, 255))
    tiles["foam"] = foam
    # buisson jungle (solide)
    bush = tile(grass, (70, 150, 70))
    d = ImageDraw.Draw(bush)
    d.ellipse([1, 2, 14, 14], fill=(38, 105, 56, 255))
    d.ellipse([3, 3, 12, 11], fill=(52, 138, 70, 255))
    d.ellipse([5, 4, 9, 8], fill=(84, 170, 92, 255))
    tiles["bush"] = bush
    # falaise / rocher (solide)
    rock = tile((146, 134, 110), (122, 111, 90), n=12)
    d = ImageDraw.Draw(rock)
    d.rectangle([0, 0, 15, 1], fill=(178, 165, 138, 255))
    d.rectangle([0, 14, 15, 15], fill=(96, 87, 70, 255))
    for x in (3, 9, 13):
        d.line([x, 4, x, 10], fill=(118, 107, 86, 255))
    tiles["cliff"] = rock

    order = ["grass1", "grass2", "sand1", "sand2", "path",
             "water", "foam", "bush", "cliff"]
    atlas = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    for i, name in enumerate(order):
        atlas.paste(tiles[name], ((i % 3) * 16, (i // 3) * 16))
    save(atlas, "tiles")

# ---------------------------------------------------------------- décors
PALM = [
    "......LLLL..............",
    "...LLLllLLLLL...........",
    ".LLLlLLLLLlLLLL.........",
    "LLlLLL.oo.LLLlLLL.......",
    "LlL...oUTo...LLlLL......",
    "L....oUTTCo....LlL......",
    ".....oTTCCo......L......",
    ".....oUTTo..............",
    "......oUTo..............",
    "......oUTo..............",
    ".......oUTo.............",
    ".......oUTo.............",
    "........oUTo............",
    "........oUTo............",
    "........oUTTo...........",
    "........oUTTo...........",
]
TOTEM = [
    "..oooooooooo....",
    ".oAAAAAAAAAAo...",
    ".oAaYaAAaYaAo...",
    ".oAaYaAAaYaAo...",
    ".oAAAAaaAAAAo...",
    ".oAaAAAAAAaAo...",
    ".oAAaaaaaaAAo...",
    ".oaAAAAAAAAao...",
    ".oAAaAaaAaAAo...",
    ".oAAAAAAAAAAo...",
    ".oAaaAAAAaaAo...",
    ".oAAAAaaAAAAo...",
    ".oaAAAAAAAAao...",
    ".oAAAAAAAAAAo...",
    "oooAAAAAAAAooo..",
    "oaaaaaaaaaaaao..",
]
ROCK_PROP = [
    "....oooo........",
    "..ooqqqRoo......",
    ".oqqRRRRRRo.....",
    ".oqRRRRrRRRo....",
    "oRRRrRRRRrRo....",
    "oRrRRRRrRRro....",
    ".orrrrrrrro.....",
    "..oooooooo......",
]


def gen_props():
    save(img_from_map(PALM), "palm")
    save(img_from_map(TOTEM), "totem")
    save(img_from_map(ROCK_PROP), "rock")

# ---------------------------------------------------------------- preview


def preview():
    names = sorted(p.stem for p in OUT.glob("*.png") if p.stem != "preview")
    scale = 5
    cols = 6
    cell = 40 * scale
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (40, 44, 52, 255))
    for i, n in enumerate(names):
        im = Image.open(OUT / f"{n}.png")
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        x = (i % cols) * cell + (cell - im.width) // 2
        y = (i // cols) * cell + (cell - im.height) // 2
        sheet.alpha_composite(im, (max(x, 0), max(y, 0)))
    sheet.save(OUT / "preview.png")


if __name__ == "__main__":
    # purge des anciennes frames (noms de schéma précédent inclus)
    for old in list(OUT.glob("hero_*.png")) + list(OUT.glob("kobold_*.png")):
        old.unlink()
        imp = old.with_suffix(".png.import")
        if imp.exists():
            imp.unlink()
    gen_hero()
    gen_hook()
    gen_kobold()
    gen_orb("orb_green", (82, 255, 122), (30, 160, 70))
    gen_orb("orb_red", (255, 92, 82), (170, 40, 36))
    gen_orb("orb_dim", (150, 150, 150), (90, 90, 95))
    gen_glow()
    gen_shadow()
    gen_slash()
    gen_puff()
    gen_hearts()
    gen_tiles()
    gen_props()
    preview()
    print("OK ->", OUT)
