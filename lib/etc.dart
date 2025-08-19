import 'package:flutter/material.dart';
import 'main.dart';
import 'login_page.dart';

//bottomappbar
class Bottom extends StatelessWidget {
  const Bottom({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: (){
                final isMainPage = ModalRoute.of(context)?.settings.name == '/main';

                if (isMainPage) {
                  // 현재 메인 페이지일 경우: 새로고침 트리거
                  homePageRefreshNotifier.value++;
                } else {
                  // 메인이 아닐 경우: 메인 페이지로 이동
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                        (route) => false, // 기존 페이지 모두 제거
                  );
                }
              }, child: const Icon(Icons.home) ),
              ElevatedButton(onPressed: (){}, child: const Icon(Icons.star) ),
              ElevatedButton(onPressed: (){}, child: const Icon(Icons.search) ),
            ]
        )
    );
  }
}

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  // 1. 이 위젯이 표시할 제목을 전달받기 위한 변수
  final String title;

  // 2. 생성자를 통해 title 값을 필수로 받도록 설정
  const TopAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // 3. 생성자에서 전달받은 title 변수를 Text 위젯에 적용
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_2_outlined),
          onPressed: () {
            // LoginPage 자체가 Scaffold를 가지고 있으므로,
            // 또 다른 Scaffold로 감싸지 않고 바로 이동합니다.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
        )
      ],
      // 여기에 공통 스타일을 적용하면 모든 페이지에 반영됩니다.
      // backgroundColor: Colors.black,
      // foregroundColor: Colors.white,
    );
  }

  // 4. PreferredSizeWidget을 구현하면 반드시 이 getter를 오버라이드해야 합니다.
  // AppBar의 표준 높이(kToolbarHeight)를 반환합니다.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

