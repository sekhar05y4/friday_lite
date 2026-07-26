/// A locally-cached favourite contact.
class Contact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String? relation; // e.g. 'Dad', 'Mom'

  const Contact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.relation,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'relation': relation,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as int?,
        name: map['name'] as String,
        phoneNumber: map['phone_number'] as String,
        relation: map['relation'] as String?,
      );
}
