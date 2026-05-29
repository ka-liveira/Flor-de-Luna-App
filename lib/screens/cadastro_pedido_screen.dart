import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pedido_model.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';

class CadastroPedidoScreen extends StatefulWidget {
  final PedidoModel? pedido; // Recebe o pedido opcional para edição

  const CadastroPedidoScreen({super.key, this.pedido});

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
  DateTime? _dataEntrega;
  List<LinhaResumida> _linhasSelecionadas = [];

  List<ClienteModel> _clientes = [];
  dynamic _estoqueLinhas = []; 
  bool _carregando = true;

  // Constantes de cálculo
  static const double _pontosPorCm = 5.0;
  static const double _margemTecido = 10.0;
  static const double _pontosPorHora = 100.0;
  static const double _valorHora = 5.0;
  static const double _materialFixo = 10.0;

 @override
  void initState() {
    super.initState();
    
    // de forma síncrona aqui no início para o Flutter não limpar os dados na tela.
    if (widget.pedido != null) {
      final p = widget.pedido!;
      _clienteSelecionado = p.cliente;
      _dataEntrega = p.dataEntrega;
      _linhasSelecionadas = List.from(p.linhas);
      
      _temaController.text = p.tema;
      _textoController.text = p.textoBordar;
      _larguraController.text = p.larguraPontos > 0 ? p.larguraPontos.toString() : '';
      _alturaController.text = p.alturaPontos > 0 ? p.alturaPontos.toString() : '';
      _valorController.text = p.valorCobrado > 0 ? p.valorCobrado.toStringAsFixed(2) : '';
      _entradaController.text = p.valorPago > 0 ? p.valorPago.toStringAsFixed(2) : '';
      _observacoesController.text = p.observacoes;
    }

    // Depois de preparar os textos, chama o carregamento do estoque em segundo plano
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final resultadoEstoque = await FirestoreService.buscarEstoque();

      if (mounted) {
        setState(() {
          _estoqueLinhas = resultadoEstoque;
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

  double get _larguraCm => (double.tryParse(_larguraController.text) ?? 0) / _pontosPorCm;
  double get _alturaCm => (double.tryParse(_alturaController.text) ?? 0) / _pontosPorCm;
  double get _totalPontos => (double.tryParse(_larguraController.text) ?? 0) * (double.tryParse(_alturaController.text) ?? 0);
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
    final bool isEdicao = widget.pedido != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9EFE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9EFE1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3C6246)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdicao ? 'Editar Pedido' : 'Novo Pedido',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF3C6246))),
      ),
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

  Widget _bloco1Cliente() {
    return _blocoContainer(
      titulo: 'Cliente e Entrega',
      child: Column(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3C6246)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _modalMeioTelaNovoCliente,
            icon: const Icon(Icons.person_add_outlined, color: Color(0xFF3C6246), size: 18),
            label: Text(_clienteSelecionado == null ? 'Cadastrar Cliente' : 'Cliente: ${_clienteSelecionado!.nome}',
                style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF3C6246), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
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
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF3C6246), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _dataEntrega == null
                        ? 'Data de Entrega'
                        : DateFormat('dd/MM/yyyy').format(_dataEntrega!),
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: _dataEntrega == null ? Colors.grey : const Color(0xFF1C2321)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              border: Border.all(color: const Color(0xFFF39AA5).withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo_outlined, color: Color(0xFFF39AA5), size: 28),
                const SizedBox(height: 6),
                Text('Adicionar Imagem de Referência',
                    style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFFF39AA5))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _campo(_temaController, 'Descrição', Icons.auto_stories_outlined),
          const SizedBox(height: 10),
          _campo(_textoController, 'Observação', Icons.text_fields_outlined),
        ],
      ),
    );
  }

  Widget _bloco3Calculadora() {
    return _blocoContainer(
      titulo: 'Calculadora Inteligente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Digite o tamanho do gráfico em pontos:', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _campo(_larguraController, 'Largura (pontos)', Icons.width_normal_outlined,
                    teclado: TextInputType.number, aoMudar: () => setState(() {})),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFF3C6246))),
              ),
              Expanded(
                child: _campo(_alturaController, 'Altura (pontos)', Icons.height_outlined,
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
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF3C6246))),
                  const SizedBox(height: 8),
                  _linhaCalculo('Tamanho do bordado:', '${_larguraCm.toStringAsFixed(1)} cm × ${_alturaCm.toStringAsFixed(1)} cm'),
                  _linhaCalculo('Corte sugerido do tecido:', '${(_larguraCm + _margemTecido).toStringAsFixed(1)} cm × ${(_alturaCm + _margemTecido).toStringAsFixed(1)} cm'),
                  _linhaCalculo('Total de pontos:', '${_totalPontos.toStringAsFixed(0)} pts'),
                  _linhaCalculo('Tempo estimado:', '${_horasEstimadas.toStringAsFixed(1)} horas'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Preço sugerido:', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3C6246))),
                      Text('R\$ ${_precoSugerido.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF3C6246))),
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

  Widget _bloco4Financeiro() {
    return _blocoContainer(
      titulo: 'Materiais e Pagamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Icon(Icons.colorize_outlined, color: Color(0xFF3C6246), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _linhasSelecionadas.isEmpty ? 'Adicionar Linhas' : '${_linhasSelecionadas.length} linha(s) selecionada(s)',
                      style: GoogleFonts.montserrat(fontSize: 13, color: _linhasSelecionadas.isEmpty ? Colors.grey : const Color(0xFF1C2321)),
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
                  label: Text('${l.marca} ${l.codigo}', style: GoogleFonts.montserrat(fontSize: 11)),
                  backgroundColor: const Color(0xFFF39AA5).withOpacity(0.15),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _linhasSelecionadas.remove(l)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          _campo(_valorController, 'Valor Cobrado (R\$)', Icons.attach_money, teclado: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          _campo(_entradaController, 'Valor da Entrada (R\$)', Icons.payments_outlined, teclado: const TextInputType.numberWithOptions(decimal: true)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoSalvar() {
    final bool isEdicao = widget.pedido != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEdicao ? const Color(0xFF3C6246) : const Color(0xFFF39AA5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _salvarPedido,
        child: Text(isEdicao ? 'Salvar Alterações' : 'Criar Pedido', 
            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _blocoContainer({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF3C6246))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String hint, IconData icone, {TextInputType teclado = TextInputType.text, VoidCallback? aoMudar}) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      onChanged: aoMudar != null ? (_) => aoMudar() : null,
      style: GoogleFonts.montserrat(fontSize: 13),
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
          Text(valor, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1C2321))),
        ],
      ),
    );
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataEntrega ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3C6246), onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (data != null) setState(() => _dataEntrega = data);
  }

  void _modalMeioTelaNovoCliente() {
    final nomeCtrl = TextEditingController(text: _clienteSelecionado?.nome);
    final obsCtrl = TextEditingController(text: _clienteSelecionado?.whatsapp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Dados do Cliente',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl, 
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: _inputDecoration('Nome completo')
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsCtrl,
              maxLines: 2,
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: _inputDecoration('Observação')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39AA5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nomeCtrl.text.isNotEmpty) {
                final clie = ClienteModel(
                  id: _clienteSelecionado?.id ?? const Uuid().v4(),
                  nome: nomeCtrl.text,
                  whatsapp: obsCtrl.text,
                );
                
                await FirestoreService.salvarCliente(clie);

                setState(() {
                  _clienteSelecionado = clie;
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text('Confirmar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _modalAdicionarLinhas() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFF9EFE1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Selecionar Linhas',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3C6246),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _estoqueLinhas.length,
              itemBuilder: (_, i) {
                final l = _estoqueLinhas[i];
                final selecionada = _linhasSelecionadas.any((s) => s.codigo == l.codigo && s.marca == l.marca);
                return CheckboxListTile(
                  value: selecionada,
                  activeColor: const Color(0xFF3C6246),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${l.marca} — ${l.codigo ?? l.nomeCor}',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                  onChanged: (v) {
                    setModalState(() {
                      setState(() {
                        if (v == true) {
                          _linhasSelecionadas.add(LinhaResumida(marca: l.marca, codigo: l.codigo ?? '', nomeCor: l.nomeCor));
                        } else {
                          _linhasSelecionadas.removeWhere((s) => s.codigo == l.codigo && s.marca == l.marca);
                        }
                      });
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.montserrat(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39AA5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Confirmar',
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarPedido() async {
    if (_clienteSelecionado == null || _dataEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha o cliente e a data de entrega!', style: GoogleFonts.montserrat()), backgroundColor: Colors.red),
      );
      return;
    }

    final valorCobradoTexto = _valorController.text.replaceAll(',', '.');
    final valorPagoTexto = _entradaController.text.replaceAll(',', '.');

    final valorCobrado = double.tryParse(valorCobradoTexto) ?? _precoSugerido;
    final valorPago = double.tryParse(valorPagoTexto) ?? 0;

    String statusPagamento = valorPago <= 0 ? 'PENDENTE' : (valorPago >= valorCobrado ? 'QUITADO' : 'PAGO_PARCIAL');

    final novoPedido = PedidoModel(
      id: widget.pedido?.id ?? const Uuid().v4(), // Mantém o ID original se for edição
      cliente: _clienteSelecionado!,
      dataPedido: widget.pedido?.dataPedido ?? DateTime.now(), // Mantém a data de criação original
      dataEntrega: _dataEntrega!,
      tema: _temaController.text.isEmpty ? 'Sem tema' : _temaController.text,
      textoBordar: _textoController.text,
      tecido: widget.pedido?.tecido ?? '',
      larguraPontos: int.tryParse(_larguraController.text) ?? 0,
      alturaPontos: int.tryParse(_alturaController.text) ?? 0,
      linhas: _linhasSelecionadas,
      valorCobrado: valorCobrado,
      valorPago: valorPago,
      statusProducao: widget.pedido?.statusProducao ?? 'NA_FILA', // Preserva o status na edição
      statusPagamento: statusPagamento,
      observacoes: _observacoesController.text,
      urlImagem: widget.pedido?.urlImagem,
    );

    await FirestoreService.salvarPedido(novoPedido);
    
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.pedido != null ? '✅ Pedido atualizado!' : '🎉 Pedido criado!'),
          backgroundColor: const Color(0xFF3C6246),
        ),
      );
    }
  }
}