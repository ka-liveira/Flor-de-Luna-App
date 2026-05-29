import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../models/linha_model.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  String _filtroMarca = 'TODAS';
  String _busca = '';

  List<LinhaModel> _filtrar(List<LinhaModel> linhas) {
    return linhas.where((l) {
      final buscaOk =
          (l.codigo ?? '').toLowerCase().contains(_busca.toLowerCase()) ||
              l.nomeCor.toLowerCase().contains(_busca.toLowerCase());
      if (!buscaOk) return false;
      switch (_filtroMarca) {
        case 'DMC':
          return l.marca == 'DMC';
        case 'ANCHOR':
          return l.marca == 'Anchor';
        case 'SEM_CODIGO':
          return l.codigo == null || l.codigo!.isEmpty;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9EFE1),
      body: SafeArea(
        child: StreamBuilder<List<LinhaModel>>(
          stream: FirestoreService.streamEstoque(),
          builder: (context, snapshot) {
            final linhas = snapshot.data ?? [];
            final filtradas = _filtrar(linhas);
            final totalComprar =
                linhas.where((l) => l.statusEstoque == 'COMPRAR').length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalho(totalComprar),
                _barraBusca(),
                _filtrosMarca(),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFF39AA5)))
                      : filtradas.isEmpty
                          ? _estadoVazio()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: filtradas.length,
                              itemBuilder: (_, i) => GestureDetector(
                                // Ao clicar em qualquer lugar do card, abre a modal de edição preenchida
                                onTap: () => _modalCadastrarOuEditarLinha(filtradas[i]),
                                child: _cardLinha(filtradas[i]),
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF39AA5),
        onPressed: () => _modalCadastrarOuEditarLinha(), // Abre vazia para cadastro
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _cabecalho(int totalComprar) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧵 Estoque de Linhas',
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C6246))),
              ],
            ),
          ),
          if (totalComprar > 0)
            GestureDetector(
              onTap: () {
                // Se quiser abrir a modal ao clicar, chame sua função aqui:
                // _abrirModalListaDeCompras();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '$totalComprar ${totalComprar == 1 ? "linha" : "linhas"} para comprar',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barraBusca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (v) => setState(() => _busca = v),
        style: GoogleFonts.montserrat(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar por número ou cor...',
          hintStyle: GoogleFonts.montserrat(fontSize: 13),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF3C6246)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filtrosMarca() {
    final filtros = [
      ('TODAS', 'Todas'),
      ('DMC', 'DMC'),
      ('ANCHOR', 'Anchor'),
      ('SEM_CODIGO', 'Sem Código'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: filtros.map((f) {
          final ativo = _filtroMarca == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filtroMarca = f.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ativo ? const Color(0xFF3C6246) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: ativo
                        ? const Color(0xFF3C6246)
                        : Colors.grey.shade300),
              ),
              child: Text(f.$2,
                  style: GoogleFonts.montserrat(
                      color:
                          ativo ? Colors.white : const Color(0xFF1C2321),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _cardLinha(LinhaModel linha) {
    final cor = _corStatus(linha.statusEstoque);
    final corCirculo = _corDMC(linha.codigo);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        border: linha.statusEstoque == 'COMPRAR'
            ? Border.all(color: Colors.red.shade200, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: corCirculo,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(linha.marcaECodigo,
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF1C2321))),
                Text(linha.nomeCor,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${linha.quantidade} meadas',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: const Color(0xFF1C2321))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: cor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_labelStatus(linha.statusEstoque),
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cor)),
              ),
            ],
          ),
        PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Colors.grey.shade400, size: 20),
            // CORREÇÃO AQUI: Adicionada a opção de Editar no menu
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'editar', child: Text('Editar')),
              const PopupMenuItem(
                  value: 'excluir', child: Text('Excluir')),
            ],
          
            onSelected: (v) async {
              if (v == 'editar') {
                _modalCadastrarOuEditarLinha(linha); // Abre a modal de edição
              } else if (v == 'excluir') {
                await FirestoreService.excluirLinha(linha.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Nenhuma linha no estoque.\nClique no + para adicionar!',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // MODIFICAÇÃO E CORREÇÃO: Todos os campos agora usam o '_campoTextoModal' correto para renderizar os dados na edição
  void _modalCadastrarOuEditarLinha([LinhaModel? linhaExistente]) {
    final bool isEdicao = linhaExistente != null;

    final marcaCtrl = TextEditingController(text: linhaExistente?.marca ?? '');
    final codigoCtrl = TextEditingController(text: linhaExistente?.codigo ?? '');
    final nomeCtrl = TextEditingController(text: linhaExistente?.nomeCor ?? '');
    final qtdCtrl = TextEditingController(
      text: isEdicao ? linhaExistente.quantidade.toString() : '1.0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdicao ? 'Editar Meada' : 'Nova Linha',
          style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3C6246)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campoTextoModal('Marca', marcaCtrl),
            const SizedBox(height: 10),
            _campoTextoModal('Código — opcional', codigoCtrl),
            const SizedBox(height: 10),
            _campoTextoModal('Nome da Cor', nomeCtrl),
            const SizedBox(height: 10),
            _campoTextoModal('Quantidade', qtdCtrl, teclado: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.montserrat(
                    color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39AA5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nomeCtrl.text.isEmpty) return;
              
              final qtdText = qtdCtrl.text.replaceAll(',', '.');
              final qtd = double.tryParse(qtdText) ?? 1.0;
              
              String status;
              if (qtd <= 0) {
                status = 'COMPRAR';
              } else if (qtd <= 0.3) {
                status = 'ACABANDO';
              } else {
                status = 'DISPONIVEL';
              }

              final linhaMapeada = LinhaModel(
                id: linhaExistente?.id ?? const Uuid().v4(),
                marca: marcaCtrl.text.isEmpty ? 'Sem Marca' : marcaCtrl.text,
                codigo: codigoCtrl.text.isEmpty ? null : codigoCtrl.text,
                nomeCor: nomeCtrl.text,
                quantidade: qtd,
                statusEstoque: status,
              );

              await FirestoreService.salvarLinha(linhaMapeada);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdicao ? 'Atualizar' : 'Salvar',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _campoTextoModal(String hint, TextEditingController ctrl,
      {TextInputType teclado = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: teclado,
      style: GoogleFonts.montserrat(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'DISPONIVEL':
        return const Color(0xFF3C6246);
      case 'ACABANDO':
        return const Color(0xFFF4C47C);
      default:
        return Colors.red;
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'DISPONIVEL':
        return '🟢 Disponível';
      case 'ACABANDO':
        return '🟡 Acabando';
      default:
        return '🔴 Comprar';
    }
  }

  Color _corDMC(String? codigo) {
    final cores = {
      '310': const Color(0xFF1C2321),
      '321': const Color(0xFFCC2222),
      '604': const Color(0xFFFFB6C1),
      '550': const Color(0xFF6A0DAD),
      '403': const Color(0xFF2C2C2C),
    };
    return cores[codigo] ?? const Color(0xFF9E9E9E);
  }
}