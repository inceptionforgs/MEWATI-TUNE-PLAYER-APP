// File: lib/core/utils/premium_gate.dart

import 'package:flutter/material.dart';

/// Intentionally a pure pass-through for now — there is no real
/// subscription/entitlement backend wired up yet (no payment flow,
/// no server-side check of `profile.subscription_status` against
/// this widget). It always renders `child`, never `lockedWidget`.
///
/// This is a deliberate fail-open choice: showing premium content to
/// everyone is safe (no security claim is being made), whereas a
/// client-only check that pretends to gate content would NOT be real
/// security and would be misleading. Do not wire `lockedWidget` into
/// real gating logic here without a genuine server-side entitlement
/// check (RLS / edge function) backing it — see File 19's related fix,
/// which removes the "VIP Member" badge in the drawer for the same reason.
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
    return child;
  }
}
