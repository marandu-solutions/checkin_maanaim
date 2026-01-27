import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/inscrito_model.dart';
import '../../themes/app_theme.dart';

class ParticipantePage extends StatelessWidget {
  final Inscrito inscrito;

  const ParticipantePage({super.key, required this.inscrito});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final bool isPresent = inscrito.presente;
    final statusColor = isPresent ? Colors.green : Colors.red;
    final statusBgColor = isPresent ? Colors.green.shade50 : Colors.red.shade50;
    final statusIcon = isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final statusText = isPresent ? 'PRESENTE' : 'AUSENTE';

    // Initials logic
    String iniciais = '';
    if (inscrito.nome != null && inscrito.nome!.isNotEmpty) {
      final names = inscrito.nome!.trim().split(' ');
      if (names.isNotEmpty) {
        iniciais = names[0][0];
        if (names.length > 1) {
          iniciais += names.last[0];
        }
      }
    }
    iniciais = iniciais.toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  
                  // Decorative Circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Avatar & Name Content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Hero(
                          tag: 'avatar_${inscrito.id}',
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              iniciais,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            inscrito.nome ?? 'Sem Nome',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (inscrito.dscEquipe != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              inscrito.dscEquipe!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Card
                      _buildStatusCard(statusText, statusColor, statusBgColor, statusIcon, inscrito.lidoAt),
                      
                      const SizedBox(height: 24),
                      
                      // Info Grid
                      const Text(
                        'Informações Pessoais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection([
                        if (inscrito.documento != null)
                          _buildInfoRow(Icons.badge_outlined, 'Documento', inscrito.documento!),
                        if (inscrito.isPastor == '1')
                          _buildInfoRow(Icons.church_outlined, 'Cargo', 'Pastor'),
                        if (inscrito.codTipoObreiro != null)
                          _buildInfoRow(Icons.work_outline, 'Tipo Obreiro', inscrito.codTipoObreiro!),
                      ]),

                      const SizedBox(height: 24),

                      const Text(
                        'Localização & Classe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection([
                         if (inscrito.dscLocal != null)
                          _buildInfoRow(Icons.location_on_outlined, 'Local', inscrito.dscLocal!),
                        if (inscrito.dscClasse != null)
                          _buildInfoRow(Icons.class_outlined, 'Classe', inscrito.dscClasse!),
                        if (inscrito.dscAuditorio != null)
                          _buildInfoRow(Icons.meeting_room_outlined, 'Auditório', inscrito.dscAuditorio!),
                        if (inscrito.numAssento != null && inscrito.numAssento!.isNotEmpty)
                          _buildInfoRow(Icons.event_seat_outlined, 'Assento', inscrito.numAssento!),
                      ]),

                      if (_hasAccommodationInfo(inscrito)) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Hospedagem',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoSection([
                          if (inscrito.dscAlojamento != null)
                            _buildInfoRow(Icons.hotel_outlined, 'Alojamento', inscrito.dscAlojamento!),
                          if (inscrito.leitoQuartoNumero != null)
                            _buildInfoRow(Icons.door_front_door_outlined, 'Quarto', inscrito.leitoQuartoNumero!),
                          if (inscrito.leitoNumero != null)
                            _buildInfoRow(Icons.bed_outlined, 'Leito', inscrito.leitoNumero!),
                        ]),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAccommodationInfo(Inscrito i) {
    return (i.dscAlojamento != null && i.dscAlojamento!.isNotEmpty) ||
           (i.leitoQuartoNumero != null && i.leitoQuartoNumero!.isNotEmpty) ||
           (i.leitoNumero != null && i.leitoNumero!.isNotEmpty);
  }

  Widget _buildStatusCard(String status, Color color, Color bgColor, IconData icon, String? lidoAt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status do Check-in',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                if (lidoAt != null && lidoAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Realizado em: ${_formatTime(lidoAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      // Assuming raw is standard format, parse and reformat
      var dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      return '${twoDigits(dt.day)}/${twoDigits(dt.month)}/${dt.year} às ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }
}
