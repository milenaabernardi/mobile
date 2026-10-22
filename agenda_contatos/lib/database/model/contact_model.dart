String idColumn = "idColumn";
String nameColumn = "nameColumn";
String emailColumn = "emailColumn";
String phoneColumn = "phoneColumn";
String imgColumn = "imgColumn";
String cepColumn = "cepColumn";
String streetColumn = "streetColumn";
String numberColumn = "numberColumn";
String complementColumn = "complementColumn";
String neighborhoodColumn = "neighborhoodColumn";
String cityColumn = "cityColumn";
String stateColumn = "stateColumn";
String contactTable = "contactTable";

class Contact {
  Contact({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.img,
    this.cep = "",
    this.street = "",
    this.number = "",
    this.complement = "",
    this.neighborhood = "",
    this.city = "",
    this.state = "",
  });

  int? id;
  String name;
  String email;
  String phone;
  String? img;

  // Endereço
  String cep;
  String street; // Logradouro
  String number;
  String complement;
  String neighborhood; // Bairro
  String city; // Cidade
  String state; // UF

  Contact.fromMap(Map<String, dynamic> map)
      : id = map[idColumn],
        name = map[nameColumn] ?? "",
        email = map[emailColumn] ?? "",
        phone = map[phoneColumn] ?? "",
        img = map[imgColumn],
        cep = map[cepColumn] ?? "",
        street = map[streetColumn] ?? "",
        number = map[numberColumn] ?? "",
        complement = map[complementColumn] ?? "",
        neighborhood = map[neighborhoodColumn] ?? "",
        city = map[cityColumn] ?? "",
        state = map[stateColumn] ?? "";

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      nameColumn: name,
      emailColumn: email,
      phoneColumn: phone,
      imgColumn: img,
      cepColumn: cep,
      streetColumn: street,
      numberColumn: number,
      complementColumn: complement,
      neighborhoodColumn: neighborhood,
      cityColumn: city,
      stateColumn: state,
    };

    if (id != null) {
      map[idColumn] = id;
    }

    return map;
  }

  /// Endereço em uma linha, para exibir na lista. Vazio se não houver dados.
  String get formattedAddress {
    final streetPart = [street, number]
        .where((e) => e.trim().isNotEmpty)
        .join(', ');
    final cityPart = [city, state]
        .where((e) => e.trim().isNotEmpty)
        .join('/');
    return [streetPart, neighborhood, cityPart]
        .where((e) => e.trim().isNotEmpty)
        .join(' - ');
  }

  @override
  String toString() {
    return "Contact(id: $id, name: $name, email: $email, phone: $phone, img: $img, "
        "cep: $cep, street: $street, number: $number, complement: $complement, "
        "neighborhood: $neighborhood, city: $city, state: $state)";
  }
}
