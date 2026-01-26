import 'package:flutter/material.dart';

/// A pill widget for displaying a trend with visibility controls
class TrendPill extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isVisible;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onVisibilityToggle;

  const TrendPill({
    super.key,
    required this.label,
    this.color,
    this.isVisible = true,
    this.isSelected = false,
    this.onTap,
    this.onVisibilityToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.cyan.withOpacity(0.1) 
              : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? Colors.cyan 
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color indicator dot
            if (color != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isVisible ? color : color!.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Label
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isVisible ? Colors.black87 : Colors.grey.shade400,
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Visibility toggle button
            if (onVisibilityToggle != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onVisibilityToggle,
                child: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  size: 16,
                  color: isVisible ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tag pill for category/tag selection in explore view
class TrendTagPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const TrendTagPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.pinkAccent : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              size: 16,
              color: isSelected ? Colors.pinkAccent : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.pinkAccent : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}