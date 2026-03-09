// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../api_config.dart'; // 회원가입 페이지에서 사용한 api_config를 재사용합니다.
import '../signup_page.dart';
import '../main.dart';
import '../user_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // 1. 폼 유효성 검사
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // 2. 서버로 보낼 데이터 준비
    final Map<String, dynamic> loginData = {
      'loginId': _idCtrl.text,
      'password': _passwordCtrl.text,
    };

    // 3. Dio를 사용한 서버 통신
    final dio = Dio();
    // 실제 로그인 API 엔드포인트로 변경해야 합니다.
    const String apiUrl = '$apiBaseUrl/api/login';

    try {
      final response = await dio.post(
        apiUrl,
        data: jsonEncode(loginData),
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      // 4. 서버 응답 처리
      if (response.statusCode == 200) {

        print('--- [로그인 성공 응답 데이터 확인] ---');
        print('데이터 타입: ${response.data.runtimeType}');
        print('데이터 내용: ${response.data}');
        print('------------------------------------');
        // --- [디버깅 끝] ---

        // 2. 받은 데이터를 변수에 담습니다.
        var responseData = response.data;

        // 3. 만약 데이터가 String(문자열)이라면, Map(JSON) 형태로 변환을 시도합니다.
        if (responseData is String) {
          try {
            responseData = jsonDecode(responseData);
          } catch (e) {
            print('JSON 파싱 에러: $e');
            // 파싱 실패 시, 더 이상 진행하지 않고 함수를 종료할 수 있습니다.
          }
        }

        // 4. 이제 데이터가 Map 형태일 것이므로, 'nickname' 키가 있는지 확인하고 값을 저장합니다.
        if (responseData is Map && responseData.containsKey('nickname')) {
          UserSession.nickname = responseData['nickname'];
          // 성공적으로 저장되었는지 확인용 print
          print('>>> UserSession에 닉네임 저장 성공: ${UserSession.nickname}');
        } else {
          // 'nickname' 키를 찾지 못한 경우
          print('!!! 응답 데이터에서 "nickname" 키를 찾지 못했습니다.');
        }
        // 성공적으로 로그인 되었을 때
        // 예: 토큰 저장, 메인 페이지로 이동 등
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 성공했습니다!')),
        );
        // TODO: 로그인 성공 후 다음 페이지로 이동하는 로직 구현
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
      } else {
        // 서버에서 다른 상태 코드로 응답했을 때 (예: 401 Unauthorized)
        final String errorMessage = response.data['message'] ?? '아이디 또는 비밀번호가 일치하지 않습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } on DioException catch (e) {
      String errorMessage = '로그인에 실패했습니다. 네트워크 상태를 확인해주세요.';

      if (e.response != null) {
        // 디버깅을 위해 서버가 보낸 데이터의 타입과 내용을 출력합니다.
        print('서버 응답 데이터 타입: ${e.response!.data.runtimeType}');
        print('서버 응답 데이터 내용: ${e.response!.data}');

        final responseData = e.response!.data;

        // ▼▼▼ 타입을 안전하게 확인하고 처리하는 핵심 로직 ▼▼▼
        if (responseData is Map) {
          // 경우 1: 데이터가 이미 Map 형태로 파싱된 경우
          errorMessage = responseData['message'] ?? '서버로부터 메시지를 받지 못했습니다.';
        } else if (responseData is String) {
          // 경우 2: 데이터가 String 형태인 경우 (JSON 문자열일 가능성 높음)
          try {
            final decodedJson = jsonDecode(responseData); // 문자열을 JSON(Map)으로 변환 시도
            if (decodedJson is Map) {
              errorMessage = decodedJson['message'] ?? '서버 메시지 형식이 올바르지 않습니다.';
            } else {
              errorMessage = responseData; // JSON이 아닌 순수 문자열이면 그대로 사용
            }
          } catch (jsonError) {
            // JSON 변환에 실패하면 원본 문자열을 에러 메시지로 사용
            errorMessage = '아이디 또는 비밀번호를 다시 확인해주세요.';
          }
        } else {
          // 경우 3: 예상치 못한 다른 타입의 데이터가 온 경우
          errorMessage = '서버로부터 예상치 못한 형식의 응답을 받았습니다.';
        }
        // ▲▲▲ 핵심 로직 끝 ▲▲▲

      } else {
        // 서버에 아예 연결하지 못한 경우 (네트워크 오류 등)
        errorMessage = '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
        print('요청 에러 (서버 응답 없음): ${e.message}');
      }

      // 비동기 작업 후 UI를 업데이트할 때는 mounted 체크가 안전합니다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
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
        title: const Text('로그인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    // 살짝 어두운 오버레이로 가독성 확보
                    color: Colors.black.withOpacity(0.72),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction, // 유효성 검사 자동 실행
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '계정 로그인',
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
                            decoration: InputDecoration(
                              hintText: '아이디',
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
                              if ((v ?? '').trim().isEmpty) return '아이디를 입력하세요';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _FieldLabel('비밀번호', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onLogin(),
                            decoration: InputDecoration(
                              hintText: '비밀번호',
                              hintStyle: TextStyle(color: hintColor),
                              prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white70),
                                onPressed: () => setState(() => _obscure = !_obscure),
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
                              if ((v ?? '').isEmpty) return '비밀번호를 입력하세요';
                              if ((v!).length < 6) return '6자 이상 입력하세요';
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : () {
                                // TODO: 비밀번호 찾기 페이지로 이동
                              },
                              child: const Text('비밀번호 찾기', style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _onLogin,
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
                                  : const Text('로그인', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _loading ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpPage()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('회원가입', style: TextStyle(fontWeight: FontWeight.w600)),
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