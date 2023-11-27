import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Make sure to import your Firebase options
import 'LoginPage.dart';
import 'auth.dart' as auth;
import 'read_add.dart' as read_add;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Notes Application with Firebase'),
      routes: {
        '/readAdd': (context) => read_add.FirestorePage(),
        '/auth': (context) => auth.AuthPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Function to navigate to the authentication page
  void _navigateToAuthPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => auth.AuthPage()),
    );
  }

  // Function to navigate to the read and add notes page
  void _navigateToReadAddPage() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => read_add.FirestorePage()),
      );
    } else {
      _navigateToAuthPage();
    }
  }

  // Function to navigate to the login page
  void _navigateToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Function to sign out the user
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // Show login icon if the user is not logged in
          if (FirebaseAuth.instance.currentUser == null)
            IconButton(
              icon: Icon(Icons.login),
              onPressed: _navigateToAuthPage,
            ),
          // Show user icon if the user is not logged in
          if (FirebaseAuth.instance.currentUser == null)
            IconButton(
              icon: Icon(Icons.person),
              onPressed: _navigateToLoginPage,
            ),
          // Show add icon if the user is logged in
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _navigateToReadAddPage,
            ),
          // Show logout icon if the user is logged in
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show a message if the user is not logged in
            if (FirebaseAuth.instance.currentUser == null)
              Text(
                'Log in to access notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
