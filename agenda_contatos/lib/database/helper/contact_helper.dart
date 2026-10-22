import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../model/contact_model.dart';

class ContactHelper {
  static final ContactHelper _instance = ContactHelper.internal();

  factory ContactHelper() => _instance;

  ContactHelper.internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }

    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final databaseFile = kIsWeb
        ? 'contactsDB.db'
        : join(await getDatabasesPath(), 'contactsDB.db');

    return openDatabase(
      databaseFile,
      version: 2,
      onCreate: (Database db, int newVersion) async {
        await db.execute('''
          CREATE TABLE $contactTable(
            $idColumn INTEGER PRIMARY KEY,
            $nameColumn TEXT,
            $emailColumn TEXT,
            $phoneColumn TEXT,
            $imgColumn TEXT,
            $cepColumn TEXT,
            $streetColumn TEXT,
            $numberColumn TEXT,
            $complementColumn TEXT,
            $neighborhoodColumn TEXT,
            $cityColumn TEXT,
            $stateColumn TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          for (final column in [
            cepColumn,
            streetColumn,
            numberColumn,
            complementColumn,
            neighborhoodColumn,
            cityColumn,
            stateColumn,
          ]) {
            await db.execute('ALTER TABLE $contactTable ADD COLUMN $column TEXT');
          }
        }
      },
    );
  }

  Future<Contact> saveContact(Contact contact) async {
    final Database dbContact = await db;
    contact.id = await dbContact.insert(contactTable, contact.toMap());
    return contact;
  }

  Future<Contact?> getContact(int id) async {
    final Database dbContact = await db;
    final List<Map<String, dynamic>> maps = await dbContact.query(
      contactTable,
      where: "$idColumn = ?",
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }

    return null;
  }

  Future<List<Contact>> getAllContacts() async {
    final Database dbContact = await db;
    final List<Map<String, dynamic>> listMap =
        await dbContact.query(contactTable);

    return listMap.map(Contact.fromMap).toList();
  }

  Future<int> deleteContact(int id) async {
    final Database dbContact = await db;
    return dbContact.delete(
      contactTable,
      where: "$idColumn = ?",
      whereArgs: [id],
    );
  }

  Future<int> updateContact(Contact contact) async {
    final Database dbContact = await db;
    return dbContact.update(
      contactTable,
      contact.toMap(),
      where: "$idColumn = ?",
      whereArgs: [contact.id],
    );
  }
}
