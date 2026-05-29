import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pedido_model.dart';
import 'editar_pedido_screen.dart';
import '../services/firestore_service.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {

  // Centralizamos as ações de alteração de valores enviando as atualizações para o Firestore
  Future<void> _acaoMenu(String acao, PedidoModel pedido) async {
    switch (acao) {
      case 'quitar':
        _confirmarQuitacao(pedido);
        break;
      case 'parcial':
        _modalPagamentoParcial(pedido);
        break;
      case 'editar':
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EditarPedidoScreen(pedido: pedido)),
        );
        break;
    }
  }

  void _confirmarQuitacao(PedidoModel pedido) {
    // Cálculo do valor restante baseado nas regras de negócio do modelo
    final valorRestante = pedido.valorCobrado - pedido.valorPago;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9EFE1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Dar Baixa no Pedido',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold, color: const Color(0xFF1C2321))),
        content: Text(
          'Confirmar que ${pedido.cliente.nome} pagou o valor restante de R\$ ${valorRestante.toStringAsFixed(2)}?',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.montserrat(color: const Color(0xFF3C6246))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C6246),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              // Criamos o objeto atualizado com o valor total quitado
              final pedidoQuitado = PedidoModel(
                id: pedido.id,
                cliente: pedido.cliente,
                dataPedido: pedido.dataPedido,
                dataEntrega: pedido.dataEntrega,
                tema: pedido.tema,
                textoBordar: pedido.textoBordar,
                tecido: pedido.tecido,
                larguraPontos: pedido.larguraPontos,
                alturaPontos: pedido.alturaPontos,
                linhas: pedido.linhas,
                valorCobrado: pedido.valorCobrado,
                valorPago: pedido.valorCobrado, // Valor totalmente pago
                statusProducao: pedido.statusProducao,
                statusPagamento: 'QUITADO',
                observacoes: pedido.observacoes,
                urlImagem: pedido.urlImagem,
              );

              // Atualiza diretamente no Firestore
              await FirestoreService.salvarPedido(pedidoQuitado);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pedido quitado com sucesso!',
                        style: GoogleFonts.montserrat()),
                    backgroundColor: const Color(0xFF3C6246),
                  ),
                );
              }
            },
            child: Text('Confirmar',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _modalPagamentoParcial(PedidoModel pedido) {
    final valorCtrl = TextEditingController();
    final valorRestante = pedido.valorCobrado - pedido.valorPago;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9EFE1),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar Pagamento',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3C6246))),
            Text('${pedido.cliente.nome} · ${pedido.tema}',
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              'Saldo devedor: R\$ ${valorRestante.toStringAsFixed(2)}',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Valor recebido (R\$)',
                hintStyle: GoogleFonts.montserrat(fontSize: 13),
                prefixIcon: const Icon(Icons.attach_money,
                    color: Color(0xFF3C6246)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3C6246)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: GoogleFonts.montserrat(
                            color: const Color(0xFF3C6246))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39AA5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final valorRecebido = double.tryParse(valorCtrl.text) ?? 0;
                      final novoTotal = pedido.valorPago + valorRecebido;
                      final novoStatus = novoTotal >= pedido.valorCobrado
                          ? 'QUITADO'
                          : 'PAGO_PARCIAL';

                      final pedidoAtualizado = PedidoModel(
                        id: pedido.id,
                        cliente: pedido.cliente,
                        dataPedido: pedido.dataPedido,
                        dataEntrega: pedido.dataEntrega,
                        tema: pedido.tema,
                        textoBordar: pedido.textoBordar,
                        tecido: pedido.tecido,
                        larguraPontos: pedido.larguraPontos,
                        alturaPontos: pedido.alturaPontos,
                        linhas: pedido.linhas,
                        valorCobrado: pedido.valorCobrado,
                        valorPago: novoTotal,
                        statusProducao: pedido.statusProducao,
                        statusPagamento: novoStatus,
                        observacoes: pedido.observacoes,
                        urlImagem: pedido.urlImagem,
                      );

                      // Salva as alterações financeiras direto no Firestore
                      await FirestoreService.salvarPedido(pedidoAtualizado);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              novoStatus == 'QUITADO'
                                  ? 'Pedido quitado!'
                                  : 'Pagamento registrado!',
                              style: GoogleFonts.montserrat(),
                            ),
                            backgroundColor: const Color(0xFF3C6246),
                          ),
                        );
                      }
                    },
                    child: Text('Confirmar',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o StreamPedidos do seu FirestoreService para escutar o banco em tempo real
    return StreamBuilder<List<PedidoModel>>(
      stream: FirestoreService.streamPedidos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9EFE1),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF3C6246))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9EFE1),
            body: Center(child: Text('Erro ao carregar dados financeiros: ${snapshot.error}')),
          );
        }

        final pedidosReal = snapshot.data ?? [];

        // Re-calculamos as variáveis locais dinamicamente com base nos dados reais do Firebase
        final double faturamentoBruto = pedidosReal.fold(0, (s, p) => s + p.valorCobrado);
        final double totalRecebido = pedidosReal.fold(0, (s, p) => s + p.valorPago);
        final double aReceber = pedidosReal.fold(0, (s, p) => s + (p.valorCobrado - p.valorPago));

        // Filtra a lista de devedores vindos do Firestore
        final List<PedidoModel> devedores = pedidosReal
            .where((p) => p.statusPagamento != 'QUITADO')
            .toList()
          ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));

        return Scaffold(
          backgroundColor: const Color(0xFFF9EFE1),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(faturamentoBruto, totalRecebido, aReceber),
                  const SizedBox(height: 20),
                  _graficoMeses(totalRecebido),
                  const SizedBox(height: 24),
                  _tituloSecao('Valores a Receber'),
                  const SizedBox(height: 12),
                  ...devedores.map(_cardDevedor),
                  if (devedores.isEmpty) _estadoVazio(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cabecalho(double faturamento, double recebido, double pendente) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C6246), Color(0xFF5A8A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financeiro',
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text('Maio de 2026',
              style: GoogleFonts.montserrat(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              _blocoValor('Faturamento Bruto', faturamento, const Color(0xFFF39AA5)),
              const SizedBox(width: 12),
              _blocoValor('Já Recebido', recebido, const Color(0xFF63C1E2)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF4C47C).withOpacity(0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('A Receber',
                    style: GoogleFonts.montserrat(
                        color: Colors.white70, fontSize: 13)),
                Text(
                  'R\$ ${pendente.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFFF4C47C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoValor(String titulo, double valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: GoogleFonts.montserrat(
                    color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            Text('R\$ ${valor.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _graficoMeses(double totalRecebidoAtual) {
    final meses = [
      ('Mar', 320.0),
      ('Abr', 480.0),
      ('Mai', totalRecebidoAtual),
    ];
    final maximo = meses.map((m) => m.$2).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolução Mensal',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF3C6246))),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: meses.map((m) {
              final altura = maximo > 0 ? (m.$2 / maximo) * 120 : 0.0;
              final ativo = m.$1 == 'Mai';
              return Column(
                children: [
                  Text('R\$ ${m.$2.toStringAsFixed(0)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          color: ativo ? const Color(0xFF3C6246) : Colors.grey)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: 48,
                    height: altura,
                    decoration: BoxDecoration(
                      color: ativo
                          ? const Color(0xFF3C6246)
                          : const Color(0xFFF39AA5).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(m.$1,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                          color: ativo ? const Color(0xFF3C6246) : Colors.grey)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String titulo) {
    return Text(titulo,
        style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2321)));
  }

  Widget _cardDevedor(PedidoModel pedido) {
    final formatData = DateFormat('dd/MMM', 'pt_BR');
    final valorRestante = pedido.valorCobrado - pedido.valorPago;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👤', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pedido.cliente.nome} · ${pedido.tema}',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF1C2321),
                  ),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF3C6246)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'quitar', child: Text('Dar Baixa / Quitar')),
                  const PopupMenuItem(
                      value: 'parcial', child: Text('Registrar Pagamento Parcial')),
                  const PopupMenuItem(
                      value: 'editar', child: Text('✏️ Editar Pedido')),
                ],
                onSelected: (v) => _acaoMenu(v.toString(), pedido),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('Entrega: ${formatData.format(pedido.dataEntrega)}',
                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Text(
                'Total: R\$ ${pedido.pedidoValorCobradoFormatado(pedido.valorCobrado)}',
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Já pago: R\$ ${pedido.valorPago.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Falta: R\$ ${valorRestante.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text('Tudo quitado! Nenhum valor pendente.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// Extensão utilitária para manter compatibilidade de formatação visual sem quebrar strings
extension PedidoModelFormat on PedidoModel {
  String pedidoValorCobradoFormatado(double valor) => valor.toStringAsFixed(2);
}