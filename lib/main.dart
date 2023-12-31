import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namer_app/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class CatImage {
  final String url;

  CatImage({required this.url});

  factory CatImage.fromJson(Map<String, dynamic> json) {
    return CatImage(url: json['url']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url};
  }
}

class CatCubit extends Cubit<List<CatImage>> {
  CatCubit() : super([]);

  void fetchCatImages() async {
    try {
      final response = await http.get(
          Uri.parse('https://api.thecatapi.com/v1/images/search?limit=10'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<CatImage> catImages =
        data.map((json) => CatImage.fromJson(json)).toList();
        emit(catImages);
      } else {
        throw Exception('Failed to load cat images');
      }
    } catch (e) {
      throw (Exception('Failed to load cat images: $e'));
    }
  }
}

class AuthenticationCubit extends Cubit<String> {
  AuthenticationCubit() : super('');

  Future<void> authenticate(String login, String password) async {
    if (login.isNotEmpty && password.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('login', login);
      emit(login);
    } else {
      emit('');
    }
  }

  Future<void> checkAuthenticationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String authenticatedUser = prefs.getString('login') ?? '';
    emit(authenticatedUser);
  }

  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('login');
    emit('');
  }
}

class InternetCubit extends Cubit<bool> {
  InternetCubit() : super(false);

  StreamSubscription? _subscription;

  void checkInternetConnection() {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      bool isConnected = await _isConnected(result);
      emit(isConnected);
    });
  }

  Future<bool> _isConnected(ConnectivityResult result) async {
    return result != ConnectivityResult.none;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class FavoriteCubit extends Cubit<List<CatImage>> {
  FavoriteCubit() : super([]);

  SharedPreferences? _prefs;

  void initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    emit(getFavorites());
  }

  List<CatImage> getFavorites() {
    final List<String>? favoriteStrings = _prefs?.getStringList('favorites');
    if (favoriteStrings == null || favoriteStrings.isEmpty) {
      return [];
    }
    return favoriteStrings.map((json) {
      final Map<String, dynamic> map = jsonDecode(json);
      return CatImage.fromJson(map);
    }).toList();
  }

  void updateFavorites(List<CatImage> updatedFavorites) {
    _prefs?.setStringList('favorites',
        updatedFavorites.map((cat) => jsonEncode(cat.toJson())).toList());
    emit(updatedFavorites);
  }

  void addToFavorites(CatImage catImage) {
    final List<CatImage> updatedFavorites = List.from(state);
    updatedFavorites.add(catImage);
    updateFavorites(updatedFavorites);
  }

  void removeFromFavorites(CatImage catImage) {
    final List<CatImage> updatedFavorites = List.from(state);
    updatedFavorites.remove(catImage);
    updateFavorites(updatedFavorites);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CatCubit()..fetchCatImages()),
        BlocProvider(
            create: (context) => FavoriteCubit()..initializePreferences()),
        BlocProvider(
            create: (context) =>
            AuthenticationCubit()..checkAuthenticationStatus()),
        BlocProvider(
            create: (context) => InternetCubit()..checkInternetConnection()),
      ],
      child: MaterialApp(
        title: 'ПУПУПУ',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BlocBuilder<AuthenticationCubit, String>(
          builder: (context, isAuthenticated) {
            if (isAuthenticated.isNotEmpty) {
              return const MyHomePage();
            } else {
              return const SplashScreen();
            }
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Картинки котиков'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              context.read<AuthenticationCubit>().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? const GeneratorPage() : const FavoritesPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Картинки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}


class GeneratorPage extends StatelessWidget {
  const GeneratorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationCubit, String>(
      builder: (context, isAuthenticated) {
        return BlocBuilder<CatCubit, List<CatImage>>(
          builder: (context, catImages) {
            if (catImages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            var catImage = catImages.first;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FullScreenImagePage(imageUrl: catImage.url),
                        ),
                      );
                    },
                    child: Hero(
                      tag: catImage.url,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              catImage.url,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAuthenticated.isNotEmpty
                        ? 'Вот котики для тебя, $isAuthenticated'
                        : 'Необходима авторизация',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CatCubit>().fetchCatImages();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Послѣдьнѩі'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final favoriteCubit = context.read<FavoriteCubit>();
                      final List<CatImage> updatedFavorites =
                      List.from(favoriteCubit.state);
                      updatedFavorites.add(catImage);
                      favoriteCubit.updateFavorites(updatedFavorites);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Любо'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteCubit, List<CatImage>>(
      builder: (context, favorites) {
        if (favorites.isEmpty) {
          return const Center(child: Text('Нет избранных'));
        }

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () {
                      context
                          .read<FavoriteCubit>()
                          .removeFromFavorites(favorites[index]);
                    },
                  ),
                  title: Image.network(
                    favorites[index].url,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _loginController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторизация'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Логин',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Пароль',
                ),
                obscureText: true,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final login = _loginController.text;
                final password = _passwordController.text;

                if (login.isNotEmpty && password.isNotEmpty) {
                  context.read<AuthenticationCubit>().authenticate(
                    login,
                    password,
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пожалуйста, заполните поля Логин и Пароль'),
                    ),
                  );
                }
              },
              child: const Text('Авторизоваться'),
            ),
          ],
        ),
      ),
    );
  }
}


class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Login',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthenticationCubit>().authenticate(
                  _loginController.text,
                  _passwordController.text,
                );
              },
              child: const Text('Authenticate'),
            ),
          ],
        ),
      ),
    );
  }
}
