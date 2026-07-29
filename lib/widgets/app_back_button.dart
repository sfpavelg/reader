import 'package:flutter/material.dart';

import '../theme/star_colors.dart';

/// Круглая кнопка в едином стиле (+/− на раскраске, назад и т.п.).
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.child,
    this.tooltip,
    this.onPressed,
    this.size = 36,
  });

  final Widget child;
  final String? tooltip;
  final VoidCallback? onPressed;
  final double size;

  static const outline = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    );
    final button = Material(
      color: colors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: outline, width: 1.5),
      ),
      child: onPressed == null
          ? content
          : InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: content,
            ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Кнопка «назад»: оранжевый шеврон в кружке.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: AppCircleIconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const Icon(
            Icons.chevron_left,
            size: 28,
            color: StarColors.currency,
          ),
        ),
      ),
    );
  }
}

/// Кнопка «обновить»: оранжевый refresh в том же кружке, что и «назад».
class AppRefreshButton extends StatelessWidget {
  const AppRefreshButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Обновить',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: AppCircleIconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          child: const Icon(
            Icons.refresh,
            size: 24,
            color: StarColors.currency,
          ),
        ),
      ),
    );
  }
}

/// AppBar с единой кнопкой назад (если экран можно закрыть).
PreferredSizeWidget appBar(
  BuildContext context, {
  Widget? title,
  List<Widget>? actions,
  bool implyLeading = true,
  PreferredSizeWidget? bottom,
  double? titleSpacing,
  double? leadingWidth,
  bool? centerTitle,
}) {
  final canPop = ModalRoute.of(context)?.canPop ?? false;
  final showBack = implyLeading && canPop;
  return AppBar(
    automaticallyImplyLeading: false,
    leading: showBack ? const AppBackButton() : null,
    leadingWidth: leadingWidth,
    title: title,
    actions: actions,
    bottom: bottom,
    titleSpacing: titleSpacing,
    centerTitle: centerTitle,
  );
}
