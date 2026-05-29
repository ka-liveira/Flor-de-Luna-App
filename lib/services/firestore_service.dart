import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_model.dart';
import '../models/linha_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── PEDIDOS ────────────────────────────────────────────────────

  static Stream<List<PedidoModel>> streamPedidos() {
    return _db
        .collection('pedidos')
        .orderBy('dataEntrega')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => _pedidoFromDoc(doc)).toList());
  }

  static Future<void> salvarPedido(PedidoModel pedido) async {
    await _db.collection('pedidos').doc(pedido.id).set(_pedidoToMap(pedido));
  }

  static Future<void> excluirPedido(String id) async {
    await _db.collection('pedidos').doc(id).delete();
  }

  // ─── CLIENTES ───────────────────────────────────────────────────

  // Busca em tempo real (Stream)
  static Stream<List<ClienteModel>> streamClientes() {
    return _db.collection('clientes').snapshots().map((snap) =>
        snap.docs.map((doc) => ClienteModel(
              id: doc.id,
              nome: doc['nome'],
              whatsapp: doc['whatsapp'],
            )).toList());
  }

  // NOVA: Busca única para carregar seletores/dropdowns (Future)
  static Future<List<ClienteModel>> buscarClientes() async {
    final snap = await _db.collection('clientes').get();
    return snap.docs.map((doc) => ClienteModel(
          id: doc.id,
          nome: doc['nome'] ?? '',
          whatsapp: doc['whatsapp'] ?? '',
        )).toList();
  }

  static Future<void> salvarCliente(ClienteModel cliente) async {
    await _db.collection('clientes').doc(cliente.id).set({
      'nome': cliente.nome,
      'whatsapp': cliente.whatsapp,
      'dataCadastro': FieldValue.serverTimestamp(),
    });
  }

  // ─── ESTOQUE ────────────────────────────────────────────────────

  // Busca em tempo real (Stream)
  static Stream<List<LinhaModel>> streamEstoque() {
    return _db.collection('estoque_linhas').snapshots().map((snap) =>
        snap.docs.map((doc) => LinhaModel(
              id: doc.id,
              marca: doc['marca'],
              codigo: doc['codigo'],
              nomeCor: doc['nomeCor'],
              quantidade: (doc['quantidade'] as num).toDouble(),
              statusEstoque: doc['statusEstoque'],
            )).toList());
  }

  // NOVA: Busca única para abrir modais de seleção (Future)
  static Future<List<LinhaModel>> buscarEstoque() async {
    final snap = await _db.collection('estoque_linhas').get();
    return snap.docs.map((doc) => LinhaModel(
          id: doc.id,
          marca: doc['marca'] ?? '',
          codigo: doc['codigo'] ?? '',
          nomeCor: doc['nomeCor'] ?? '',
          quantidade: (doc['quantidade'] as num? ?? 0).toDouble(),
          statusEstoque: doc['statusEstoque'] ?? '',
        )).toList();
  }

  static Future<void> salvarLinha(LinhaModel linha) async {
    await _db.collection('estoque_linhas').doc(linha.id).set({
      'marca': linha.marca,
      'codigo': linha.codigo,
      'nomeCor': linha.nomeCor,
      'quantidade': linha.quantidade,
      'statusEstoque': linha.statusEstoque,
    });
  }

  static Future<void> excluirLinha(String id) async {
    await _db.collection('estoque_linhas').doc(id).delete();
  }

  // ─── CONVERSORES ────────────────────────────────────────────────

  static Map<String, dynamic> _pedidoToMap(PedidoModel p) {
    return {
      'clienteId': p.cliente.id,
      'clienteNome': p.cliente.nome,
      'clienteWhatsapp': p.cliente.whatsapp,
      'dataPedido': Timestamp.fromDate(p.dataPedido),
      'dataEntrega': Timestamp.fromDate(p.dataEntrega),
      'tema': p.tema,
      'textoBordar': p.textoBordar,
      'tecido': p.tecido,
      'larguraPontos': p.larguraPontos,
      'alturaPontos': p.alturaPontos,
      'linhas': p.linhas.map((l) => {
        'marca': l.marca,
        'codigo': l.codigo,
        'nomeCor': l.nomeCor,
      }).toList(),
      'valorCobrado': p.valorCobrado,
      'valorPago': p.valorPago,
      'statusProducao': p.statusProducao,
      'statusPagamento': p.statusPagamento,
      'observacoes': p.observacoes,
      'urlImagem': p.urlImagem,
    };
  }

  static PedidoModel _pedidoFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PedidoModel(
      id: doc.id,
      cliente: ClienteModel(
        id: data['clienteId'],
        nome: data['clienteNome'],
        whatsapp: data['clienteWhatsapp'],
      ),
      dataPedido: (data['dataPedido'] as Timestamp).toDate(),
      dataEntrega: (data['dataEntrega'] as Timestamp).toDate(),
      tema: data['tema'],
      textoBordar: data['textoBordar'],
      tecido: data['tecido'],
      larguraPontos: data['larguraPontos'],
      alturaPontos: data['alturaPontos'],
      linhas: (data['linhas'] as List).map((l) => LinhaResumida(
            marca: l['marca'],
            codigo: l['codigo'],
            nomeCor: l['nomeCor'],
          )).toList(),
      valorCobrado: (data['valorCobrado'] as num).toDouble(),
      valorPago: (data['valorPago'] as num).toDouble(),
      statusProducao: data['statusProducao'],
      statusPagamento: data['statusPagamento'],
      observacoes: data['observacoes'] ?? '',
      urlImagem: data['urlImagem'],
    );
  }
}