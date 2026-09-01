import 'package:flutter/material.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final Widget? lockedWidget;

  const PremiumGate({
    Key? key,
    required this.child,
    this.lockedWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Later, add logic here to check subscription_status from the profile.
    return child;
  }
}