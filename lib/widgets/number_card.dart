import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_theme.dart';

class NumberCard extends StatelessWidget {
  const NumberCard({
    required this.value,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  final int value;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconCount = value.abs().clamp(0, 12);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '$value, ${value.abs()} animal icons${selected ? ', selected' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: dimmed
                ? const Color(0xFFE6ECE8)
                : selected
                ? const Color(0xFFDDF7E6)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.actionGreen : const Color(0xFFD9E6DE),
              width: selected ? 3 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1410233F),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: value >= 0 && value <= 9
              ? Opacity(
                  opacity: dimmed ? 0.5 : 1,
                  child: Image.asset(
                    AppAssets.numberCard(value),
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) =>
                        _FallbackCardValue(
                      value: value,
                      iconCount: iconCount,
                      dimmed: dimmed,
                    ),
                  ),
                )
              : _FallbackCardValue(
                  value: value,
                  iconCount: iconCount,
                  dimmed: dimmed,
                ),
        ),
      ),
    );
  }
}

class _FallbackCardValue extends StatelessWidget {
  const _FallbackCardValue({
    required this.value,
    required this.iconCount,
    required this.dimmed,
  });

  final int value;
  final int iconCount;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                color: dimmed ? const Color(0xFF526256) : AppColors.navy,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 1,
              runSpacing: 0,
              children: [
                for (var index = 0; index < iconCount; index++)
                  const Icon(
                    Icons.set_meal_rounded,
                    size: 10,
                    color: AppColors.skyBlue,
                  ),
              ],
            ),
          ],
        ),
      );
}
