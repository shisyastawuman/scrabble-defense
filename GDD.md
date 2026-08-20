# SCRABBLE DEFENSE
 
# High Level Concept/Design 

## Concept statement 
Play tower defense using scrabble words as walls that get stronger the more connected they are. Survive enemies and exploit map features to gain resource and craft better letter tiles.

## Genre(s) 
Tower defense word game
 
## Target audience 
Motivations and relevant interests; potentially age, gender, etc.; and the desired ESRB rating for the game. 

## Unique Selling Points 
Critically important. What makes your game stand out? How is it different from all other games? 
Player Experience and Game POV 
Who is the player? What is the setting? What is the fantasy the game grants the player? What emotions do  you want the player to feel? What keeps the player engaged for the duration of their play? 

# Detailed & Game Systems Design

## Core Loops 

## Objectives and Progression 
How does the player move through the game, literally and figuratively, from tutorial to end? What are their  short-term and long-term goals (explicit or implicit)? How do these support the game concept, style, and  player-fantasy? 

## Game Systems 

### Phases:
- Player turn
-- Place letter to form up to one word.
-- Gain energy from words formed and use it in spells.
-- Draw letter tiles.
- Words actions
- Enemies actions
- Enemies movement
- Enemies spawn

### Letter placement rules:
- You may place any amount of letters on a single axis without empty spaces in between.
- New letters must all end as part of valid words.
- After word validation, new letters crush enemies underneath them.
- Letters remain as walls with 1 health.
- Every time a placed letter becomes part of a new word, it gains 1 health. This applies both for letters that were in place and are included in a new word, and letters that are placed as connected to 2 or more words.
- Destroyed letters dissappear. This could left invalid words, that's ok, but if new letters are added adjacent to them, they must be valid again.

### Energy and spellbook rules:
- You have a spellbook with up to 5 spells.
- Spells can be casted for an energy cost.
- Words give as much energy as their length.
- Remaining energy is discarded at the end of the turn.

### Letter bag and draw rules:
- Player has a letter bag, starting with 20 letters (10 vowels, 10 consonants).
- Player has a vowels hand and a consonant hand, which are refilled at the end of the turn.
- Letters are used for casting words and then go to a discard. When bag is empty, discard is reshuffled to form a new bag.

### Enemies movements, actions and spawn
Basic enemies have health points, damage and speed. They move by their speed towards player's village tiles. Upong reaching a wall, the enemies smash against it, damaging the wall and receiving damage as well.

Upon an enemy reaching a village tile, the player loses. Upon destroying the last enemy, the player wins.

Advanced enemies also have actions which they take before moving (e.g., range-attacking a wall, boosting nearby enemies speed).

Enemies may also have effects upon spawning (e.g., heal all enemies), dying (e.g., damage adjacent walls) or encountering a wall (e.g., jump over it the first time).

Enemies spawn by a fixed amount and type, on randomized origin tiles, calculated as end points of straigth lines from the villages. Enemies never change paths.

### Level design
The game is played on a 2D grid, with an interior sub-area of buildable tiles and an outside area for enemy spawning.

In the interior, player villages spawn in fixed tiles. Then, map features are randomized on some of the rest of the tiles.

Map features can include:
- Terrain modifiers.
- Traps set for enemies.
- Bonus rewards pickable by building words on top.

## MVP 1 Feature List
- IMPORTANT: All the content should be based on .tres easily modifiable, expandable and modular.
- Enemies in particular should be as modular as possible, composed of different effects and actions.

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

## Interactivity 

How are different kinds of interactivity used? (Action/Feedback, ST Cog, LT Cog, Emotional, Social, Cultural)  What is the player doing moment-by-moment? How does the player move through the world? How does  physics/combat/etc. work? A clear, professional-looking sketch of the primary game UX is helpful. 
