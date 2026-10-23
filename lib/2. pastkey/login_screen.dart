// 기존 사용자 로그인 화면.
//
// 가입 때 등록해 둔 패스키(Face ID/지문)로 서명해서 세션을 다시 받는다.
// 앱을 지웠거나 기기를 바꿔 세션이 비었을 때 들어오는 입구다.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passkeys/exceptions.dart';

import '../main_shell.dart';
import '../services/auth_api.dart';
import '../services/firebase_phone_auth.dart';
import '../services/session_store.dart';
import 'signup_method_screen.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = AuthApi();
  final _phoneAuth = FirebasePhoneAuth();
  final _phoneController = TextEditingController();
  bool _busy = false;
  String _busyMessage = '패스키로 로그인 중…\n생체인증을 진행하세요';

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  String get _passkeyName => _isAndroid ? '패스키 지문인식' : 'Face ID';

  String get _passkeyGuide =>
      _isAndroid ? '등록해 두신 패스키 지문인식으로 확인해요' : '등록해 두신 Face ID / 지문으로 확인해요';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// 가입 화면으로. 스플래시에서 곧장 열렸을 때는 돌아갈 곳이 없어서
  /// pop 대신 가입 화면을 띄운다.
  void _goToSignup() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupMethodScreen()),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// 전화번호로 등록된 패스키를 찾아 생체인증 → 세션 저장 → 홈.
  Future<void> _onLogin() async {
    if (_busy) return;
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      _snack('전화번호를 확인해 주세요.');
      return;
    }

    _setBusy(true, '패스키로 로그인 중…\n생체인증을 진행하세요');
    try {
      await _enter(await _api.login(phone));
    } on PasskeyAuthCancelledException {
      _setBusy(false);
    } on NoCredentialsAvailableException {
      _setBusy(false);
      // 기기를 바꾼 경우가 대부분이다. 번호 인증으로 이 기기를 등록하게 한다.
      if (await _confirmNewDevice()) await _onRegisterThisDevice();
    } on AuthenticatorException catch (e) {
      _setBusy(false);
      _snack(_passkeyErrorMessage(e));
    } catch (e) {
      _setBusy(false);
      _snack('로그인 실패: $e');
    }
  }

  void _setBusy(bool busy, [String? message]) {
    if (!mounted) return;
    setState(() {
      _busy = busy;
      if (message != null) _busyMessage = message;
    });
  }

  Future<void> _enter(AuthResult result) async {
    await SessionStore.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      protectorId: result.protectorId,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  /// 새 기기: 문자 인증으로 본인 확인 → 이 기기에 패스키 등록 → 로그인.
  Future<void> _onRegisterThisDevice() async {
    if (_busy) return;
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      _snack('전화번호를 먼저 입력해 주세요.');
      return;
    }
    try {
      _setBusy(true, '인증번호 발송 중…');
      // Android 에서 문자가 자동으로 읽히면 코드 입력 없이 토큰이 바로 온다.
      var idToken = await _phoneAuth.sendCode(phone);
      _setBusy(false);

      if (idToken == null) {
        final code = await _promptOtp(phone);
        if (code == null || code.trim().isEmpty) return; // 취소

        _setBusy(true, '인증번호 확인 중…');
        idToken = await _phoneAuth.confirmCode(code.trim());
      }

      _setBusy(true, '이 기기에 $_passkeyName 등록 중…\n생체인증을 진행하세요');
      final result = await _api.registerThisDevice(idToken: idToken);
      await _phoneAuth.signOut();
      await _enter(result);
    } on PasskeyAuthCancelledException {
      _setBusy(false);
    } on AuthenticatorException catch (e) {
      _setBusy(false);
      _snack(_passkeyErrorMessage(e));
    } catch (e) {
      _setBusy(false);
      _snack('실패: $e');
    }
  }

  Future<bool> _confirmNewDevice() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          '기기를 바꾸셨나요?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '이 기기에는 등록된 $_passkeyName이 없어요.\n'
          '문자 인증을 하면 이 기기에서도 로그인할 수 있어요.',
          style: const TextStyle(fontSize: 13, height: 1.5, color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '문자 인증하기',
              style: TextStyle(color: _brown, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// 인증번호 입력 다이얼로그. 문자는 Firebase 가 보낸다.
  Future<String?> _promptOtp(String phone) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          '인증번호 입력',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$phone 로 보낸 6자리 번호를 입력하세요.',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              '확인',
              style: TextStyle(color: _brown, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  /// 패키지 예외는 toString 이 'Instance of ...' 로 찍혀서 그대로 보여주면
  /// 알아볼 수 없다. 사용자가 할 수 있는 일로 바꿔 말한다.
  String _passkeyErrorMessage(AuthenticatorException e) => switch (e) {
        NoCredentialsAvailableException() =>
          '이 기기에는 등록된 $_passkeyName이 없어요.',
        MissingGoogleSignInException() ||
        SyncAccountNotAvailableException() =>
          '패스키를 쓰려면 기기에 Google 계정으로 로그인되어 있어야 해요.',
        DeviceNotSupportedException() ||
        PasskeyUnsupportedException() =>
          '이 기기는 패스키를 지원하지 않아요.',
        TimeoutException() => '시간이 초과됐어요. 다시 시도해 주세요.',
        _ => '로그인 실패: $e',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 32.h,
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: Icon(
                                Icons.chevron_left,
                                color: _dark,
                                size: 21.sp,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 28.w),
                        Expanded(
                          child: Text(
                            '로그인',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                            ),
                          ),
                        ),
                        SizedBox(width: 28.w),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),
                        Text(
                          '다시 오셨네요',
                          style: TextStyle(
                            fontSize: 23.sp,
                            height: 1.25,
                            color: _dark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '가입할 때 쓰신 전화번호를 넣어주세요.\n비밀번호 없이 $_passkeyName으로 바로 들어갑니다.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            height: 1.55,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 30.h),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Text(
                            '전화번호',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: _dark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 42.h,
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _onLogin(),
                            cursorColor: _brown,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _dark,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '전화번호를 입력하세요',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFFB9ACA2),
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: _line),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: _brown),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Icon(
                            Icons.center_focus_weak,
                            size: 60.sp,
                            color: _brown,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Center(
                          child: Text(
                            _passkeyGuide,
                            style: TextStyle(
                              fontSize: 9.sp,
                              height: 1.35,
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _onLogin,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _busy
                                  ? const Color(0xFFD2C5BC)
                                  : _brown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_open_rounded, size: 16.sp),
                                SizedBox(width: 5.w),
                                Text(
                                  '$_passkeyName으로 로그인',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : _onRegisterThisDevice,
                            child: Text(
                              '기기를 바꾸셨나요? 이 기기 등록하기',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _brown,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : _goToSignup,
                            child: Text(
                              '처음이신가요? 가입하기',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                  Container(
                    width: 58.w,
                    height: 3.h,
                    margin: EdgeInsets.only(bottom: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7B8AE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16.h),
                    Text(
                      _busyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
