import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/helper/contact_helper.dart';
import '../database/model/contact_model.dart';
import '../utils/photo_storage.dart';
import 'contact_page.dart';

enum OrderOptions { orderAZ, orderZA }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ContactHelper helper = ContactHelper();
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final list = await helper.getAllContacts();
    if (!mounted) return;
    setState(() {
      contacts = list;
    });
  }

  Future<void> _showContactPage({Contact? contact}) async {
    final updatedContact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (context) => ContactPage(contact: contact),
      ),
    );

    if (updatedContact != null) {
      await _loadContacts();
    }
  }

  void _orderList(OrderOptions result) {
    setState(() {
      switch (result) {
        case OrderOptions.orderAZ:
          contacts.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case OrderOptions.orderZA:
          contacts.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
      }
    });
  }

  Future<void> _callContact(Contact contact) async {
    final rawPhone = contact.phone.trim();
    if (rawPhone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este contato não possui telefone.')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: rawPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o discador.')),
      );
    }
  }

  void _showOptions(BuildContext context, int index) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _callContact(contacts[index]);
                  },
                  child: const Text(
                    'Ligar',
                    style: TextStyle(color: Colors.green, fontSize: 20),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showContactPage(contact: contacts[index]);
                  },
                  child: const Text(
                    'Editar',
                    style: TextStyle(color: Colors.blue, fontSize: 20),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final contact = contacts[index];
                    if (contact.id == null) {
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro: ID do contato não encontrado.')),
                      );
                      return;
                    }

                    await helper.deleteContact(contact.id!);
                    if (!mounted) return;
                    setState(() {
                      contacts.removeAt(index);
                    });
                    Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contactCard(BuildContext context, int index) {
    final contact = contacts[index];

    final ImageProvider<Object> imageProvider =
        contactPhotoProvider(contact.img) ??
            const AssetImage('assets/imgs/image.png');
    final address = contact.formattedAddress;

    return GestureDetector(
      onTap: () => _showOptions(context, index),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.email,
                        style: const TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contact.phone,
                        style: const TextStyle(fontSize: 18),
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Contatos'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          PopupMenuButton<OrderOptions>(
            onSelected: _orderList,
            itemBuilder: (context) => const <PopupMenuEntry<OrderOptions>>[
              PopupMenuItem<OrderOptions>(
                value: OrderOptions.orderAZ,
                child: Text('Ordenar de A-Z'),
              ),
              PopupMenuItem<OrderOptions>(
                value: OrderOptions.orderZA,
                child: Text('Ordenar de Z-A'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactPage(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: contacts.isEmpty
          ? const Center(
              child: Text(
                'Nenhum contato cadastrado.\nToque em + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: contacts.length,
              itemBuilder: (context, index) => _contactCard(context, index),
            ),
    );
  }
}
