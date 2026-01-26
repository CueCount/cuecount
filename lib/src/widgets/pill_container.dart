import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

/// A reusable container widget that displays a collapsible section
/// with a header label and a wrap of pill children.
/// 
/// Supports both static and reorderable layouts.
/// 
/// Example usage:
/// ```dart
/// PillContainer(
///   label: 'My Section',
///   reorderable: true,
///   collapsed: isCollapsed,
///   onToggle: () => setState(() => isCollapsed = !isCollapsed),
///   onReorder: (oldIndex, newIndex) => handleReorder(oldIndex, newIndex),
///   children: myPillWidgets,
/// )
/// ```
class PillContainer extends StatelessWidget {
  /// The header label text displayed above the pill content
  final String label;
  
  /// Whether the pills can be reordered via drag and drop
  final bool reorderable;
  
  /// Whether the content section is currently collapsed
  final bool collapsed;
  
  /// Callback fired when the header is tapped (to toggle collapse)
  final VoidCallback onToggle;
  
  /// The pill widgets to display in the wrap
  final List<Widget> children;
  
  /// Callback fired when pills are reordered (only used if reorderable is true)
  final void Function(int oldIndex, int newIndex)? onReorder;
  
  /// Custom text style for the label (optional)
  final TextStyle? labelStyle;
  
  /// Spacing between pills horizontally
  final double spacing;
  
  /// Spacing between pills vertically (between rows)
  final double runSpacing;
  
  /// Animation duration for collapse/expand
  final Duration animationDuration;

  const PillContainer({
    super.key,
    required this.label,
    this.reorderable = false,
    this.collapsed = false,
    required this.onToggle,
    required this.children,
    this.onReorder,
    this.labelStyle,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (tappable to toggle collapse)
        _buildHeader(),

        // Collapsible Content Area
        _buildCollapsibleContent(),
      ],
    );
  }

  /// Builds the tappable header row with label and animated arrow
  Widget _buildHeader() {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Text(
            label,
            style: labelStyle ?? const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: collapsed ? -0.25 : 0, // Points right when collapsed, down when expanded
            duration: animationDuration,
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the animated collapsible content section
  Widget _buildCollapsibleContent() {
    return AnimatedCrossFade(
      firstChild: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: reorderable ? _buildReorderableWrap() : _buildStaticWrap(),
      ),
      secondChild: const SizedBox.shrink(),
      crossFadeState: collapsed 
          ? CrossFadeState.showSecond 
          : CrossFadeState.showFirst,
      duration: animationDuration,
    );
  }

  /// Builds a ReorderableWrap for drag-and-drop reordering
  Widget _buildReorderableWrap() {
    return ReorderableWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: WrapAlignment.start,
      needsLongPressDraggable: false,
      onReorder: onReorder ?? (_, __) {},
      buildDraggableFeedback: _buildDraggableFeedback,
      children: children,
    );
  }

  /// Builds a standard static Wrap (no reordering)
  Widget _buildStaticWrap() {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }

  /// Builds the visual feedback widget shown while dragging
  Widget _buildDraggableFeedback(
    BuildContext context,
    BoxConstraints constraint,
    Widget widget,
  ) {
    return Material(
      elevation: 6.0,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: constraint,
        child: widget,
      ),
    );
  }
}

/// A helper widget that wraps children for use in ReorderableWrap.
/// Use this when you need to provide a key for reorderable items.
/// 
/// Example:
/// ```dart
/// ReorderablePillWrapper(
///   key: ValueKey(item.id),
///   child: ClusterPill(label: item.name),
/// )
/// ```
class ReorderablePillWrapper extends StatelessWidget {
  final Widget child;

  const ReorderablePillWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}