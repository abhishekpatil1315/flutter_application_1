# MathQuest

MathQuest is a Flutter / Dart maths learning game for Grades 1–6.

## Run locally

```sh
flutter pub get
flutter run
```

The initial implementation includes the onboarding and UI-only account flow,
three-step child profiles, course journey map, Rank/Profile/Settings screens,
Math Snap, Number Builder, Combo Forge, Grid Hunt, Math Array, Number Leap,
Pizza Party, per-child local progress, course mastery gates, and a testable
performance recommendation engine.
Progress is stored locally with
`shared_preferences`. Authentication, social sign-in, leaderboards, and
subscriptions are marked as future backend integration points.

## Grid Hunt

Grid Hunt is a continuous, turn-based addition game for one child against Prof
Penguin. Link neighboring cards on the 3×3 board and release to submit the sum;
wrong sums clear the selection without a penalty. A successful player claim
earns 8 XP and 12 coins, then Prof Penguin thinks for a moment and visibly
claims a matching pair if one is available. The next target is chosen from the
current board so the player always has a solution. There are no timers, hints,
attempt limits, or end-of-game screen.

Easy deals 1–5, Medium 2–9, and Hard 2–10. The selected difficulty is saved per
player profile. Replacement cards are always 1–5. Each successful claim records
three stars as a best result and adds one card to the player's score.

## Math Snap

Math Snap is a five-round race against Prof Penguin. Each puzzle deals the
digits 0–9 once, chooses a target that has at least one valid two-card answer,
and validates every mathematically correct pair for the selected operation.
Easy uses addition, Medium multiplication, and Hard lets the player choose
either. Wrong snaps cost 0, 1, or 2 coins respectively; a correct player snap
earns 12 coins. Prof Penguin's reaction delay and accuracy increase by level,
and the correct combination is shown after each round is decided. Difficulty
is saved per child profile.

Online Player vs Player is not enabled. TODO: connect a backend session service
that distributes the identical puzzle to both devices and determines the first
valid submission by server receipt order. The client does not simulate or claim
authoritative two-device multiplayer.

## Number Builder

Number Builder is a solo, untimed, five-round place-value game. Easy builds a
two-digit number; Medium and Hard build three-digit numbers. Easy and Medium
ask for the smallest or largest number, while Hard can also ask for the number
closest to a three-digit target. Each puzzle deals five unique digit cards.
Leading zero is rejected, every arrangement is evaluated against all legal
numbers, and equally close answers are accepted. An optimal answer awards 8 XP
and 12 coins. Difficulty is saved per child profile.

## Combo Forge

Combo Forge is a solo, untimed, five-round expression-building game using
single-digit cards. Easy allows addition and two operands, Medium allows
addition/subtraction and up to three operands, and Hard allows all four
operations and up to four operands; Hard answers must include multiplication.
Expressions use standard operator precedence, and division must produce a
whole-number intermediate result. The target is generated from a valid
expression in the level's range, and the result is hidden until submission.
Correct answers add 10 game points and award 8 XP and 12 coins; incorrect
Medium/Hard submissions deduct one/two game points, not wallet coins. Difficulty
is saved per child profile.

## Math Array

Math Array is a solo, untimed Course 1 multiplication game. The child counts
rows or equal groups first, then items in one row, and builds the ordered
equation with a digit pad. Easy has 6 rounds, Medium 8, and Hard 10; Hard hides
some rows while preserving equal groups. Each puzzle uses a unique valid fact
for its level and accepts only the rows-first factor order. Each round permits
two attempts; a correct round awards 8 XP and 12 coins. One non-answer hint per
round costs 3 coins. New child profiles start with 20 wallet coins.

## Number Leap

Number Leap is a solo, untimed Course 1 skip-counting game. Each sequence uses
one consistent addition or multiplication pattern, and children enter one or
more missing numbers using the digit pad. Easy has 6 rounds and uses +2/+3;
Medium has 8 rounds and uses +2/+3/+4 and ×2/×3/×4; Hard has 10 rounds and
adds +5/×5, with up to two blanks. Generated values stay at or below 45, and
the visible numbers uniquely identify the pattern. Each round permits two
attempts; a correct round awards 8 XP and 12 coins. One non-answer hint per
round costs 3 coins.

## Pizza Party

Pizza Party is a solo Course 1 fraction game with eight rounds per level. Easy
names a fraction, Medium adds red and blue portions with the same denominator,
and Hard finds a missing numerator in a listed equivalent-fraction family.
Each round permits two attempts and one 3-coin hint. Correct first attempts
earn 3 stars; second attempts earn 1. At level completion, wallet coins equal
the stars earned during that level; the game awards no XP. A new child profile
starts with 20 shared wallet coins. Pizza wedges are drawn in-app because the
exported asset set does not include pizza artwork.

Online multiplayer is intentionally disabled. TODO: add a shared session
backend that distributes identical puzzles and resolves fair two-player
submissions before exposing a multiplayer mode.

## Artwork

Images in `assets/` are declared in `pubspec.yaml` and used for the splash,
welcome, journey, course backgrounds, number cards (0–9), animal avatars, and
bottom navigation. Values without exported card artwork (negative cards and
10–12) continue to use the in-app number-card fallback.
