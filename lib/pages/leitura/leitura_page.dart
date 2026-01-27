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

  Future<void> _confirmarPresenca() async {
    if (_foundInscrito == null) return;

    setState(() => _isProcessingCheckin = true);

    try {
      final eventoService = context.read<EventoService>();
      // Instancia CheckinService on-demand pois não é um Provider global ainda, mas poderia ser.
      // Usa AuthService do provider.
      final checkinService = CheckinService(context.read<AuthService>());

      final idEvento = widget.evento.id.toString();
      final idInscrito = _foundInscrito!.id.toString();

      // 1. Atualizar localmente (Cache e Lista Atual)
      eventoService.updateInscritoPresenteLocal(idEvento, idInscrito);

      setState(() {
        // Atualiza objeto exibido na tela
        _foundInscrito = _foundInscrito!.copyWith(participou: '1');
        
        // Atualiza na lista em memória desta tela
        final index = _inscritos.indexWhere((i) => i.id == idInscrito);
        if (index != -1) {
          _inscritos[index] = _foundInscrito!;
        }
      });

      // 2. Enviar para servidor (Fire-and-forget ou aguardar confirmação?)
      // O usuário pediu: "altere para que cada vez que eu marcar uma pessoa como presente ele altere tanto offline quanto no banco de dados"
      // Se estiver offline, o CheckinService vai falhar. O requisito diz "Offline First".
      // Idealmente, deveríamos enfileirar se falhar. 
      // Por enquanto, vamos tentar enviar e mostrar erro se falhar, mas manter o sucesso local (lógica otimista).
      
      try {
        await checkinService.confirmarPresenca(idEvento, [idInscrito]);
        if (mounted) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salvo localmente. Sincronização falhou (verifique internet).'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Limpar busca após sucesso
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

    } catch (e) {
      // Erro geral (improvável se a parte local funcionar)
      if (mounted) {
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppTheme.errorColor),
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
                      // Header Section
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
                            const Text(
                              'Leitura de Credencial',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total de inscritos carregados: ${_inscritos.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
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
                                            horizontal: 20, vertical: 16),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.grey[400],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner,
                                        color: AppTheme.primaryColor),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[300],
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
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
                      color: jaParticipou ? Colors.green : AppTheme.primaryColor,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (inscrito.dscEquipe != null && inscrito.dscEquipe!.isNotEmpty)
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  inscrito.dscEquipe ?? 'Participante',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: (inscrito.dscEquipe != null && inscrito.dscEquipe!.isNotEmpty)
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
