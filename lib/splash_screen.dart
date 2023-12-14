import 'main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Center(
        child: BlocBuilder<AuthenticationCubit, bool>(
          builder: (context, isAuthenticated) {
            return ElevatedButton(
              onPressed: () {
                if (isAuthenticated) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  );
                } else {
                  context.read<AuthenticationCubit>().authenticate();
                }
              },
              child: Text(
                  isAuthenticated ? 'Вернуться на главную' : 'Authenticate'),
            );
          },
        ),
      ),
    );
  }
}
