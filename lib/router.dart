import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/item_prefill.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/item/item_detail_screen.dart';
import 'screens/item/item_form_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  // ทุกครั้งที่สถานะ login เปลี่ยน (login / logout / สมัครเสร็จ) ให้ router เช็ก redirect ใหม่
  refreshListenable: _AuthStateListenable(),
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final onAuthPage =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!loggedIn && !onAuthPage) return '/login';
    if (loggedIn && onAuthPage) return '/';
    return null; // ไม่ต้อง redirect
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // หน้าแท็บ (มี bottom nav) — แต่ละแท็บจำ state ของตัวเองไว้
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // หน้าที่กดเข้าไป (ไม่มี bottom nav) — '/item/new' ต้องอยู่ก่อน '/item/:id'
    GoRoute(
      path: '/scan',
      pageBuilder: (context, state) =>
          _transitionPage(state, const ScanScreen(), slide: false),
    ),
    GoRoute(
      path: '/item/new',
      // มาจากหน้า Scan จะส่งบาร์โค้ด/ชื่อ/รูปมาใน extra (กรอกเองจะเป็น null)
      pageBuilder: (context, state) => _transitionPage(
        state,
        ItemFormScreen(prefill: state.extra as ItemPrefill?),
      ),
    ),
    GoRoute(
      path: '/item/:id',
      pageBuilder: (context, state) => _transitionPage(
        state,
        ItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
      routes: [
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) => _transitionPage(
            state,
            ItemFormScreen(itemId: state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);

/// เปลี่ยนหน้าแบบจางเข้า + เลื่อนขึ้นเล็กน้อย (หน้า Scan ใช้แค่จาง เพราะเป็นกล้องเต็มจอ)
/// ใช้ CustomTransitionPage แทน builder ปกติ เพื่อกำหนดแอนิเมชันเองได้
CustomTransitionPage<void> _transitionPage(
  GoRouterState state,
  Widget child, {
  bool slide = true,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final faded = FadeTransition(opacity: curved, child: child);
      if (!slide) return faded;
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: faded,
      );
    },
  );
}

/// แปลง Stream ของ authStateChanges ให้เป็น Listenable ที่ GoRouter ฟังได้
class _AuthStateListenable extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  _AuthStateListenable() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
