import 'package:flutter/material.dart';

/// Default colors for trend pills
class TrendPillColors {
  static const Color background = Color(0xFFF3F4F6); // Light gray
  static const Color backgroundSelected = Color(0xFFE0F2FE); // Light cyan
  static const Color text = Color(0xFF374151); // Dark gray
  static const Color textSelected = Color(0xFF0891B2); // Cyan
  static const Color border = Color(0xFFD1D5DB); // Gray border
  static const Color borderSelected = Colors.cyan;
}

/// A simple pill widget for displaying trends, tags, or categories.
/// 
/// Lighter and simpler than ClusterPill, designed for secondary
/// navigation or filtering use cases.
/// 
/// Example usage:
/// ```dart
/// TrendPill(
///   label: 'Macro Trends',
///   onTap: () => filterByTrend('Macro Trends'),
/// )
/// ```
class TrendPill extends StatelessWidget {
  /// The text label displayed on the pill
  final String label;
  
  /// Whether this pill is currently selected/active
  final bool isSelected;
  
  /// Callback fired when the pill is tapped
  final VoidCallback? onTap;
  
  /// Optional icon to display before the label
  final IconData? leadingIcon;
  
  /// Optional icon to display after the label
  final IconData? trailingIcon;

  const TrendPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? TrendPillColors.backgroundSelected 
              : TrendPillColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? TrendPillColors.borderSelected 
                : TrendPillColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 16,
                color: isSelected 
                    ? TrendPillColors.textSelected 
                    : TrendPillColors.text,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? TrendPillColors.textSelected 
                    : TrendPillColors.text,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(
                trailingIcon,
                size: 16,
                color: isSelected 
                    ? TrendPillColors.textSelected 
                    : TrendPillColors.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tag-style trend pill with an icon indicator
/// Useful for displaying hashtag-like categories
class TrendTagPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showTagIcon;

  const TrendTagPill({
    super.key,
    required this.label,
    this.onTap,
    this.showTagIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (showTagIcon) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.sell_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A minimal trend pill for inline use
class TrendPillMinimal extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const TrendPillMinimal({
    super.key,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? Colors.grey.shade600;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: pillColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: pillColor,
          ),
        ),
      ),
    );
  }
}

/// An environment pill - used for workspace/environment selection
/// Has a drag handle and selection state
class EnvironmentPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDragHandle;

  const EnvironmentPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.cyan.withOpacity(0.1) 
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) ...[
              Icon(
                Icons.drag_indicator,
                size: 16,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}