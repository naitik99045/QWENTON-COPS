import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/phone_input_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/onboarding/presentation/business_onboarding_screen.dart';
import '../../main.dart';

import '../../features/products/presentation/product_list_screen.dart';
import '../../features/products/presentation/add_edit_product_screen.dart';
import '../../features/orders/presentation/order_feed_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const BusinessOnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardDemoScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderFeedScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/verify-otp';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (!authState.hasCompletedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isLoggingIn || isOnboarding) {
        return '/dashboard';
      }

      return null;
    },
  );
});
