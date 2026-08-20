from pathlib import Path

ROOT = Path(r"c:\Users\lcasa\Documents\VideogameDev\scrabble-defense")
LETTER_DIR = ROOT / "resources" / "letters" / "base"
LETTER_DIR.mkdir(parents=True, exist_ok=True)

EXISTING_UIDS = {
    "A": "uid://onlfm28x23nn",
    "R": "uid://bs3ax75m1tevo",
}


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.replace("\r\n", "\n"), encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    uid_attr = f' uid="{EXISTING_UIDS[ch]}"' if ch in EXISTING_UIDS else ""
    write(
        LETTER_DIR / f"{ch}.tres",
        f"""[gd_resource type="Resource" script_class="LetterBlueprint" load_steps=2 format=3{uid_attr}]

[ext_resource type="Script" path="res://scripts/classes/letter_blueprint.gd" id="1"]

[resource]
script = ExtResource("1")
char = "{ch}"
health = 1
""",
    )

counts = {
    "A": 3,
    "E": 2,
    "I": 2,
    "O": 2,
    "U": 1,
    "R": 1,
    "S": 1,
    "T": 1,
    "N": 1,
    "L": 1,
    "D": 1,
    "C": 1,
    "P": 1,
    "M": 1,
    "B": 1,
}

ext_lines = [
    '[ext_resource type="Script" path="res://scripts/classes/letter_set.gd" id="set"]',
    '[ext_resource type="Script" path="res://scripts/classes/stack_blueprint.gd" id="stack"]',
]
set_blocks = []
set_ids = []
for i, (ch, amount) in enumerate(counts.items(), start=1):
    ext_id = f"L{ch}"
    ext_lines.append(
        f'[ext_resource type="Resource" path="res://resources/letters/base/{ch}.tres" id="{ext_id}"]'
    )
    sub_id = f"Set_{ch}"
    set_ids.append(sub_id)
    set_blocks.append(
        f"""[sub_resource type="Resource" id="{sub_id}"]
script = ExtResource("set")
amount = {amount}
letter_blueprint = ExtResource("{ext_id}")
"""
    )

array_items = ", ".join(f'SubResource("{sid}")' for sid in set_ids)
write(
    ROOT / "resources" / "initial_bags" / "bag_test.tres",
    f"""[gd_resource type="Resource" script_class="StackBlueprint" load_steps={len(ext_lines) + 1} format=3 uid="uid://eppm43w0od36"]

{chr(10).join(ext_lines)}

{chr(10).join(set_blocks)}
[resource]
script = ExtResource("stack")
letter_sets = Array[ExtResource("set")]([{array_items}])
""",
)

write(
    ROOT / "resources" / "spell_effects" / "damage_1.tres",
    """[gd_resource type="Resource" script_class="DamageEnemyEffect" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/classes/spell_effects/damage_enemy_effect.gd" id="1"]

[resource]
script = ExtResource("1")
amount = 1
""",
)

write(
    ROOT / "resources" / "spells" / "zap.tres",
    """[gd_resource type="Resource" script_class="Spell" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/classes/spell.gd" id="1"]
[ext_resource type="Script" path="res://scripts/classes/spell_effect.gd" id="2"]
[ext_resource type="Resource" path="res://resources/spell_effects/damage_1.tres" id="3"]

[resource]
script = ExtResource("1")
display_name = "Zap"
description = "Deal 1 damage to an enemy."
energy_cost = 3
target_mode = 1
effects = Array[ExtResource("2")]([ExtResource("3")])
""",
)

write(
    ROOT / "resources" / "enemy_actions" / "gain_speed_every_2.tres",
    """[gd_resource type="Resource" script_class="GainSpeedAction" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/classes/enemy_actions/gain_speed_action.gd" id="1"]

[resource]
script = ExtResource("1")
amount = 1
interval = 2
""",
)

write(
    ROOT / "resources" / "enemies" / "basic.tres",
    """[gd_resource type="Resource" script_class="EnemyClass" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/classes/enemy_class.gd" id="1"]

[resource]
script = ExtResource("1")
display_name = "Basic"
health = 1
speed = 1
damage = 1
shape = 0
tooltip = "Walks straight at the village. Smashes walls in its path."
""",
)

write(
    ROOT / "resources" / "enemies" / "strong.tres",
    """[gd_resource type="Resource" script_class="EnemyClass" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/classes/enemy_class.gd" id="1"]

[resource]
script = ExtResource("1")
display_name = "Strong"
health = 2
speed = 1
damage = 2
shape = 1
tooltip = "Tougher raider. Hits walls for 2 damage."
""",
)

write(
    ROOT / "resources" / "enemies" / "speeder.tres",
    """[gd_resource type="Resource" script_class="EnemyClass" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/classes/enemy_class.gd" id="1"]
[ext_resource type="Script" path="res://scripts/classes/enemy_action.gd" id="2"]
[ext_resource type="Resource" path="res://resources/enemy_actions/gain_speed_every_2.tres" id="3"]
[ext_resource type="Script" path="res://scripts/classes/enemy_effect.gd" id="4"]

[resource]
script = ExtResource("1")
display_name = "Speeder"
health = 1
speed = 1
damage = 1
shape = 2
tooltip = "Gains +1 permanent speed every 2 turns."
actions = Array[ExtResource("2")]([ExtResource("3")])
""",
)

write(
    ROOT / "resources" / "player_test.tres",
    """[gd_resource type="Resource" script_class="Player" load_steps=5 format=3 uid="uid://dvuji4sr6yf36"]

[ext_resource type="Resource" path="res://resources/initial_bags/bag_test.tres" id="1"]
[ext_resource type="Script" path="res://scripts/classes/player.gd" id="2"]
[ext_resource type="Script" path="res://scripts/classes/spell.gd" id="3"]
[ext_resource type="Resource" path="res://resources/spells/zap.tres" id="4"]

[resource]
script = ExtResource("2")
stack_blueprint = ExtResource("1")
spells = Array[ExtResource("3")]([ExtResource("4")])
vowel_hand_size = 3
consonant_hand_size = 3
""",
)

waves = [
    [("basic", 1)],
    [("basic", 1)],
    [("basic", 2)],
    [("strong", 1)],
    [("speeder", 1)],
    [("strong", 1), ("basic", 1)],
    [("speeder", 2)],
    [("strong", 1), ("speeder", 1), ("basic", 1)],
]

ext = [
    '[ext_resource type="Script" path="res://scripts/classes/map.gd" id="map"]',
    '[ext_resource type="Script" path="res://scripts/classes/level.gd" id="level"]',
    '[ext_resource type="Script" path="res://scripts/classes/wave.gd" id="wave"]',
    '[ext_resource type="Script" path="res://scripts/classes/spawn_group.gd" id="group"]',
    '[ext_resource type="Resource" path="res://resources/enemies/basic.tres" id="basic"]',
    '[ext_resource type="Resource" path="res://resources/enemies/strong.tres" id="strong"]',
    '[ext_resource type="Resource" path="res://resources/enemies/speeder.tres" id="speeder"]',
]
subs = [
    """[sub_resource type="Resource" id="MapMain"]
script = ExtResource("map")
cols = 9
rows = 9
buildings = Array[Vector2i]([Vector2i(4, 4)])
"""
]
wave_ids = []
group_n = 0
for wi, groups in enumerate(waves, start=1):
    group_ids = []
    for enemy_id, count in groups:
        group_n += 1
        gid = f"G{group_n}"
        group_ids.append(gid)
        subs.append(
            f"""[sub_resource type="Resource" id="{gid}"]
script = ExtResource("group")
enemy = ExtResource("{enemy_id}")
count = {count}
"""
        )
    wid = f"W{wi}"
    wave_ids.append(wid)
    group_arr = ", ".join(f'SubResource("{g}")' for g in group_ids)
    subs.append(
        f"""[sub_resource type="Resource" id="{wid}"]
script = ExtResource("wave")
groups = Array[ExtResource("group")]([{group_arr}])
"""
    )

wave_arr = ", ".join(f'SubResource("{w}")' for w in wave_ids)
write(
    ROOT / "resources" / "levels" / "level_test.tres",
    f"""[gd_resource type="Resource" script_class="Level" load_steps={len(ext) + 1} format=3 uid="uid://cjy7giq6v0gyj"]

{chr(10).join(ext)}

{chr(10).join(subs)}
[resource]
script = ExtResource("level")
waves = Array[ExtResource("wave")]([{wave_arr}])
map = SubResource("MapMain")
""",
)

print("done")
