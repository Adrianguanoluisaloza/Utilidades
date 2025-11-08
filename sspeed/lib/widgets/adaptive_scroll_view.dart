import 'package:flutter/material.dart';

/// Widget que ajusta automáticamente el padding inferior
class AdaptiveScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;
  final bool scrollable;
  final ScrollPhysics? physics;

  const AdaptiveScrollView({
    super.key,
    required this.child,
    this.customPadding,
    this.scrollable = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double bottomPadding = mediaQuery.padding.bottom;

    final EdgeInsets effectivePadding = customPadding?.copyWith(
          bottom: (customPadding?.bottom ?? 0) + bottomPadding,
        ) ??
        EdgeInsets.only(bottom: bottomPadding);

    if (scrollable) {
      return SingleChildScrollView(
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      );
    } else {
      return Padding(
        padding: effectivePadding,
        child: child,
      );
    }
  }
}

/// ListView adaptativo
class AdaptiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AdaptiveListView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double bottomPadding = mediaQuery.padding.bottom;

    final EdgeInsets effectivePadding = padding?.copyWith(
          bottom: (padding?.bottom ?? 0) + bottomPadding,
        ) ??
        EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: bottomPadding,
        );

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: effectivePadding,
      children: children,
    );
  }
}

/// ListView.builder adaptativo
class AdaptiveListViewBuilder extends StatelessWidget {
  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AdaptiveListViewBuilder({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double bottomPadding = mediaQuery.padding.bottom;

    final EdgeInsets effectivePadding = padding?.copyWith(
          bottom: (padding?.bottom ?? 0) + bottomPadding,
        ) ??
        EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: bottomPadding,
        );

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: effectivePadding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// GridView adaptativo
class AdaptiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final EdgeInsets? padding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;

  const AdaptiveGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.padding,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double bottomPadding = mediaQuery.padding.bottom;

    final EdgeInsets effectivePadding = padding?.copyWith(
          bottom: (padding?.bottom ?? 0) + bottomPadding,
        ) ??
        EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding,
        );

    return GridView.count(
      shrinkWrap: shrinkWrap,
      physics: const NeverScrollableScrollPhysics(),
      padding: effectivePadding,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }
}
