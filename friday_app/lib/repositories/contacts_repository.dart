import '../interfaces/repositories/i_contacts_repository.dart';
import '../models/contact.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository managing SQLite persistence for contacts.
class ContactsRepository implements IContactsRepository {
  ContactsRepository._();

  static final ContactsRepository instance = ContactsRepository._();

  @override
  Future<List<Contact>> searchContacts(String query) async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = query.trim().isEmpty
          ? await db.query('contacts', limit: 20)
          : await db.query(
              'contacts',
              where: 'name LIKE ? OR phone_number LIKE ?',
              whereArgs: ['%$query%', '%$query%'],
            );
      return rows.map((r) => Contact.fromMap(r)).toList();
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'ContactsRepository searchContacts error: $e');
      return [];
    }
  }

  @override
  Future<int> addContact(Contact contact) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('contacts', contact.toMap());
      FridayLogger.log(LogCategory.assistant, 'ContactsRepository: added contact #$id "${contact.name}"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'ContactsRepository addContact error: $e');
      return -1;
    }
  }
}
