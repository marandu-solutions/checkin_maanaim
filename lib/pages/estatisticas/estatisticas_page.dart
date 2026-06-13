import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inscrito_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/evento_service.dart';
import '../../themes/app_theme.dart';

class EstatisticasPage extends StatefulWidget {
  final UserEvento? evento;

  const EstatisticasPage({super.key, this.evento});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  late Future<EventoInscritos?> _futureData;
  bool _isLoading = false;

  // Dados processados para os gráficos
  int _totalInscritos = 0;
  int _totalPresentes = 0;
  int _totalFaltantes = 0;
  int _totalPastores = 0;
  Map<String, int> _porEquipe = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant EstatisticasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.evento?.id != oldWidget.evento?.id) {
      _loadData();
    }
  }

  void _loadData() {
    if (widget.evento == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auth = context.read<AuthService>();
    final service = EventoService(auth);
    final id = widget.evento!.id?.toString() ?? '';

    service
        .getInscritos(id)
        .then((data) {
          if (mounted) {
            _processRealData(data);
            setState(() {
              _isLoading = false;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
  }

  void _processRealData(EventoInscritos data) {
    final inscritos = data.inscritos;
    int presentes = 0;
    int pastores = 0;
    final equipeMap = <String, int>{};

    for (var i in inscritos) {
      if (i.presente) presentes++;
      if (i.isPastor == '1') pastores++;

      final equipe = i.dscEquipe?.trim() ?? 'Sem Equipe';
      final equipeKey = equipe.isEmpty ? 'Sem Equipe' : equipe;
      equipeMap[equipeKey] = (equipeMap[equipeKey] ?? 0) + 1;
    }

    // Ordenar equipes por quantidade
    final sortedEntries = equipeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEquipes = <String, int>{};

    // Pega TODAS as equipes, sem limitar a "top N" e sem agrupar em "Outros"
    for (int i = 0; i < sortedEntries.length; i++) {
      topEquipes[sortedEntries[i].key] = sortedEntries[i].value;
    }

    _totalInscritos = inscritos.length;
    _totalPresentes = presentes;
    _totalFaltantes = inscritos.length - presentes;
    _totalPastores = pastores;
    _porEquipe = topEquipes;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.evento == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 80,
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nenhum evento selecionado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Selecione um evento na aba Eventos\npara visualizar as estatísticas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildKpiGrid(isWide),
                      const SizedBox(height: 32),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPresenceChartCard()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTeamChartCard()),
                          ],
                        )
                      else ...[
                        _buildPresenceChartCard(),
                        const SizedBox(height: 24),
                        _buildTeamChartCard(),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final titulo = widget.evento?.descricaoClasse ?? 'Visão Geral';
    const subtitulo = 'Estatísticas em tempo real do evento';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(bool isWide) {
    final taxaPresenca = _totalInscritos > 0
        ? (_totalPresentes / _totalInscritos * 100).toStringAsFixed(1)
        : '0.0';

    final cards = [
      _buildKpiCard(
        'Total Inscritos',
        _totalInscritos.toString(),
        Icons.people_alt_rounded,
        Colors.blue,
        Colors.blue.shade50,
      ),
      _buildKpiCard(
        'Presentes',
        _totalPresentes.toString(),
        Icons.check_circle_rounded,
        Colors.green,
        Colors.green.shade50,
      ),
      _buildKpiCard(
        'Ausentes',
        _totalFaltantes.toString(),
        Icons.cancel_rounded,
        Colors.orange,
        Colors.orange.shade50,
      ),
      _buildKpiCard(
        'Taxa de Presença',
        '$taxaPresenca%',
        Icons.pie_chart_rounded,
        Colors.purple,
        Colors.purple.shade50,
      ),
    ];

    if (isWide) {
      return SizedBox(
        height: 170,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: c,
                  ),
                ),
              )
              .toList(),
        ),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        children: cards,
      );
    }
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (widget.evento != null)
                Icon(Icons.insights, color: Colors.grey.shade300, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceChartCard() {
    return _PresenceChart(
      totalPresentes: _totalPresentes,
      totalFaltantes: _totalFaltantes,
      totalInscritos: _totalInscritos,
    );
  }

  Widget _buildTeamChartCard() {
    return _TeamDistributionChart(
      porEquipe: _porEquipe,
      totalInscritos: _totalInscritos,
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PresenceChart extends StatefulWidget {
  final int totalPresentes;
  final int totalFaltantes;
  final int totalInscritos;

  const _PresenceChart({
    required this.totalPresentes,
    required this.totalFaltantes,
    required this.totalInscritos,
  });

  @override
  State<_PresenceChart> createState() => _PresenceChartState();
}

class _PresenceChartState extends State<_PresenceChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.totalInscritos > 0;
    final percentPresentes = hasData
        ? (widget.totalPresentes / widget.totalInscritos * 100).toStringAsFixed(
            1,
          )
        : '0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status de Presença',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentPresentes% Presentes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: _showingSections(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _touchedIndex == 0
                          ? 'Presentes'
                          : _touchedIndex == 1
                          ? 'Ausentes'
                          : 'Total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _touchedIndex == 0
                          ? '${widget.totalPresentes}'
                          : _touchedIndex == 1
                          ? '${widget.totalFaltantes}'
                          : '${widget.totalInscritos}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: Colors.greenAccent.shade400,
                text: 'Presentes',
                isSquare: false,
                isSelected: _touchedIndex == 0,
              ),
              const SizedBox(width: 24),
              _LegendItem(
                color: Colors.orangeAccent.shade100,
                text: 'Ausentes',
                isSquare: false,
                isSelected: _touchedIndex == 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(2, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 70.0 : 60.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black26, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.greenAccent.shade400,
            value: widget.totalPresentes.toDouble(),
            title:
                '${((widget.totalPresentes / (widget.totalInscritos == 0 ? 1 : widget.totalInscritos)) * 100).toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: _Badge(
              Icons.check_circle,
              size: widgetSize,
              borderColor: Colors.greenAccent.shade400,
            ),
            badgePositionPercentageOffset: 1.2,
            titlePositionPercentageOffset: 0.55,
          );
        case 1:
          return PieChartSectionData(
            color: Colors.orangeAccent.shade100,
            value: widget.totalFaltantes.toDouble(),
            title:
                '${((widget.totalFaltantes / (widget.totalInscritos == 0 ? 1 : widget.totalInscritos)) * 100).toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: _Badge(
              Icons.cancel,
              size: widgetSize,
              borderColor: Colors.orangeAccent.shade100,
            ),
            badgePositionPercentageOffset: 1.2,
            titlePositionPercentageOffset: 0.55,
          );
        default:
          throw Error();
      }
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, {required this.size, required this.borderColor});
  final IconData icon;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Icon(icon, color: borderColor, size: size * 0.6),
      ),
    );
  }
}

class _TeamDistributionChart extends StatefulWidget {
  final Map<String, int> porEquipe;
  final int totalInscritos;

  const _TeamDistributionChart({
    required this.porEquipe,
    required this.totalInscritos,
  });

  @override
  State<_TeamDistributionChart> createState() => _TeamDistributionChartState();
}

class _TeamDistributionChartState extends State<_TeamDistributionChart> {
  int _touchedIndex = -1;

  final List<Color> _colors = [
    const Color(0xFF03A9F4), // Primary
    const Color(0xFFAB47BC), // Purple
    const Color(0xFF26A69A), // Teal
    const Color(0xFFFF7043), // Deep Orange
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF8D6E63), // Brown
    const Color(0xFF78909C), // Blue Grey
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuição por Equipe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: _showingSections(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _touchedIndex != -1 &&
                                      _touchedIndex < widget.porEquipe.length
                                  ? widget.porEquipe.keys.elementAt(
                                      _touchedIndex,
                                    )
                                  : 'Total',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _touchedIndex != -1 ? 12 : 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _touchedIndex != -1 &&
                                      _touchedIndex < widget.porEquipe.length
                                  ? '${widget.porEquipe.values.elementAt(_touchedIndex)}'
                                  : '${widget.totalInscritos}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Opção "Todos"
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _touchedIndex = -1;
                              });
                            },
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _touchedIndex == -1 ? 1.0 : 0.3,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Todos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ...widget.porEquipe.keys.toList().asMap().entries.map((
                          e,
                        ) {
                          final index = e.key;
                          final text = e.value;
                          final color = _colors[index % _colors.length];
                          final isTouched = index == _touchedIndex;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (_touchedIndex == index) {
                                    _touchedIndex = -1;
                                  } else {
                                    _touchedIndex = index;
                                  }
                                });
                              },
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _touchedIndex == -1 || isTouched
                                    ? 1.0
                                    : 0.3,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isTouched
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isTouched
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(widget.porEquipe.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final widgetSize = isTouched ? 40.0 : 30.0;
      final value = widget.porEquipe.values.elementAt(i);
      final color = _colors[i % _colors.length];
      final equipeName = widget.porEquipe.keys.elementAt(i).toUpperCase();

      IconData iconData = Icons.person; // Padrão
      if (equipeName != 'SEM EQUIPE' && equipeName != 'OUTROS') {
        switch (equipeName) {
          case 'APOIO':
            iconData = Icons.event_seat;
            break;
          case 'COMUNICAÇÃO':
            iconData = Icons.campaign;
            break;
          case 'COZINHA':
            iconData = Icons.soup_kitchen;
            break;
          case 'GRUPO DE LOUVOR':
            iconData = Icons.music_note;
            break;
          case 'LIMPEZA':
            iconData = Icons.cleaning_services;
            break;
          case 'LIVRARIA':
            iconData = Icons.menu_book;
            break;
          case 'SAÚDE':
            iconData = Icons.local_hospital;
            break;
          case 'SEGURANÇA':
            iconData = Icons.local_police;
            break;
          case 'CANTINA':
            iconData = Icons.attach_money;
            break;
          case 'SECRETARIA':
            iconData = Icons.badge; // ou Icons.folder_shared
            break;
          default:
            iconData = Icons.group_work;
        }
      }

      return PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title: isTouched ? '$value' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
        badgeWidget: _Badge(iconData, size: widgetSize, borderColor: color),
        badgePositionPercentageOffset: 1.2,
        titlePositionPercentageOffset: 0.55,
      );
    });
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 12,
    this.textColor,
    this.isSelected = false,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isSelected ? 1.0 : 0.7,
      child: Row(
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
