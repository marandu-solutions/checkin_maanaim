import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../themes/app_theme.dart';
import '../home/home_page.dart';

class ListaSeminariosPage extends StatelessWidget {
  final User user;

  const ListaSeminariosPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final eventos = <UserEvento>[];

    if (user.locais != null) {
      for (final local in user.locais!) {
        if (local.eventos != null) {
          eventos.addAll(local.eventos!);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Selecione o seminário',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      body: eventos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum seminário disponível.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventos.length,
              itemBuilder: (context, index) {
                final evento = eventos[index];
                final titulo = evento.descricaoClasse ?? 'Sem descrição';
                final local = evento.local ?? '';
                final inicio = evento.inicio ?? '';
                final inscritos = evento.qtdInscritos ?? '0';
                final presentes = evento.qtdParticipou ?? '0';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomePage(selectedEvento: evento),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (local.isNotEmpty)
                              Text(
                                local,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            if (inicio.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                inicio,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                text: '(',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: inscritos,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const TextSpan(text: '/'),
                                  TextSpan(
                                    text: presentes,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const TextSpan(text: ')'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
