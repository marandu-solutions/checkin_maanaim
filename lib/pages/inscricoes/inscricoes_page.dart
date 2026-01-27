import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inscrito_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/evento_service.dart';
import '../../themes/app_theme.dart';

class InscricoesPage extends StatefulWidget {
  final UserEvento evento;

  const InscricoesPage({super.key, required this.evento});

  @override
  State<InscricoesPage> createState() => _InscricoesPageState();
}

class _InscricoesPageState extends State<InscricoesPage> {
  late Future<EventoInscritos> _future;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final service = EventoService(auth);
    final id = widget.evento.id?.toString() ?? '';
    _future = service.getInscritos(id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: FutureBuilder<EventoInscritos>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Erro ao carregar inscritos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null || data.inscritos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Nenhum inscrito encontrado para este seminário.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final inscritos = data.inscritos;
                final header = _buildHeader(data);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 16),
                      Expanded(
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildList(inscritos)),
                                ],
                              )
                            : _buildList(inscritos),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(EventoInscritos data) {
    final titulo =
        data.classesDesc ?? widget.evento.descricaoClasse ?? 'Seminário';
    final local = data.local ?? widget.evento.local ?? '';
    final dataInicio = data.inicio ?? widget.evento.inicio ?? '';
    final inscritos = data.qtdInscritos ?? widget.evento.qtdInscritos ?? '0';
    final presentes = data.qtdParticipou ?? widget.evento.qtdParticipou ?? '0';

    final totalInt = int.tryParse(inscritos) ?? 0;
    final presentesInt = int.tryParse(presentes) ?? 0;
    final faltantesInt = totalInt - presentesInt;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (local.isNotEmpty)
            Text(
              local,
              style: Colors.white70 == null
                  ? const TextStyle()
                  : const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          if (dataInicio.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _formatDateBr(dataInicio),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip(
                label: 'Inscritos',
                value: inscritos,
                color: Colors.white,
                background: Colors.white.withOpacity(0.12),
              ),
              _buildStatChip(
                label: 'Presentes',
                value: presentes,
                color: Colors.greenAccent.shade100,
                background: Colors.black.withOpacity(0.08),
              ),
              _buildStatChip(
                label: 'Faltantes',
                value: faltantesInt.toString(),
                color: Colors.amberAccent.shade100,
                background: Colors.black.withOpacity(0.08),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Inscrito> inscritos) {
    return ListView.separated(
      itemCount: inscritos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inscrito = inscritos[index];
        return _buildInscritoCard(inscrito);
      },
    );
  }

  Widget _buildInscritoCard(Inscrito inscrito) {
    final iniciais = _buildIniciais(inscrito.nome);
    final presente = inscrito.presente;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryColor.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              iniciais,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inscrito.nome ?? 'Sem nome',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (inscrito.documento != null &&
                        inscrito.documento!.isNotEmpty)
                      Flexible(
                        child: Text(
                          inscrito.documento!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (inscrito.sigla != null &&
                        inscrito.sigla!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          inscrito.sigla!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (inscrito.dscLocal != null && inscrito.dscLocal!.isNotEmpty)
                  Text(
                    inscrito.dscLocal!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (inscrito.dscAuditorio != null &&
                    inscrito.dscAuditorio!.isNotEmpty)
                  Text(
                    inscrito.dscAuditorio!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: presente
                            ? Colors.green.withOpacity(0.12)
                            : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        presente ? 'Presente' : 'Não presente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: presente ? Colors.green[800] : Colors.red[700],
                        ),
                      ),
                    ),
                    if (inscrito.lidoAt != null &&
                        inscrito.lidoAt!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeBr(inscrito.lidoAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateTime(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    DateTime? dt = DateTime.tryParse(value);
    if (dt == null && value.contains(' ')) {
      dt = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    }
    return dt;
  }

  String _formatDateBr(String raw) {
    try {
      final parsed = _parseDateTime(raw);
      if (parsed == null) return raw;
      final dt = parsed.toLocal();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final date =
          '${twoDigits(dt.day)}/${twoDigits(dt.month)}/${dt.year.toString().padLeft(4, '0')}';
      return date;
    } catch (_) {
      return raw;
    }
  }

  String _formatTimeBr(String raw) {
    try {
      final parsed = _parseDateTime(raw);
      if (parsed == null) return raw;
      final dt = parsed.toLocal();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final time =
          '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}';
      return time;
    } catch (_) {
      return raw;
    }
  }

  String _buildIniciais(String? nome) {
    if (nome == null || nome.trim().isEmpty) return '?';
    final partes = nome.trim().split(' ');
    if (partes.length == 1) {
      return partes.first.characters.first.toUpperCase();
    }
    final primeira = partes.first.characters.first;
    final ultima = partes.last.characters.first;
    return (primeira + ultima).toUpperCase();
  }
}
