class User {
  final String? id;
  final String? name;
  final String? email;
  final String? cpf;
  final String? secretKey;
  final List<UserLocal>? locais;

  User({this.id, this.name, this.email, this.cpf, this.secretKey, this.locais});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      name: json['nom_obreiro']?.toString() ?? json['name']?.toString(),
      email: json['email']?.toString(),
      cpf: json['num_cpf']?.toString(),
      secretKey: json['secret_key']?.toString(),
      locais: json['locais'] is List
          ? (json['locais'] as List)
                .map((e) => UserLocal.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'num_cpf': cpf,
      'secret_key': secretKey,
      'locais': locais?.map((e) => e.toJson()).toList(),
    };
  }
}

class UserLocal {
  final int? id;
  final String? descricao;
  final List<UserEvento>? eventos;

  UserLocal({this.id, this.descricao, this.eventos});

  factory UserLocal.fromJson(Map<String, dynamic> json) {
    return UserLocal(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      descricao: json['descricao'],
      eventos: json['eventos'] is List
          ? (json['eventos'] as List)
                .map((e) => UserEvento.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'eventos': eventos?.map((e) => e.toJson()).toList(),
    };
  }
}

class UserEvento {
  final int? id;
  final String? inicio;
  final String? fim;
  final String? local;
  final String? qtdInscritos;
  final String? qtdParticipou;
  final String? descricaoClasse;

  UserEvento({
    this.id,
    this.inicio,
    this.fim,
    this.local,
    this.qtdInscritos,
    this.qtdParticipou,
    this.descricaoClasse,
  });

  factory UserEvento.fromJson(Map<String, dynamic> json) {
    return UserEvento(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      inicio: json['inicio'],
      fim: json['fim'],
      local: json['dsc_local'],
      qtdInscritos: json['qtd_inscritos']?.toString(),
      qtdParticipou: json['qtd_participou']?.toString(),
      descricaoClasse: json['classes_desc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inicio': inicio,
      'fim': fim,
      'dsc_local': local,
      'qtd_inscritos': qtdInscritos,
      'qtd_participou': qtdParticipou,
      'classes_desc': descricaoClasse,
    };
  }
}
