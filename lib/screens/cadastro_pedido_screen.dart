import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pedido_model.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';

class CadastroPedidoScreen extends StatefulWidget {
  const CadastroPedidoScreen({super.key});

  @override
  State<CadastroPedidoScreen> createState() => _CadastroPedidoScreenState();
}
class _CadastroPedidoScreenState extends State<CadastroPedidoScreen> {
  // Controllers
  final _temaController = TextEditingController();
  final _textoController = TextEditingController();
  final _larguraController = TextEditingController();
  final _alturaController = TextEditingController();
  final _valorController = TextEditingController();
  final _entradaController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Estado
  ClienteModel? _clienteSelecionado;
  String _tecidoSelecionado = 'Etamine';
  DateTime? _dataEntrega;
  List<LinhaResumida> _linhasSelecionadas = [];

  // Novas variáveis de estado para dados reais
  List<ClienteModel> _clientes = [];
  dynamic _estoqueLinhas = []; // Troque dynamic pelo seu modelo correto, ex: List<LinhaModel>
  bool _carregando = true;

  // Constantes de cálculo
  static const double _pontosPorCm = 5.0;
  static const double _margemTecido = 10.0;
  static const double _pontosPorHora = 100.0;
  static const double _valorHora = 5.0;
  static const double _materialFixo = 10.0;

  final List<String> _tecidos = ['Etamine', 'Crivo', 'Aida 14', 'Aida 18'];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  // Busca os dados do Firebase de forma paralela
  Future<void> _carregarDadosIniciais() async {
    try {
      // Chame as funções corretas do seu FirestoreService aqui
      final resultados = await Future.wait([
        FirestoreService.buscarClientes(), // Crie este método se não existir
        FirestoreService.buscarEstoque(),  // Crie este método se não existir
      ]);

      if (mounted) {
        setState(() {
          _clientes = resultados[0] as List<ClienteModel>;
          _estoqueLinhas = resultados[1];
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  // Cálculos automáticos
  double get _larguraCm {
    final v = double.tryParse(_larguraController.text) ?? 0;
    return v / _pontosPorCm;
  }

  double get _alturaCm {
    final v = double.tryParse(_alturaController.text) ?? 0;
    return v / _pontosPorCm;
  }

  double get _totalPontos {
    final l = double.tryParse(_larguraController.text) ?? 0;
    final a = double.tryParse(_alturaController.text) ?? 0;
    return l * a;
  }

  double get _horasEstimadas => _totalPontos / _pontosPorHora;
  double get _precoSugerido => (_horasEstimadas * _valorHora) + _materialFixo;
  bool get _temCalculo => _larguraController.text.isNotEmpty && _alturaController.text.isNotEmpty;

  @override
  void dispose() {
    _temaController.dispose();
    _textoController.dispose();
    _larguraController.dispose();
    _alturaController.dispose();
    _valorController.dispose();
    _entradaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9EFE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9EFE1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3C6246)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Novo Pedido',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF3C6246))),
      ),
      // Se estiver carregando, mostra uma barra de progresso centralizada
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3C6246)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bloco1Cliente(),
                  const SizedBox(height: 16),
                  _bloco2Bordado(),
                  const SizedBox(height: 16),
                  _bloco3Calculadora(),
                  const SizedBox(height: 16),
                  _bloco4Financeiro(),
                  const SizedBox(height: 24),
                  _botaoSalvar(),
                ],
              ),
            ),
    );
  }

  // ─── BLOCO 1: CLIENTE ───────────────────────────────────────────
  Widget _bloco1Cliente() {
    return _blocoContainer(
      titulo: 'Cliente e Entrega',
      child: Column(
        children: [
          // Seletor de cliente atualizado para usar a lista local _clientes
          DropdownButtonFormField<ClienteModel>(
            value: _clienteSelecionado,
            hint: Text('Selecionar cliente',
                style: GoogleFonts.montserrat(fontSize: 13)),
            decoration: _inputDecoration(''),
            items: _clientes.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c.nome,
                    style: GoogleFonts.montserrat(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _clienteSelecionado = v),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3C6246)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _modalNovoCliente,
            icon: const Icon(Icons.person_add_outlined,
                color: Color(0xFF3C6246), size: 18),
            label: Text('+ Novo Cliente',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: const Color(0xFF3C6246))),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF3C6246), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _dataEntrega == null
                        ? 'Data de Entrega'
                        : DateFormat('dd/MM/yyyy').format(_dataEntrega!),
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: _dataEntrega == null
                            ? Colors.grey
                            : const Color(0xFF1C2321)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BLOCO 2: BORDADO ───────────────────────────────────────────
  Widget _bloco2Bordado() {
    return _blocoContainer(
      titulo: 'Detalhes do Bordado',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF39AA5).withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo_outlined,
                    color: Color(0xFFF39AA5), size: 28),
                const SizedBox(height: 6),
                Text('Adicionar Imagem de Referência',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: const Color(0xFFF39AA5))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _campo(_temaController, 'Tema / Descrição do Trabalho',
              Icons.auto_stories_outlined),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _tecidoSelecionado,
            decoration: _inputDecoration('Tecido'),
            items: _tecidos.map((t) {
              return DropdownMenuItem(
                  value: t,
                  child: Text(t, style: GoogleFonts.montserrat(fontSize: 13)));
            }).toList(),
            onChanged: (v) => setState(() => _tecidoSelecionado = v!),
          ),
        ],
      ),
    );
  }

  // ─── BLOCO 3: CALCULADORA ───────────────────────────────────────
  Widget _bloco3Calculadora() {
    return _blocoContainer(
      titulo: 'Calculadora Inteligente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Digite o tamanho do gráfico em pontos:',
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _campo(_larguraController, 'Largura (pontos)',
                    Icons.width_normal_outlined,
                    teclado: TextInputType.number, aoMudar: () => setState(() {})),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFF3C6246))),
              ),
              Expanded(
                child: _campo(_alturaController, 'Altura (pontos)',
                    Icons.height_outlined,
                    teclado: TextInputType.number, aoMudar: () => setState(() {})),
              ),
            ],
          ),
          if (_temCalculo) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3C6246).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3C6246).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resultado do Cálculo',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF3C6246))),
                  const SizedBox(height: 8),
                  _linhaCalculo('Tamanho do bordado:',
                      '${_larguraCm.toStringAsFixed(1)} cm × ${_alturaCm.toStringAsFixed(1)} cm'),
                  _linhaCalculo('Corte sugerido do tecido:',
                      '${(_larguraCm + _margemTecido).toStringAsFixed(1)} cm × ${(_alturaCm + _margemTecido).toStringAsFixed(1)} cm'),
                  _linhaCalculo('Total de pontos:', '${_totalPontos.toStringAsFixed(0)} pts'),
                  _linhaCalculo('Tempo estimado:', '${_horasEstimadas.toStringAsFixed(1)} horas'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Preço sugerido:',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF3C6246))),
                      Text('R\$ ${_precoSugerido.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF3C6246))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BLOCO 4: FINANCEIRO ────────────────────────────────────────
  Widget _bloco4Financeiro() {
    return _blocoContainer(
      titulo: 'Materiais e Pagamento',
      child: Column(
        children: [
          GestureDetector(
            onTap: _modalAdicionarLinhas,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _linhasSelecionadas.isEmpty
                          ? 'Adicionar Linhas do Projeto'
                          : '${_linhasSelecionadas.length} linha(s) selecionada(s)',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: _linhasSelecionadas.isEmpty
                              ? Colors.grey
                              : const Color(0xFF1C2321)),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_linhasSelecionadas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _linhasSelecionadas.map((l) {
                return Chip(
                  label: Text('${l.marca} ${l.codigo}',
                      style: GoogleFonts.montserrat(fontSize: 11)),
                  backgroundColor: const Color(0xFFF39AA5).withOpacity(0.15),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _linhasSelecionadas.remove(l)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          _campo(_valorController, 'Valor Cobrado (R\$)', Icons.attach_money,
              teclado: TextInputType.number),
          const SizedBox(height: 10),
          _campo(_entradaController, 'Valor da Entrada / Sinal (R\$)', Icons.payments_outlined,
              teclado: TextInputType.number),
          const SizedBox(height: 10),
          TextField(
            controller: _observacoesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Observações gerais...',
              hintStyle: GoogleFonts.montserrat(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTÃO SALVAR ───────────────────────────────────────────────
  Widget _botaoSalvar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF39AA5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _salvarPedido,
        child: Text('Criar Pedido',
            style: GoogleFonts.montserrat(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────
  Widget _blocoContainer({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF3C6246))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String hint,
    IconData icone, {
    TextInputType teclado = TextInputType.text,
    VoidCallback? aoMudar,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      onChanged: aoMudar != null ? (_) => aoMudar() : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13),
        prefixIcon: Icon(icone, color: const Color(0xFF3C6246), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _linhaCalculo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade700)),
          Text(valor,
              style: GoogleFonts.montserrat(
                  fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1C2321))),
        ],
      ),
    );
  }

  // ─── AÇÕES ──────────────────────────────────────────────────────
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3C6246),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) setState(() => _dataEntrega = data);
  }

  // Modificado para salvar o novo cliente direto no Firebase
  void _modalNovoCliente() {
    final nomeCtrl = TextEditingController();
    final wppCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9EFE1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novo Cliente',
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
            const SizedBox(height: 16),
            TextField(controller: nomeCtrl, decoration: _inputDecoration('Nome completo')),
            const SizedBox(height: 10),
            TextField(
                controller: wppCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('WhatsApp (ex: 62999991111)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39AA5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nomeCtrl.text.isNotEmpty) {
                    final novoCliente = ClienteModel(
                      id: const Uuid().v4(), // Usando Uuid real para o banco de dados
                      nome: nomeCtrl.text,
                      whatsapp: wppCtrl.text,
                    );
                    
                    // Salva no banco de dados primeiro
                    await FirestoreService.salvarCliente(novoCliente); // Crie este método se necessário

                    setState(() {
                      _clientes.add(novoCliente);
                      _clienteSelecionado = novoCliente;
                    });
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text('Salvar Cliente',
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modificado para usar o estoque vindo do Firebase (_estoqueLinhas)
  void _modalAdicionarLinhas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9EFE1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text('Selecionar Linhas',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _estoqueLinhas.length, // Usando a variável de estado
                  itemBuilder: (_, i) {
                    final l = _estoqueLinhas[i];
                    final selecionada = _linhasSelecionadas
                        .any((s) => s.codigo == l.codigo && s.marca == l.marca);
                    return CheckboxListTile(
                      value: selecionada,
                      activeColor: const Color(0xFF3C6246),
                      title: Text('${l.marca} — ${l.codigo ?? l.nomeCor}', // Ajuste conforme os atributos do seu modelo real
                          style: GoogleFonts.montserrat(fontSize: 13)),
                      onChanged: (v) {
                        setModalState(() {
                          setState(() {
                            if (v == true) {
                              _linhasSelecionadas.add(LinhaResumida(
                                marca: l.marca,
                                codigo: l.codigo ?? '',
                                nomeCor: l.nomeCor,
                              ));
                            } else {
                              _linhasSelecionadas.removeWhere((s) =>
                                  s.codigo == l.codigo && s.marca == l.marca);
                            }
                          });
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39AA5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Confirmar Seleção',
                        style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvarPedido() async {
    if (_clienteSelecionado == null || _dataEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha o cliente e a data de entrega!', style: GoogleFonts.montserrat()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final valorCobrado = double.tryParse(_valorController.text) ?? _precoSugerido;
    final valorPago = double.tryParse(_entradaController.text) ?? 0;

    String statusPagamento;
    if (valorPago <= 0) {
      statusPagamento = 'PENDENTE';
    } else if (valorPago >= valorCobrado) {
      statusPagamento = 'QUITADO';
    } else {
      statusPagamento = 'PAGO_PARCIAL';
    }

    final novoPedido = PedidoModel(
      id: const Uuid().v4(),
      cliente: _clienteSelecionado!,
      dataPedido: DateTime.now(),
      dataEntrega: _dataEntrega!,
      tema: _temaController.text.isEmpty ? 'Sem tema' : _temaController.text,
      textoBordar: _textoController.text,
      tecido: _tecidoSelecionado,
      larguraPontos: int.tryParse(_larguraController.text) ?? 0,
      alturaPontos: int.tryParse(_alturaController.text) ?? 0,
      linhas: _linhasSelecionadas,
      valorCobrado: valorCobrado,
      valorPago: valorPago,
      statusProducao: 'NA_FILA',
      statusPagamento: statusPagamento,
      observacoes: _observacoesController.text,
    );

    await FirestoreService.salvarPedido(novoPedido);
    if (context.mounted) Navigator.pop(context);
  }
}