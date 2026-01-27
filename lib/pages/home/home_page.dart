import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../themes/app_theme.dart';
import '../inscricoes/inscricoes_page.dart';
import '../listaseminarios/lista_seminarios_page.dart';
import 'components/home_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final User user;
  final UserEvento? selectedEvento;

  const HomePage({
    super.key,
    required this.user,
    this.selectedEvento,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  UserEvento? _selectedEvento;

  @override
  void initState() {
    super.initState();
    _selectedEvento = widget.selectedEvento;
  }

  String get _currentLabel {
    switch (_currentIndex) {
      case 0:
        return 'Eventos';
      case 1:
        return 'Leitura';
      case 2:
        return 'Inscrições';
      case 3:
        return 'Estatísticas';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final content = _buildContent();

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Check-in',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ),
          body: isWide ? Row(children: [Expanded(child: content)]) : content,
          bottomNavigationBar: HomeBottomNavBar(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  void _onEventoSelected(UserEvento evento) {
    setState(() {
      _selectedEvento = evento;
      _currentIndex = 2;
    });
  }

  Widget _buildContent() {
    if (_currentIndex == 0) {
      return ListaSeminariosPage(
        user: widget.user,
        onEventoSelected: _onEventoSelected,
      );
    }

    if (_currentIndex == 2) {
      if (_selectedEvento == null) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Selecione um evento na aba Eventos para ver as inscrições.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }

      return InscricoesPage(evento: _selectedEvento!);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentLabel,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Você está na seção de $_currentLabel.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
