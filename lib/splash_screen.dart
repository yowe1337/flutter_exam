import 'main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сплеш-скрин'),
      ),
      body: Center(
        child: BlocBuilder<AuthenticationCubit, String>(
          builder: (context, isAuthenticated) {
            return ElevatedButton(
              onPressed: () {
                if (isAuthenticated.isNotEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(),
                      fullscreenDialog: true,
                    ),
                  );
                } else {
                  // Navigate to authentication screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthenticationScreen(),
                    ),
                  );
                }
              },
              child: Text(
                isAuthenticated.isNotEmpty ? 'Вернуться на главную' : 'Авторизоваться',
              ),
            );
          },
        ),
      ),
    );
  }
}
