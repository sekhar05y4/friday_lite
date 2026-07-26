import '../../models/contact.dart';

abstract class IContactsRepository {
  Future<List<Contact>> searchContacts(String query);
  Future<int> addContact(Contact contact);
}
