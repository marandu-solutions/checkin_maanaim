import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/user_model.dart';
import '../../models/inscrito_model.dart';
import '../../services/evento_service.dart';
import '../../services/checkin_service.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

class LeituraPage extends StatefulWidget {
  final UserEvento evento;

  const LeituraPage({super.key, required this.evento});

  @override
  State<LeituraPage> createState() => _LeituraPageState();
}

class _LeituraPageState extends State<LeituraPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  List<Inscrito> _inscritos = [];
  Inscrito? _foundInscrito;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessingCheckin = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadInscritos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadInscritos() async {
    try {
      final service = context.read<EventoService>();
      final id = widget.evento.id?.toString() ?? '';
      // forceRefresh: false garante uso do cache se disponível
      final data = await service.getInscritos(id);

      if (mounted) {
        setState(() {
          _inscritos = data.inscritos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _search(String query) {
    if (query.length < 3) {
      if (_foundInscrito != null) {
        setState(() => _foundInscrito = null);
      }
      return;
    }

    // Busca exata por ID Token ou Documento (CPF)
    // Remove caracteres não numéricos para comparação segura
    final cleanQuery = query.trim().replaceAll(RegExp(r'\D'), '');

    // Se a query limpa for vazia (ex: digitou letras), usa a query original para comparar com idToken (caso tenha letras)
    final searchTerm = cleanQuery.isEmpty ? query.trim() : cleanQuery;

    final result = _inscritos.where((p) {
      final idToken = p.idToken?.trim() ?? '';
      final doc = p.documento?.trim().replaceAll(RegExp(r'\D'), '') ?? '';

      return idToken == searchTerm || (doc.isNotEmpty && doc == searchTerm);
    }).firstOrNull;

    setState(() {
      _foundInscrito = result;
    });
  }

  Future<void> _confirmarPresenca({
    Inscrito? inscritoAlvo,
    bool isAuto = false,
  }) async {
    final target = inscritoAlvo ?? _foundInscrito;
    if (target == null) return;

    // Se não for auto check-in, mostra loading na UI manual
    if (!isAuto) {
      setState(() => _isProcessingCheckin = true);
    }

    try {
      final eventoService = context.read<EventoService>();
      final checkinService = CheckinService(context.read<AuthService>());

      // O idEvento pode vir do widget ou do próprio inscrito (seminarioId)
      // Especialmente útil para equipes onde o evento principal pode não ter ID na listagem.
      final idEvento =
          widget.evento.id?.toString() ?? target.seminarioId?.toString() ?? '';
      if (idEvento.isEmpty) {
        throw Exception('ID do evento inválido ou não encontrado.');
      }

      // O ID do inscrito precisa ser o ID correto para a chamada na API
      // Às vezes o campo 'id' pode vir nulo ou ser o ID do visitante/equipe.
      // O ideal é usar o id principal, ou fazer fallback se necessário.
      final idInscrito =
          target.id?.toString() ?? target.visitanteId?.toString() ?? '';

      if (idInscrito.isEmpty) {
        throw Exception('ID do inscrito não encontrado.');
      }

      // 1. Atualizar localmente (Cache e Lista Atual)
      eventoService.updateInscritoPresenteLocal(idEvento, idInscrito);

      // Atualiza o objeto na lista em memória
      final novoInscrito = target.copyWith(participou: '1');
      setState(() {
        final index = _inscritos.indexWhere(
          (i) =>
              (i.id == target.id && i.id != null) ||
              (i.idToken == target.idToken),
        );
        if (index != -1) {
          _inscritos[index] = novoInscrito;
        }
        // Se estiver no manual e for o mesmo inscrito, atualiza a view
        if (!isAuto &&
            (_foundInscrito?.id == target.id ||
                _foundInscrito?.idToken == target.idToken)) {
          _foundInscrito = novoInscrito;
        }
      });

      // 2. Enviar para servidor
      try {
        await checkinService.confirmarPresenca(idEvento, [idInscrito]);

        if (!isAuto && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presença sincronizada com o servidor!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Erro ao sincronizar checkin: $e');
        if (!isAuto && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Salvo localmente. Sincronização falhou (verifique internet).',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Limpar busca após sucesso (Apenas Manual)
      if (!isAuto) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _searchController.clear();
            setState(() {
              _foundInscrito = null;
              _isProcessingCheckin = false;
            });
            _focusNode.requestFocus();
          }
        });
      }
    } catch (e) {
      if (!isAuto && mounted) {
        setState(() => _isProcessingCheckin = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro crítico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleScanner() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escanear QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _toggleScanner,
          ),
        ),
        body: MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                final code = barcode.rawValue!;
                debugPrint('QR Code detectado: $code');
                _toggleScanner(); // Fecha scanner
                _searchController.text = code;
                _search(code);
                break;
              }
            }
          },
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'Check-in',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Manual'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Auto'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: TabBarView(children: [_buildManualTab(), _buildAutoTab()]),
      ),
    );
  }

  Widget _buildAutoTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _processAutoCheckin(barcode.rawValue!);
                break; // Processa apenas o primeiro
              }
            }
          },
        ),
        // Overlay indicativo
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Aponte para o QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Controle de debounce para o auto-checkin
  bool _isAutoProcessing = false;

  Future<void> _processAutoCheckin(String rawValue) async {
    if (_isAutoProcessing) return;

    final cleanCode = rawValue.trim().replaceAll(RegExp(r'\D'), '');
    final searchTerm = cleanCode.isEmpty ? rawValue.trim() : cleanCode;

    // Busca o inscrito
    final inscrito = _inscritos.where((p) {
      final idToken = p.idToken?.trim() ?? '';
      final doc = p.documento?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
      return idToken == searchTerm || (doc.isNotEmpty && doc == searchTerm);
    }).firstOrNull;

    if (inscrito == null) {
      // Opcional: Feedback visual de "não encontrado" (mas sem travar)
      return;
    }

    // Se já participou, talvez mostrar um aviso? O requisito diz "confirmará o checkin",
    // mas se já estiver confirmado, podemos mostrar o popup de sucesso igual.
    // Vamos prosseguir para mostrar o popup mesmo se já estiver presente (feedback positivo).

    _isAutoProcessing = true;

    try {
      // 1. Realizar Checkin
      await _confirmarPresenca(inscritoAlvo: inscrito, isAuto: true);

      // 2. Mostrar Popup
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            // Fecha automaticamente após 4 segundos
            Future.delayed(const Duration(seconds: 4), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      inscrito.nome ?? 'Participante',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check-in Confirmado!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      }
    } finally {
      // Pequeno delay extra para evitar leituras múltiplas imediatas do mesmo código ao fechar
      await Future.delayed(const Duration(seconds: 2));
      _isAutoProcessing = false;
    }
  }

  Widget _buildManualTab() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInscritos,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header Section (Simplified for Tab View)
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total de inscritos carregados: ${_inscritos.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                                onChanged: _search,
                                decoration: const InputDecoration(
                                  hintText: 'Digite CPF ou Nº Crachá',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.grey[400],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: _toggleScanner,
                              tooltip: 'Escanear QR Code',
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Result Section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _foundInscrito != null
                        ? _buildInscritoCard(_foundInscrito!)
                        : _buildEmptyState(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aguardando leitura...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite o código ou use o scanner',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildInscritoCard(Inscrito inscrito) {
    final bool jaParticipou = inscrito.presente;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: jaParticipou ? Colors.green : AppTheme.primaryColor,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    inscrito.nome?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: jaParticipou
                          ? Colors.green
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                inscrito.nome ?? 'Nome Desconhecido',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Role/Team Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (inscrito.dscEquipe != null &&
                          inscrito.dscEquipe!.isNotEmpty)
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  inscrito.dscEquipe ?? 'Participante',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        (inscrito.dscEquipe != null &&
                            inscrito.dscEquipe!.isNotEmpty)
                        ? Colors.blue[700]
                        : Colors.grey[700],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Details Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem('Inscrição', inscrito.idToken ?? '-'),
                  _buildDetailItem('CPF', inscrito.documento ?? '-'),
                ],
              ),

              const SizedBox(height: 32),

              // Action Button
              if (jaParticipou)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'JÁ CREDENCIADO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessingCheckin ? null : _confirmarPresenca,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                    ),
                    child: _isProcessingCheckin
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CONFIRMAR PRESENÇA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
