import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/item/item_detail_screen.dart';
import 'screens/item/item_form_screen.dart';
import 'screens/profile/profile_screen.dart';
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
      path: '/item/new',
      builder: (context, state) => const ItemFormScreen(),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) =>
          ItemDetailScreen(itemId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) =>
              ItemFormScreen(itemId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

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
