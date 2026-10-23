import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '1. splash_onboarding/splash_screen.dart';
import '2. pastkey/login_screen.dart';
import 'firebase_options.dart';
import 'services/session_store.dart';
import 'services/settings_api.dart';

/// 어느 화면에서든 로그인으로 되돌릴 수 있도록 앱 전역 Navigator 를 잡아 둔다.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SessionStore.initialize();
  // 세션이 되살릴 수 없게 끊기면(재발급 실패) 로그인 화면으로 되돌린다.
  onSessionExpired = _handleSessionExpired;
  runApp(const ReMoryApp());
}

/// 저장된 세션은 이미 지워진 채로 불린다(SettingsApi._forceRelogin).
/// 여기서는 화면만 로그인으로 갈아끼운다. 스택을 비워 뒤로가기로 못 돌아오게 한다.
Future<void> _handleSessionExpired() async {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

class ReMoryApp extends StatelessWidget {
  const ReMoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      builder: (context, child) => _PhoneViewport(child: child),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBF6EE),
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
    );
  }
}

class _PhoneViewport extends StatelessWidget {
  const _PhoneViewport({required this.child});

  final Widget? child;

  static const double _designWidth = 402;
  static const double _designHeight = 874;

  /// 갤럭시 탭 S7(세로 800×1280dp) 같은 태블릿 기준. 보통 600dp 이상을 태블릿으로 본다.
  static const double _tabletShortestSide = 600;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final scale = _scaleFor(size);

    if (scale == 1) {
      final phoneSize = Size(
        size.width.clamp(0.0, _designWidth),
        size.height.clamp(0.0, _designHeight),
      );
      return _frame(
        child: SizedBox(
          width: phoneSize.width,
          height: phoneSize.height,
          child: _phone(mediaQuery.copyWith(size: phoneSize)),
        ),
      );
    }

    // 태블릿: 폰 화면을 그대로 키워 세로를 꽉 채운다. 안에서는 여전히
    // 402 폭 화면으로 그리므로 각 화면을 따로 손볼 필요가 없다.
    // 키보드·상태바 높이는 실제 픽셀 기준이라 같은 배율로 줄여서 넘긴다.
    final phoneSize = Size(_designWidth, size.height / scale);
    final scaled = mediaQuery.copyWith(
      size: phoneSize,
      devicePixelRatio: mediaQuery.devicePixelRatio * scale,
      padding: mediaQuery.padding / scale,
      viewPadding: mediaQuery.viewPadding / scale,
      viewInsets: mediaQuery.viewInsets / scale,
    );
    return _frame(
      child: SizedBox(
        width: _designWidth * scale,
        height: size.height,
        child: FittedBox(
          child: SizedBox(
            width: phoneSize.width,
            height: phoneSize.height,
            child: _phone(scaled),
          ),
        ),
      ),
    );
  }

  /// 폰은 1배 그대로. 태블릿은 폰 화면이 세로에 꼭 맞을 만큼 키운다.
  /// 가로로 눕혀 세로가 폰보다 짧으면 키울 수 없으니 폰과 같게 둔다.
  static double _scaleFor(Size size) {
    if (size.shortestSide < _tabletShortestSide) return 1;
    final fit = (size.width / _designWidth) < (size.height / _designHeight)
        ? size.width / _designWidth
        : size.height / _designHeight;
    return fit > 1 ? fit : 1;
  }

  Widget _frame({required Widget child}) => ColoredBox(
        color: const Color(0xFFFBF6EE),
        child: Center(child: child),
      );

  Widget _phone(MediaQueryData data) => MediaQuery(
        data: data,
        child: ScreenUtilInit(
          designSize: const Size(_designWidth, _designHeight),
          minTextAdapt: true,
          splitScreenMode: true,
          enableScaleWH: () => false,
          enableScaleText: () => false,
          builder: (context, _) => child ?? const SizedBox.shrink(),
        ),
      );
}
