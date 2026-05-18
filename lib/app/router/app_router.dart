import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "package:smart_expense/shared/components/app_loading_state.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_screen.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/main_shell.dart";
import "package:smart_expense/app/providers.dart";

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.root,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        name: AppRouteNames.root,
        builder: (context, state) => const OnboardingGate(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) => const MainShell(),
      ),
    ],
  );
});

abstract final class AppRoutes {
  static const root = "/";
  static const home = "/home";
}

abstract final class AppRouteNames {
  static const root = "root";
  static const home = "home";
}

class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key});

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  late Future<bool> _onboardedFuture;

  @override
  void initState() {
    super.initState();
    _onboardedFuture = _readOnboarded();
  }

  Future<bool> _readOnboarded() async {
    final meta = await ref.read(ledgerRepositoryProvider).getMeta();
    return meta["onboarded"] == true;
  }

  void _refreshOnboarding() {
    setState(() {
      _onboardedFuture = _readOnboarded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(ledgerRepositoryProvider);
    final l10n = context.l10n;

    return FutureBuilder<bool>(
      future: _onboardedFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: AppLoadingState(message: l10n.loading));
        }

        if (snapshot.data!) {
          return const MainShell();
        }

        return OnboardingScreen(repo: repo, onDone: _refreshOnboarding);
      },
    );
  }
}
