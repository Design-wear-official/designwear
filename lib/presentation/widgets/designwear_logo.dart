import 'package:flutter/material.dart';

/// The original DesignWear logo: the rainbow-thread hanger spelling "dw", on its
/// own cream tile so it looks right on both the dark and the light theme.
class DesignWearLogo extends StatelessWidget {
  const DesignWearLogo({super.key, this.size = 72});

  /// Width and height of the square tile.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'DesignWear logo',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
