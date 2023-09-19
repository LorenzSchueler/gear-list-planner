import 'package:flutter/material.dart';
import 'package:gear_list_planner/bool_toggle.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

class HoverScrollingText extends StatelessWidget {
  const HoverScrollingText(
    this.text, {
    this.style,
    super.key,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BoolToggle.off(),
      child: Consumer<BoolToggle>(
        builder: (context, hover, _) => MouseRegion(
          onEnter: (_) => hover.setState(true),
          onExit: (_) => hover.setState(false),
          cursor: MouseCursor.uncontrolled,
          child: hover.isOn
              ? TextScroll(
                  text,
                  style: style,
                  intervalSpaces: 10,
                )
              : Text(
                  text,
                  style: style,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}
