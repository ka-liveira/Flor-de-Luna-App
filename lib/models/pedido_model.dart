class ClienteModel {
  final String id;
  final String nome;
  final String whatsapp;

  ClienteModel({
    required this.id,
    required this.nome,
    required this.whatsapp,
  });
}

class PedidoModel {
  final String id;
  final ClienteModel cliente;
  final DateTime dataPedido;
  final DateTime dataEntrega;
  final String tema;
  final String textoBordar;
  final String tecido;
  final int larguraPontos;
  final int alturaPontos;
  final List<LinhaResumida> linhas;
  final double valorCobrado;
  final double valorPago;
  final String statusProducao; // NA_FILA, EM_PRODUCAO, CONCLUIDO, ENTREGUE
  final String statusPagamento; // PENDENTE, PAGO_PARCIAL, QUITADO
  final String observacoes;
  final String? urlImagem;

  PedidoModel({
    required this.id,
    required this.cliente,
    required this.dataPedido,
    required this.dataEntrega,
    required this.tema,
    required this.textoBordar,
    required this.tecido,
    required this.larguraPontos,
    required this.alturaPontos,
    required this.linhas,
    required this.valorCobrado,
    required this.valorPago,
    required this.statusProducao,
    required this.statusPagamento,
    required this.observacoes,
    this.urlImagem,
  });

  double get valorRestante => valorCobrado - valorPago;

  int get diasParaEntrega => dataEntrega.difference(DateTime.now()).inDays;

  bool get entregaProxima => diasParaEntrega <= 5 && diasParaEntrega >= 0;
}

class LinhaResumida {
  final String marca;
  final String codigo;
  final String nomeCor;

  LinhaResumida({
    required this.marca,
    required this.codigo,
    required this.nomeCor,
  });
}