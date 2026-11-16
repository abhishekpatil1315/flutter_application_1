import 'package:flutter/material.dart';

import '../games/grid_hunt/grid_hunt_screen.dart';
import '../games/combo_forge/combo_forge_screen.dart';
import '../games/math_array/math_array_screen.dart';
import '../games/math_snap/math_snap_screen.dart';
import '../games/number_leap/number_leap_screen.dart';
import '../games/number_builder/number_builder_screen.dart';
import '../games/pizza_party/pizza_party_screen.dart';

class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.course,
    required this.icon,
    this.builder,
    this.available = false,
  });

  final String id;
  final String title;
  final int course;
  final IconData icon;
  final WidgetBuilder? builder;
  final bool available;
}

const allGames = <GameEntry>[
  GameEntry(
    id: 'math-snap',
    title: 'Math Snap',
    course: 1,
    icon: Icons.bolt_rounded,
    builder: _buildMathSnap,
    available: true,
  ),
  GameEntry(
    id: 'number-builder',
    title: 'Number Builder',
    course: 1,
    icon: Icons.numbers_rounded,
    builder: _buildNumberBuilder,
    available: true,
  ),
  GameEntry(
    id: 'combo-forge',
    title: 'Combo Forge',
    course: 1,
    icon: Icons.handyman_rounded,
    builder: _buildComboForge,
    available: true,
  ),
  GameEntry(
    id: 'grid-hunt',
    title: 'Grid Hunt',
    course: 1,
    icon: Icons.explore_rounded,
    builder: _buildGridHunt,
    available: true,
  ),
  GameEntry(
    id: 'math-array',
    title: 'Math Array',
    course: 1,
    icon: Icons.grid_on_rounded,
    builder: _buildMathArray,
    available: true,
  ),
  GameEntry(
    id: 'number-leap',
    title: 'Number Leap',
    course: 1,
    icon: Icons.trending_up_rounded,
    builder: _buildNumberLeap,
    available: true,
  ),
  GameEntry(
    id: 'pizza-party',
    title: 'Pizza Party',
    course: 1,
    icon: Icons.local_pizza_rounded,
    builder: _buildPizzaParty,
    available: true,
  ),
  GameEntry(
    id: 'number-trail',
    title: 'Number Trail',
    course: 1,
    icon: Icons.trending_up_rounded,
  ),
  GameEntry(
    id: 'flip-5',
    title: 'Flip 5',
    course: 1,
    icon: Icons.style_rounded,
  ),
  GameEntry(
    id: 'slot-wars',
    title: 'Slot Wars',
    course: 2,
    icon: Icons.center_focus_strong_rounded,
  ),
  GameEntry(
    id: 'fraction-clash',
    title: 'Fraction Clash',
    course: 2,
    icon: Icons.pie_chart_rounded,
  ),
  GameEntry(
    id: 'fair-share',
    title: 'Fair Share',
    course: 2,
    icon: Icons.balance_rounded,
  ),
  GameEntry(
    id: 'factor-frenzy',
    title: 'Factor Frenzy',
    course: 2,
    icon: Icons.close_rounded,
  ),
  GameEntry(
    id: 'decimal-dash',
    title: 'Decimal Dash',
    course: 2,
    icon: Icons.speed_rounded,
  ),
  GameEntry(
    id: 'math-bingo',
    title: 'Math Bingo',
    course: 2,
    icon: Icons.grid_3x3_rounded,
  ),
  GameEntry(
    id: 'ice-trail',
    title: 'Ice Trail',
    course: 3,
    icon: Icons.ac_unit_rounded,
  ),
  GameEntry(
    id: 'ratio-balance',
    title: 'Ratio Balance',
    course: 3,
    icon: Icons.balance_rounded,
  ),
  GameEntry(
    id: 'percent-match',
    title: '% Match',
    course: 3,
    icon: Icons.percent_rounded,
  ),
  GameEntry(
    id: 'function-machine',
    title: 'Function Machine',
    course: 3,
    icon: Icons.settings_rounded,
  ),
  GameEntry(
    id: 'math-masters',
    title: 'Math Masters',
    course: 3,
    icon: Icons.emoji_events_rounded,
  ),
  GameEntry(
    id: 'quick-grab',
    title: 'Quick Grab',
    course: 3,
    icon: Icons.query_stats_rounded,
  ),
];

Widget _buildGridHunt(BuildContext context) => const GridHuntScreen();

Widget _buildMathSnap(BuildContext context) => const MathSnapScreen();

Widget _buildNumberBuilder(BuildContext context) => const NumberBuilderScreen();

Widget _buildComboForge(BuildContext context) => const ComboForgeScreen();

Widget _buildMathArray(BuildContext context) => const MathArrayScreen();

Widget _buildNumberLeap(BuildContext context) => const NumberLeapScreen();

Widget _buildPizzaParty(BuildContext context) => const PizzaPartyScreen();
