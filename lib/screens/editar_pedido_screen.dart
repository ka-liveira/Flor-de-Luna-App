import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pedido_model.dart';
import '../services/firestore_service.dart';

class EditarPedidoScreen extends StatefulWidget {
  final PedidoModel pedido;

  const EditarPedidoScreen({super.key, required this.pedido});

  @override
  State<EditarPedidoScreen> createState() => _EditarPedidoScreenState();
}

class _EditarPedidoScreenState extends State<EditarPedidoScreen> {
  late TextEditingController _temaController;
  late TextEditingController _textoController;
  late TextEditingController _larguraController;
  late TextEditingController _alturaController;
  late TextEditingController _valorController;
  late TextEditingController _entradaController;
  late TextEditingController _observacoesController;
  late TextEditingController _tecidoObservacaoController;

  ClienteModel? _clienteSelecionado;
  late DateTime? _dataEntrega;
  late String _statusProducao;
  late List<LinhaResumida> _linhasSelecionadas;

  List<ClienteModel> _clientes = [];
  List<dynamic> _estoqueLinhas = []; 
  bool _carregando = true;

  static const double _pontosPorCm = 5.0;
  static const double _margemTecido = 10.0;
  static const double _pontosPorHora = 100.0;
  static const double _valorHora = 5.0;
  static const double _materialFixo = 10.0;

  @override
  void initState() {
    super.initState();
    final p = widget.pedido;
    _temaController = TextEditingController(text: p.tema);
    _textoController = TextEditingController(text: p.textoBordar);
    _larguraController = TextEditingController(text: p.larguraPontos.toString());
    _alturaController = TextEditingController(text: p.alturaPontos.toString());
    _valorController = TextEditingController(text: p.valorCobrado.toStringAsFixed(2));
    _entradaController = TextEditingController(text: p.valorPago.toStringAsFixed(2));
    _observacoesController = TextEditingController(text: p.observacoes);
    _tecidoObservacaoController = TextEditingController(text: p.tecido); // Carrega o texto salvo anteriormente
    _clienteSelecionado = p.cliente;
    _dataEntrega = p.dataEntrega;
    _statusProducao = p.statusProducao;
    _linhasSelecionadas = List.from(p.linhas);

    _carregarDadosDoBanco();
  }

  Future<void> _carregarDadosDoBanco() async {
    try {
      final resultados = await Future.wait([
        FirestoreService.buscarClientes(),
        FirestoreService.buscarEstoque(),
      ]);

      if (mounted) {
        setState(() {
          _clientes = resultados[0] as List<ClienteModel>;
          _estoqueLinhas = resultados[1] as List<dynamic>;
          
          if (_clienteSelecionado != null && _clientes.isNotEmpty) {
            _clienteSelecionado = _clientes.firstWhere(
              (c) => c.id == widget.pedido.cliente.id,
              orElse: () => widget.pedido.cliente,
            );
          }
          
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados do banco: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _temaController.dispose();
    _textoController.dispose();
    _larguraController.dispose();
    _alturaController.dispose();
    _valorController.dispose();
    _entradaController.dispose();
    _observacoesController.dispose();
    _tecidoObservacaoController.dispose();
    super.dispose();
  }

  double get _larguraCm => (double.tryParse(_larguraController.text) ?? 0) / _pontosPorCm;
  double get _alturaCm => (double.tryParse(_alturaController.text) ?? 0) / _pontosPorCm;
  double get _totalPontos => (double.tryParse(_larguraController.text) ?? 0) * (double.tryParse(_alturaController.text) ?? 0);
  double get _horasEstimadas => _totalPontos / _pontosPorHora;
  double get _precoSugerido => (_horasEstimadas * _valorHora) + _materialFixo;
  bool get _temCalculo => _larguraController.text.isNotEmpty && _alturaController.text.isNotEmpty;

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
        title: Text('Editar Pedido',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF3C6246))),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3C6246)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _blocoStatus(),
                  const SizedBox(height: 16),
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

  Widget _blocoStatus() {
    final statusOpcoes = [
      ('NA_FILA', 'Na Fila'),
      ('EM_PRODUCAO', 'Em Produção'),
      ('CONCLUIDO', 'Concluído'),
      ('ENTREGUE', 'Entregue'),
    ];
    return _blocoContainer(
      titulo: 'Status do Pedido',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: statusOpcoes.map((s) {
          final ativo = _statusProducao == s.$1;
          return GestureDetector(
            onTap: () => setState(() => _statusProducao = s.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ativo ? const Color(0xFF3C6246) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ativo ? const Color(0xFF3C6246) : Colors.grey.shade300),
              ),
              child: Text(s.$2,
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: ativo ? Colors.white : const Color(0xFF1C2321))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bloco1Cliente() {
    return _blocoContainer(
      titulo: 'Cliente e Entrega',
      child: Column(
        children: [
          DropdownButtonFormField<ClienteModel>(
            value: _clienteSelecionado,
            decoration: _inputDecoration('Selecionar cliente'),
            hint: Text('Selecionar cliente', style: GoogleFonts.montserrat(fontSize: 13)),
            items: _clientes.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c.nome, style: GoogleFonts.montserrat(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _clienteSelecionado = v),
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
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF3C6246), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _dataEntrega == null ? 'Data de Entrega' : DateFormat('dd/MM/yyyy').format(_dataEntrega!),
                    style: GoogleFonts.montserrat(fontSize: 13, color: _dataEntrega == null ? Colors.grey : const Color(0xFF1C2321)),
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
          _campo(_temaController, 'Tema / Descrição', Icons.auto_stories_outlined),
          const SizedBox(height: 10),
          _campo(_textoController, 'Texto a ser bordado', Icons.text_fields_outlined),
          const SizedBox(height: 10),
          // MODIFICAÇÃO: Select de tecidos substituído por campo de texto livre idêntico ao de cadastro
          _campo(_tecidoObservacaoController, 'Observação sobre o Tecido (Ex: Etamine Branca)', Icons.layers_outlined),
        ],
      ),
    );
  }

  Widget _bloco3Calculadora() {
    return _blocoContainer(
      titulo: 'Medidas e Cálculo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _campo(_larguraController, 'Largura (pts)', Icons.width_normal_outlined, teclado: TextInputType.number, aoMudar: () => setState(() {})),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFF3C6246))),
              ),
              Expanded(
                child: _campo(_alturaController, 'Altura (pts)', Icons.height_outlined, teclado: TextInputType.number, aoMudar: () => setState(() {})),
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
                  Text('✨ Resultado', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF3C6246))),
                  const SizedBox(height: 8),
                  _linhaCalculo('Tamanho:', '${_larguraCm.toStringAsFixed(1)} × ${_alturaCm.toStringAsFixed(1)} cm'),
                  _linhaCalculo('Corte sugerido:', '${(_larguraCm + _margemTecido).toStringAsFixed(1)} × ${(_alturaCm + _margemTecido).toStringAsFixed(1)} cm'),
                  _linhaCalculo('Tempo estimado:', '${_horasEstimadas.toStringAsFixed(1)} horas'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('💰 Preço sugerido:', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3C6246))),
                      Text('R\$ ${_precoSugerido.toStringAsFixed(2)}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF3C6246))),
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
                      _linhasSelecionadas.isEmpty ? 'Adicionar Linhas do Projeto' : '${_linhasSelecionadas.length} linha(s) selecionada(s)',
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
          _campo(_entradaController, 'Valor Já Pago (R\$)', Icons.payments_outlined, teclado: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          TextField(
            controller: _observacoesController,
            maxLines: 3,
            style: GoogleFonts.montserrat(fontSize: 13),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3C6246),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _salvarEdicao,
        child: Text('Salvar Alterações', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
      style: GoogleFonts.montserrat(fontSize: 13),
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
                child: Text('Selecionar Linhas', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C6246))),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _estoqueLinhas.length,
                  itemBuilder: (_, i) {
                    final l = _estoqueLinhas[i];
                    final selecionada = _linhasSelecionadas.any((s) => s.codigo == l.codigo && s.marca == l.marca);
                    return CheckboxListTile(
                      value: selecionada,
                      activeColor: const Color(0xFF3C6246),
                      title: Text('${l.marca} — ${l.codigo ?? l.nomeCor}', style: GoogleFonts.montserrat(fontSize: 13)),
                      onChanged: (v) {
                        setModalState(() {
                          setState(() {
                            if (v == true) {
                              _linhasSelecionadas.add(LinhaResumida(marca: l.marca, codigo: l.codigo ?? '', nomeCor: l.nomeCor ?? ''));
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
                    child: Text('Confirmar Seleção', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvarEdicao() async {
    if (_clienteSelecionado == null || _dataEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha o cliente e a data de entrega!', style: GoogleFonts.montserrat()), backgroundColor: Colors.red),
      );
      return;
    }

    final valorCobradoTexto = _valorController.text.replaceAll(',', '.');
    final valorPagoTexto = _entradaController.text.replaceAll(',', '.');

    final valorCobrado = double.tryParse(valorCobradoTexto) ?? widget.pedido.valorCobrado;
    final valorPago = double.tryParse(valorPagoTexto) ?? widget.pedido.valorPago;

    String novoStatusPagamento = valorPago <= 0 ? 'PENDENTE' : (valorPago >= valorCobrado ? 'QUITADO' : 'PAGO_PARCIAL');

    final pedidoAtualizado = PedidoModel(
      id: widget.pedido.id,
      cliente: _clienteSelecionado!,
      dataPedido: widget.pedido.dataPedido,
      dataEntrega: _dataEntrega!,
      tema: _temaController.text.isEmpty ? 'Sem tema' : _temaController.text,
      textoBordar: _textoController.text,
      tecido: _tecidoObservacaoController.text, // Persistindo a string editada livremente
      larguraPontos: int.tryParse(_larguraController.text) ?? 0,
      alturaPontos: int.tryParse(_alturaController.text) ?? 0,
      linhas: _linhasSelecionadas,
      valorCobrado: valorCobrado,
      valorPago: valorPago,
      statusProducao: _statusProducao,
      statusPagamento: novoStatusPagamento,
      observacoes: _observacoesController.text,
      urlImagem: widget.pedido.urlImagem,
    );

    await FirestoreService.salvarPedido(pedidoAtualizado);

    if (context.mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Pedido atualizado!', style: GoogleFonts.montserrat()), backgroundColor: const Color(0xFF3C6246)),
      );
    }
  }
}