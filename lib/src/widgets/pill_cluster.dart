import 'package:flutter/material.dart';

/// Default colors for cluster pills
class ClusterPillColors {
  static const Color defaultBackground = Color(0xFF6366F1); // Indigo
  static const Color selectedBackground = Colors.cyan;
  static const Color text = Colors.white;
  static const Color icon = Colors.white;
}

class ClusterPill extends StatelessWidget {
  /// The text label displayed on the pill
  final String label;
  
  /// Whether this pill is currently selected
  final bool isSelected;
  
  /// Callback fired when the pill is tapped
  final VoidCallback? onTap;
  
  /// Callback fired when the pill is long-pressed (e.g., for context menu)
  final VoidCallback? onLongPress;
  
  /// Custom background color (overrides default/selected colors)
  final Color? backgroundColor;
  
  /// Custom text color
  final Color? textColor;
  
  /// Custom icon to display (defaults to chevron_right or check based on selection)
  final IconData? icon;
  
  /// Whether to show the trailing icon
  final bool showIcon;
  
  /// Whether to show a drag handle (for reorderable lists)
  final bool showDragHandle;

  const ClusterPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.showIcon = true,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        (isSelected ? ClusterPillColors.selectedBackground : ClusterPillColors.defaultBackground);
    final fgColor = textColor ?? ClusterPillColors.text;
    final displayIcon = icon ?? (isSelected ? Icons.check : Icons.chevron_right);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional drag handle
            if (showDragHandle) ...[
              Icon(
                Icons.drag_indicator,
                size: 16,
                color: fgColor.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
            ],
            
            // Label text
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
            
            // Optional trailing icon
            if (showIcon) ...[
              const SizedBox(width: 6),
              Icon(
                displayIcon,
                size: 18,
                color: fgColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A variant of ClusterPill with a lighter, outline style.
/// Useful for unselected or secondary states.
class ClusterPillOutline extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? textColor;
  final bool showIcon;

  const ClusterPillOutline({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.borderColor,
    this.textColor,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? (isSelected ? Colors.cyan : Colors.grey.shade300);
    final text = textColor ?? (isSelected ? Colors.black : Colors.grey.shade700);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: text,
              ),
            ),
            if (showIcon) ...[
              const SizedBox(width: 6),
              Icon(
                isSelected ? Icons.check : Icons.chevron_right,
                size: 16,
                color: text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small badge-style cluster pill for compact displays
class ClusterPillCompact extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ClusterPillCompact({
    super.key,
    required this.label,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? ClusterPillColors.defaultBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}