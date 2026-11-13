import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Início'), actions: [
        IconButton(icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut()),
      ]),
      body: Padding(padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text('Olá, ${user.email}',
                style: const TextStyle(fontSize: 20)),
            Card(child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Meu perfil'))),
            Card(child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'))),
          ])),
      bottomNavigationBar: BottomNavigationBar(items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Início'),
        BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'Buscar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Perfil'),
      ]),
    );
  }
}
