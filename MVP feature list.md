# MVP 2 Feature List

# Game structure

When completing a level, receive gold per enemy killed by walls (+2 if crushed by wall). This is tallied on a screen, with an "OK" button.
Upon clicking the button, go to shop when you can buy up.
Upon clicking "Next level", go to next level.
Bought stuff should be stored on a persistent player_state tres (alongside your letterbag, spellbook, current upgrade stats, etc.)
Bought stuff should all be based on .tres and modular, following the same pattern than enemies, spells and levels.

# Stuff to buy (everything auto-equips)

## Spells

Discard (1): Discard and replace a letter. +1 cost until end of turn.
Storm (6): Deal 1 damage to 5 random enemies.
Freeze (4): Reduce enemy speed to 0 until your next turn.
Reinforce (3): Strengthen a letter by 1.

## Letter enchantments

Enchant a letter with a power which fires upon placing the letter.
Powers:
- +2 energy.
- Kill a random enemy with current health 2 or less.
- Give adjacent letters +1 strength.

## Enchanted letters
Buy rare letters with special powers:
- Blanks (can be any letter, choose upon placing).
- V: Gains +1 strength every turn.
- J: Shoot the farthest enemy every turn for 1 damage.
- H: 
- W: Player gains +1 energy every turn.

## Upgrades
- Max. energy.
- Vowel size.
- Consonant size.

## Enemies
- Basic: 1 health. 1 damage. 1 speed.
- Strong: 2 health. 2 damage. 1 speed.
- Speedster: 1 health. 1 damage. 1 speed. +1 speed every 2 turns.
- Archer: 1 health. 1 damage. 1 speed. Attacks up to 2 range.
- Explosive: 1 health. 1 damage. 1 speed. Damages all around upon dying.
- Buffer: 2 health. 0 damage. 0 speed. Speeds up nearby enemies.
- Boss: 10 health. 5 damage. 2 speed. Fires a laser upfront every 3 turns.

## UX
- Enemies indicate in which direction they are moving.
- Phase indicator (enemies action, enemies moving, etc.)
- Letters are drag and drop.
- Energy is a meter that fills (like a health bar).

## VFX
- Effect when crushing enemies with letters.
- Enemies tween to 0 size when dying.
- Walls tween to 0 size when destroyed.
- Basic effects for using spells.
- Basic popup modifiers when gaining and spending energy.
- Basic popup modifiers when letters gain strength.
- Basic popup modifiers when letters and enemies take damage.

## Levels
1) 1 house. 9x9. 7 waves.
2) 2 houses. 11x11. 10 waves.
3) 3 houses. 15x15. 15 waves.

## SFX
- X by Y grid map with an array of village spawns. Outermost tiles are flagged as enemy land (non buildable). Enemy spawns are calculated based on village placement.
- Enemy spawn according to resource that lists how many enemies and of which type spawn in each turn.
- 3 enemy types:
-- Basic: 1 health, 1 speed, 1 damage.
-- Strong: 2 health, 1 speed, 2 damage.
-- Speeder: 1 health, 1 speed, 1 damage. Gains +1 permanent speed every 2 turns.
- Player hand with 3 vowel slots and 3 consonant slots.
- Spellbook with 1 spell: deal 1 damage to an enemy for 3 energy.

- UX:
-- Top: Turn count.
-- Center: Grid map. Enemies, words and village are hoverable, show you a tooltip with their stats and a message.
-- Bottom: Vowel and consonant slots.
-- Bottom right: End turn button. Letter discard, clickable, shows you which letters have been discarded.
-- Bottom left: Letter bag, clickable, shows you which letters are left to drawn.
-- Left: Spellbook.

-- For visuals, use shapes and different color gradients to differentiate 1/2/3 health walls and enemies.
-- Include a dictionary of english words.
