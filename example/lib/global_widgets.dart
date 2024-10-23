import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final bool enabled;

  const PlatformButton({
    required this.text,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return (!kIsWeb && (Platform.isMacOS || Platform.isIOS))
        ? CupertinoButton.filled(
            onPressed: enabled ? onPressed : null,
            // color: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            disabledColor: Colors.grey,
            child: Text(text),
          )
        : ElevatedButton(
            onPressed: enabled ? onPressed : null,
            child: Text(text),
          );
  }
}

class ResponsiveButtonsGrid extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveButtonsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const tileWidth = 150;
        const tileHeight = 500;
        final count = constraints.maxWidth ~/ tileWidth;
        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: tileHeight / tileWidth,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
