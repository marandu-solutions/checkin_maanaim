class EventoInscritos {
  final String? id;
  final String? inicio;
  final String? fim;
  final String? local;
  final String? qtdInscritos;
  final String? qtdSeminaristas;
  final String? qtdParticipou;
  final String? classesDesc;
  final String? lastUpdateTime;
  final List<Inscrito> inscritos;

  EventoInscritos({
    this.id,
    this.inicio,
    this.fim,
    this.local,
    this.qtdInscritos,
    this.qtdSeminaristas,
    this.qtdParticipou,
    this.classesDesc,
    this.lastUpdateTime,
    required this.inscritos,
  });

  factory EventoInscritos.fromJson(Map<String, dynamic> json) {
    return EventoInscritos(
      id: json['id']?.toString(),
      inicio: json['inicio']?.toString(),
      fim: json['fim']?.toString(),
      local: json['dsc_local']?.toString(),
      qtdInscritos: json['qtd_inscritos']?.toString(),
      qtdSeminaristas: json['qtd_seminaristas']?.toString(),
      qtdParticipou: json['qtd_participou']?.toString(),
      classesDesc: json['classes_desc']?.toString(),
      lastUpdateTime: json['last_update_time']?.toString(),
      inscritos: json['inscritos'] is List
          ? (json['inscritos'] as List)
              .map((e) => Inscrito.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Inscrito>[],
    );
  }
}

class Inscrito {
  final String? id;
  final String? visitanteId;
  final String? idToken;
  final String? leitoNumero;
  final String? leitoPosicao;
  final String? leitoQuartoNumero;
  final String? participou;
  final String? lidoAt;
  final String? equipeId;
  final String? numAssento;
  final String? seminarioId;
  final String? dscAuditorio;
  final String? dscAlojamento;
  final String? imgFotoNome;
  final String? nome;
  final String? dscLocal;
  final String? documento;
  final String? sigla;
  final String? dscClasse;
  final String? dscEquipe;
  final String? codTipoObreiro;
  final String? isPastor;

  Inscrito({
    this.id,
    this.visitanteId,
    this.idToken,
    this.leitoNumero,
    this.leitoPosicao,
    this.leitoQuartoNumero,
    this.participou,
    this.lidoAt,
    this.equipeId,
    this.numAssento,
    this.seminarioId,
    this.dscAuditorio,
    this.dscAlojamento,
    this.imgFotoNome,
    this.nome,
    this.dscLocal,
    this.documento,
    this.sigla,
    this.dscClasse,
    this.dscEquipe,
    this.codTipoObreiro,
    this.isPastor,
  });

  bool get presente => participou == '1';

  factory Inscrito.fromJson(Map<String, dynamic> json) {
    return Inscrito(
      id: json['id']?.toString(),
      visitanteId: json['visitante_id']?.toString(),
      idToken: json['id_token']?.toString(),
      leitoNumero: json['leito_numero']?.toString(),
      leitoPosicao: json['leito_posicao']?.toString(),
      leitoQuartoNumero: json['leito_quarto_numero']?.toString(),
      participou: json['participou']?.toString(),
      lidoAt: json['lido_at']?.toString(),
      equipeId: json['equipe_id']?.toString(),
      numAssento: json['num_assento']?.toString(),
      seminarioId: json['seminario_id']?.toString(),
      dscAuditorio: json['dsc_auditorio']?.toString(),
      dscAlojamento: json['dsc_alojamento']?.toString(),
      imgFotoNome: json['img_foto_nome']?.toString(),
      nome: json['nom_seminarista']?.toString(),
      dscLocal: json['dsc_local']?.toString(),
      documento: json['documento']?.toString(),
      sigla: json['sigla']?.toString(),
      dscClasse: json['dsc_classe']?.toString(),
      dscEquipe: json['dsc_equipe']?.toString(),
      codTipoObreiro: json['cod_tipo_obreiro']?.toString(),
      isPastor: json['is_pastor']?.toString(),
    );
  }
}

