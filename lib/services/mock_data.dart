import '../models/pedido_model.dart';
import '../models/linha_model.dart';

class MockData {
  static List<ClienteModel> clientes = [
    ClienteModel(id: 'c1', nome: 'Maria Silva', whatsapp: '62999991111'),
    ClienteModel(id: 'c2', nome: 'Ana Costa', whatsapp: '62999992222'),
    ClienteModel(id: 'c3', nome: 'Julia Mendes', whatsapp: '62999993333'),
  ];

  static List<PedidoModel> pedidos = [
    PedidoModel(
      id: 'p1',
      cliente: clientes[0],
      dataPedido: DateTime(2026, 5, 20),
      dataEntrega: DateTime(2026, 6, 15),
      tema: 'Toalha de Batizado',
      textoBordar: 'Gabriel',
      tecido: 'Etamine',
      larguraPontos: 80,
      alturaPontos: 40,
      linhas: [
        LinhaResumida(marca: 'DMC', codigo: '310', nomeCor: 'Preto'),
        LinhaResumida(marca: 'DMC', codigo: '321', nomeCor: 'Vermelho'),
      ],
      valorCobrado: 160.00,
      valorPago: 80.00,
      statusProducao: 'EM_PRODUCAO',
      statusPagamento: 'PAGO_PARCIAL',
      observacoes: 'Cliente pediu para trocar cor das letras de azul para verde.',
    ),
    PedidoModel(
      id: 'p2',
      cliente: clientes[1],
      dataPedido: DateTime(2026, 5, 22),
      dataEntrega: DateTime(2026, 6, 22),
      tema: 'Lençol de Berço',
      textoBordar: 'Flores',
      tecido: 'Etamine',
      larguraPontos: 120,
      alturaPontos: 60,
      linhas: [
        LinhaResumida(marca: 'Anchor', codigo: '403', nomeCor: 'Preto'),
        LinhaResumida(marca: 'DMC', codigo: '604', nomeCor: 'Rosa Claro'),
      ],
      valorCobrado: 300.00,
      valorPago: 0.00,
      statusProducao: 'NA_FILA',
      statusPagamento: 'PENDENTE',
      observacoes: '',
    ),
    PedidoModel(
      id: 'p3',
      cliente: clientes[2],
      dataPedido: DateTime(2026, 5, 10),
      dataEntrega: DateTime(2026, 6, 5),
      tema: 'Pano de Prato',
      textoBordar: 'Bem-vinda',
      tecido: 'Etamine',
      larguraPontos: 60,
      alturaPontos: 30,
      linhas: [
        LinhaResumida(marca: 'DMC', codigo: '550', nomeCor: 'Roxo'),
      ],
      valorCobrado: 90.00,
      valorPago: 90.00,
      statusProducao: 'CONCLUIDO',
      statusPagamento: 'QUITADO',
      observacoes: 'Entregar embalado para presente.',
    ),
  ];

  static List<LinhaModel> estoque = [
    LinhaModel(
      id: 'l1',
      marca: 'DMC',
      codigo: '310',
      nomeCor: 'Preto',
      quantidade: 1.5,
      statusEstoque: 'DISPONIVEL',
    ),
    LinhaModel(
      id: 'l2',
      marca: 'Anchor',
      codigo: '403',
      nomeCor: 'Preto',
      quantidade: 0.2,
      statusEstoque: 'ACABANDO',
    ),
    LinhaModel(
      id: 'l3',
      marca: 'DMC',
      codigo: '321',
      nomeCor: 'Vermelho',
      quantidade: 2.0,
      statusEstoque: 'DISPONIVEL',
    ),
    LinhaModel(
      id: 'l4',
      marca: 'DMC',
      codigo: '604',
      nomeCor: 'Rosa Claro',
      quantidade: 0.0,
      statusEstoque: 'COMPRAR',
    ),
    LinhaModel(
      id: 'l5',
      marca: 'Sem Marca',
      codigo: null,
      nomeCor: 'Verde Folha Escuro',
      quantidade: 0.5,
      statusEstoque: 'DISPONIVEL',
    ),
    LinhaModel(
      id: 'l6',
      marca: 'DMC',
      codigo: '550',
      nomeCor: 'Roxo',
      quantidade: 1.0,
      statusEstoque: 'DISPONIVEL',
    ),
  ];
}