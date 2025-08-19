// lib/pages/signup_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'api_config.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _idCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  // focus
  final _nickFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _pw2Focus = FocusNode();

  bool _obscurePw = true;
  bool _obscurePw2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nickCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    _nickFocus.dispose();
    _pwFocus.dispose();
    _pw2Focus.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    // 1. 폼 유효성 검사
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // 2. 서버로 보낼 데이터 준비 (DTO)
    final Map<String, dynamic> signUpData = {
      'loginId': _idCtrl.text,
      'nickname': _nickCtrl.text,
      'password': _pwCtrl.text,
    };

    // 3. Dio를 사용한 서버 통신
    final dio = Dio();
    // 안드로이드 에뮬레이터에서 로컬 PC의 서버에 접속할 때는 10.0.2.2를 사용합니다.
    // 실제 서버 주소로 변경해야 합니다.
    const String apiUrl = '$apiBaseUrl/signup';

    try {
      final response = await dio.post(
        apiUrl,
        data: jsonEncode(signUpData), // Map 데이터를 JSON 문자열로 변환
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      // 4. 서버 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공적으로 회원가입 되었을 때
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다!')),
        );
        Navigator.pop(context); // 이전 페이지(로그인 등)로 돌아가기
      } else {
        // 서버에서 다른 상태 코드로 응답했을 때 (예: 이메일 중복)
        final String errorMessage = response.data['message'] ?? '알 수 없는 오류가 발생했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } on DioException catch (e) {
      // 5. 네트워크 또는 서버 통신 오류 처리
      String errorMessage = '회원가입에 실패했습니다. 네트워크 상태를 확인해주세요.';
      if (e.response != null) {
        // 서버가 에러 응답을 반환한 경우 (예: 409 Conflict - 이메일 중복)
        print('Server error: ${e.response!.data}');
        errorMessage = e.response!.data['message'] ?? '서버 처리 중 오류가 발생했습니다.';
      } else {
        // 요청 설정 중에 에러가 발생한 경우 (예: 인터넷 연결 없음)
        print('Request error: ${e.message}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      // 6. 로딩 상태 해제
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Colors.grey[500];
    final labelColor = Colors.grey[300];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/background.png'),
                      fit: BoxFit.fill,
                      alignment: Alignment.center,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 0.6),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.72), // 가독성 오버레이
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '계정 만들기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _FieldLabel('아이디', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _idCtrl,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_nickFocus),
                            decoration: InputDecoration(
                              hintText: '아이디',
                              hintStyle: TextStyle(color: hintColor),
                              prefixIcon: Icon(Icons.mail_outline, color: hintColor),
                              filled: true,
                              fillColor: const Color.fromRGBO(33, 33, 33, 1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return '아이디 입력하세요';
                              //if () return '올바른 아이디 형식이 아닙니다';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          _FieldLabel('닉네임', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nickCtrl,
                            focusNode: _nickFocus,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_pwFocus),
                            decoration: InputDecoration(
                              hintText: '표시할 이름',
                              hintStyle: TextStyle(color: hintColor),
                              prefixIcon: Icon(Icons.person_outline, color: hintColor),
                              filled: true,
                              fillColor: const Color.fromRGBO(33, 33, 33, 1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return '닉네임을 입력하세요';
                              if (s.length < 2) return '닉네임은 2자 이상';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          _FieldLabel('비밀번호', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _pwCtrl,
                            focusNode: _pwFocus,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscurePw,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_pw2Focus),
                            decoration: InputDecoration(
                              hintText: '비밀번호',
                              hintStyle: TextStyle(color: hintColor),
                              prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePw ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                                onPressed: () => setState(() => _obscurePw = !_obscurePw),
                              ),
                              filled: true,
                              fillColor: const Color.fromRGBO(33, 33, 33, 1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            ),
                            validator: (v) {
                              final s = v ?? '';
                              if (s.isEmpty) return '비밀번호를 입력하세요';
                              if (s.length < 6) return '6자 이상 입력하세요';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          _FieldLabel('비밀번호 확인', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _pw2Ctrl,
                            focusNode: _pw2Focus,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscurePw2,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onSignUp(),
                            decoration: InputDecoration(
                              hintText: '비밀번호 다시 입력',
                              hintStyle: TextStyle(color: hintColor),
                              prefixIcon: Icon(Icons.lock_person_outlined, color: hintColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePw2 ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                                onPressed: () => setState(() => _obscurePw2 = !_obscurePw2),
                              ),
                              filled: true,
                              fillColor: const Color.fromRGBO(33, 33, 33, 1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            ),
                            validator: (v) {
                              if ((v ?? '').isEmpty) return '비밀번호 확인을 입력하세요';
                              if (v != _pwCtrl.text) return '비밀번호가 일치하지 않습니다';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _onSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFb38b2e), // 금빛 포인트
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: Colors.white24,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                              )
                                  : const Text('회원가입', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),

                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _loading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('로그인으로 돌아가기', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );
  }
}