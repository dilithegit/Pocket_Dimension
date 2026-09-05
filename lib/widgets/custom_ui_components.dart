import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Custom Painter that renders illuminated gold corner flourishes (ornamental L-brackets)
/// on dark card containers.
class GoldCornerFlourishPainter extends CustomPainter {
  final Color goldColor;
  final double flourishSize;
  final double strokeWidth;

  const GoldCornerFlourishPainter({
    this.goldColor = AppColors.accent,
    this.flourishSize = 14.0,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final goldPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    // Draw main container border
    final RRect outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(outerRect, borderPaint);

    final double w = size.width;
    final double h = size.height;
    final double len = flourishSize;

    // Top-Left Corner L-Flourish
    canvas.drawLine(const Offset(0, 8), Offset(0, 8 + len), goldPaint);
    canvas.drawLine(const Offset(8, 0), Offset(8 + len, 0), goldPaint);

    // Top-Right Corner L-Flourish
    canvas.drawLine(Offset(w, 8), Offset(w, 8 + len), goldPaint);
    canvas.drawLine(Offset(w - 8, 0), Offset(w - 8 - len, 0), goldPaint);

    // Bottom-Left Corner L-Flourish
    canvas.drawLine(Offset(0, h - 8), Offset(0, h - 8 - len), goldPaint);
    canvas.drawLine(Offset(8, h), Offset(8 + len, h), goldPaint);

    // Bottom-Right Corner L-Flourish
    canvas.drawLine(Offset(w, h - 8), Offset(w, h - 8 - len), goldPaint);
    canvas.drawLine(Offset(w - 8, h), Offset(w - 8 - len, h), goldPaint);
  }

  @override
  bool shouldRepaint(covariant GoldCornerFlourishPainter oldDelegate) =>
      oldDelegate.goldColor != goldColor ||
      oldDelegate.flourishSize != flourishSize ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// IlluminatedSaveSlotCard — Custom save slot card with gold corner flourishes and inner glow.
class IlluminatedSaveSlotCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const IlluminatedSaveSlotCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const GoldCornerFlourishPainter(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// GoldBorderedPlayerBubble — Custom chamfered/gold-bordered container for player inputs.
class GoldBorderedPlayerBubble extends StatelessWidget {
  final String text;

  const GoldBorderedPlayerBubble({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10.0,
          ),
          child: Text(
            text,
            style: AppTypography.uiBody.copyWith(
              color: AppColors.inkPrimary,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// IlluminatedButton — Primary action button with subtle gold glow and serif/sans typography.
class IlluminatedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const IlluminatedButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    final Color bgColor = isPrimary
        ? AppColors.accent
        : AppColors.surfaceElevated;
    final Color textColor = isPrimary
        ? AppColors.background
        : AppColors.inkPrimary;
    final Color borderColor = isPrimary
        ? AppColors.accentVariant
        : AppColors.accent.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: isPrimary && enabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: enabled ? bgColor : bgColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ] else if (icon != null) ...[
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTypography.uiHeader.copyWith(
                    color: textColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// GoldIconButton — Custom icon button with gold outline and press ripple.
class GoldIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const GoldIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.accent, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8.0),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// GoldOutlineChip — Quick-reply suggestion chip with thin gold outline.
class GoldOutlineChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GoldOutlineChip({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 7.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.10),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '❖ ',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10.0,
                ),
              ),
              Text(
                label,
                style: AppTypography.uiCaption.copyWith(
                  color: AppColors.inkPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// IlluminatedHeaderBar — Custom illuminated title bar replacing default AppBar chrome.
class IlluminatedHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  const IlluminatedHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.uiHeader.copyWith(
                        color: AppColors.inkPrimary,
                        fontSize: 17.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            '❖ ',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            subtitle!,
                            style: AppTypography.uiCaption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
