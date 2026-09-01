import 'package:flutter/material.dart';

class AdBannerWidget extends StatelessWidget {
  final double height;

  const AdBannerWidget({Key? key, this.height = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace this empty container with an actual AdMob banner widget later.
    return Container(
      height: height,
      width: double.infinity,
    );
  }
}