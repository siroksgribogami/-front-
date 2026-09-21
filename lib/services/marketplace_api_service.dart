import '../models/marketplace_project.dart';
import 'api_service.dart';

/// Клиент биржи (ARThouse-backend). Все методы соответствуют эндпоинтам из
/// `docs/marketplace-backend-spec.md` и реальным роутерам бэка
/// (`marketplace_projects.py`, `master_bids.py`, `direct_chats.py`).
///
/// Сервис только маппит JSON ↔ модели фронта. Решение «онлайн или локально»
/// принимает [MarketplaceLocalStore]: при недоступности сервера он ловит
/// исключения и откатывается на локальные данные (офлайн-демо не ломается).
class MarketplaceApiService {
  final ApiService _api;

  MarketplaceApiService({ApiService? api}) : _api = api ?? ApiService();

  // ---------------- Проекты ----------------

  Future<List<ProjectSummary>> getMyProjects() async {
    final resp = await _api.get('/projects/my', requireAuth: true);
    return _list(resp).map(_projectFromApi).toList();
  }

  Future<ProjectSummary> createProject(ProjectSummary p) async {
    final resp = await _api.post(
      '/projects',
      requireAuth: true,
      body: _projectToApi(p),
    );
    return _projectFromApi(_map(resp));
  }

  /// `POST /projects/{id}/publish` — перевод draft → published.
  Future<ProjectSummary> publishProject(
    String projectId, {
    String? district,
    String? address,
  }) async {
    final id = int.tryParse(projectId);
    if (id == null) throw ApiException(statusCode: 0, message: 'Локальный проект');
    final resp = await _api.post(
      '/projects/$id/publish',
      requireAuth: true,
      body: {
        if (district != null) 'district': district,
        if (address != null) 'address': address,
      },
    );
    return _projectFromApi(_map(resp));
  }

  // ---------------- Лента заказов (мастер) ----------------

  Future<List<OrderFeedItem>> getOrders({
    String? workType,
    String? district,
  }) async {
    final resp = await _api.get(
      '/orders',
      requireAuth: true,
      queryParams: {
        if (workType != null && workType.isNotEmpty) 'work_type': workType,
        if (district != null && district.isNotEmpty) 'district': district,
      },
    );
    return _list(resp).map(_orderFromApi).toList();
  }

  Future<List<String>> getOrderDistricts() async {
    final resp = await _api.get('/orders/districts', requireAuth: true);
    return _list(resp).map((e) => e.toString()).toList();
  }

  // ---------------- Отклики ----------------

  Future<List<MasterBid>> getProjectBids(String projectId) async {
    final id = int.tryParse(projectId);
    if (id == null) return const [];
    final resp = await _api.get('/projects/$id/bids', requireAuth: true);
    return _list(resp).map(_bidFromApi).toList();
  }

  Future<MasterBid> submitBid(
    String projectId, {
    required String priceOffer,
    required String durationOffer,
    required String message,
  }) async {
    final id = int.tryParse(projectId);
    if (id == null) throw ApiException(statusCode: 0, message: 'Локальный заказ');
    final resp = await _api.post(
      '/projects/$id/bids',
      requireAuth: true,
      body: {
        'price_offer': priceOffer,
        'duration_offer': durationOffer,
        'message': message,
      },
    );
    return _bidFromApi(_map(resp));
  }

  Future<List<MasterMyBidRecord>> getMyBids() async {
    final resp = await _api.get('/bids/my', requireAuth: true);
    return _list(resp).map(_myBidFromApi).toList();
  }

  /// ⭐ Выбор мастера. Возвращает чат с выбранным мастером.
  Future<DirectChatThread> selectMaster(String projectId, String bidId) async {
    final id = int.tryParse(projectId);
    final bid = int.tryParse(bidId);
    if (id == null || bid == null) {
      throw ApiException(statusCode: 0, message: 'Локальные id');
    }
    final resp = await _api.post(
      '/projects/$id/select-master',
      requireAuth: true,
      body: {'bid_id': bid},
    );
    return _threadFromApi(_map(resp));
  }

  // ---------------- Чаты ----------------

  Future<List<DirectChatThread>> getChats() async {
    final resp = await _api.get('/chats/my', requireAuth: true);
    return _list(resp).map(_threadFromApi).toList();
  }

  Future<DirectChatThread> openChat({
    required String masterId,
    String? projectId,
  }) async {
    final master = int.tryParse(masterId);
    if (master == null) {
      throw ApiException(statusCode: 0, message: 'Локальный мастер');
    }
    final resp = await _api.post(
      '/chats',
      requireAuth: true,
      body: {
        'master_id': master,
        if (projectId != null && int.tryParse(projectId) != null)
          'project_id': int.parse(projectId),
      },
    );
    return _threadFromApi(_map(resp));
  }

  Future<List<ChatMessage>> getMessages(String threadId) async {
    final id = int.tryParse(threadId);
    if (id == null) return const [];
    final resp = await _api.get('/chats/$id/messages', requireAuth: true);
    return _list(resp).map(_messageFromApi).toList();
  }

  Future<ChatMessage> sendMessage(
    String threadId, {
    String text = '',
    String? image,
  }) async {
    final id = int.tryParse(threadId);
    if (id == null) throw ApiException(statusCode: 0, message: 'Локальный чат');
    final resp = await _api.post(
      '/chats/$id/messages',
      requireAuth: true,
      body: {
        'text': text,
        if (image != null && image.isNotEmpty) 'image': image,
      },
    );
    return _messageFromApi(_map(resp));
  }

  // ---------------- Маппинг ----------------

  static List<Map<String, dynamic>> _list(dynamic resp) {
    if (resp is List) {
      return resp.whereType<Map>().map((e) => _map(e)).toList();
    }
    return const [];
  }

  static Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : {};

  static String _statusLabel(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'draft':
        return 'Черновик';
      case 'published':
        return 'Опубликован';
      case 'in_work':
        return 'В работе';
      case 'closed':
        return 'Закрыт';
      case 'archived':
        return 'Архив';
      default:
        return status?.toString() ?? '';
    }
  }

  static String _bidStateLabel(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'selected':
      case 'accepted':
        return 'Выбран заказчиком';
      case 'declined':
        return 'Не выбран';
      case 'withdrawn':
        return 'Отозван';
      case 'sent':
      default:
        return 'Отправлен заказчику';
    }
  }

  static String _bidStatusToken(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'selected':
      case 'accepted':
        return 'selected';
      case 'declined':
      case 'withdrawn':
        return 'declined';
      default:
        return 'sent';
    }
  }

  static DateTime _date(Map<String, dynamic> j, String key, [String? fallback]) {
    final raw = j[key]?.toString() ?? (fallback != null ? j[fallback]?.toString() : null);
    return DateTime.tryParse(raw ?? '') ?? DateTime.now();
  }

  ProjectSummary _projectFromApi(Map<String, dynamic> j) {
    final budgetLabel = j['budget_label']?.toString() ?? '';
    final addressShort = j['address_short']?.toString() ?? '';
    final district = j['district']?.toString() ?? '';
    return ProjectSummary(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      status: _statusLabel(j['status']),
      updatedAt: _date(j, 'updated_at', 'created_at'),
      responsesCount: (j['responses_count'] as num?)?.toInt() ?? 0,
      mapData: (j['map_data'] as Map?)?.cast<String, dynamic>() ?? const {},
      workType: j['work_type']?.toString() ?? '',
      budget: budgetLabel,
      address: addressShort.isNotEmpty ? addressShort : district,
      spec: j['full_spec']?.toString() ?? '',
      selectedMasterId: j['selected_master_id']?.toString(),
      selectedMasterName: j['selected_master_name']?.toString(),
    );
  }

  Map<String, dynamic> _projectToApi(ProjectSummary p) => {
        'title': p.title,
        if (p.workType.isNotEmpty) 'work_type': p.workType,
        if (p.budget.isNotEmpty) 'budget_label': p.budget,
        if (p.address.isNotEmpty) 'address_short': p.address,
        if (p.spec.isNotEmpty) 'full_spec': p.spec,
        'has_3d': p.mapData.isNotEmpty,
      };

  OrderFeedItem _orderFromApi(Map<String, dynamic> j) => OrderFeedItem(
        id: j['id']?.toString() ?? '',
        workType: j['work_type']?.toString() ?? '',
        budgetLabel: j['budget_label']?.toString() ?? 'По согласованию',
        district: j['district']?.toString() ?? 'Регион уточняется',
        addressShort: j['address_short']?.toString() ?? '',
        teaser: j['teaser']?.toString() ?? '',
        has3d: j['has_3d'] as bool? ?? false,
        fullSpec: j['full_spec']?.toString() ?? '',
      );

  MasterBid _bidFromApi(Map<String, dynamic> j) => MasterBid(
        id: j['id']?.toString() ?? '',
        masterId: j['master_id']?.toString() ?? '',
        masterName: j['master_name']?.toString() ?? 'Мастер',
        specialty: j['specialty']?.toString() ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        completedJobs: (j['completed_jobs'] as num?)?.toInt() ?? 0,
        priceOffer: j['price_offer']?.toString() ?? '',
        durationOffer: j['duration_offer']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        status: _bidStatusToken(j['status']),
      );

  MasterMyBidRecord _myBidFromApi(Map<String, dynamic> j) => MasterMyBidRecord(
        id: j['id']?.toString() ?? '',
        projectTitle: j['project_title']?.toString() ??
            (j['project_id'] != null ? 'Проект №${j['project_id']}' : 'Заказ'),
        state: _bidStateLabel(j['status']),
        price: j['price_offer']?.toString() ?? '',
        projectId: j['project_id']?.toString(),
      );

  DirectChatThread _threadFromApi(Map<String, dynamic> j) => DirectChatThread(
        id: j['id']?.toString() ?? '',
        peerName: j['peer_name']?.toString() ?? 'Собеседник',
        masterId: j['master_id']?.toString(),
        lastMessagePreview: j['last_message_preview']?.toString() ?? '',
        updatedAt: _date(j, 'updated_at'),
        projectTitle: j['project_title']?.toString() ?? '',
        projectId: j['project_id']?.toString(),
      );

  ChatMessage _messageFromApi(Map<String, dynamic> j) => ChatMessage(
        id: j['id']?.toString() ?? '',
        text: j['text']?.toString() ?? '',
        mine: j['mine'] as bool? ?? false,
        at: _date(j, 'at', 'created_at'),
        imagePath: (j['image_path']?.toString().isNotEmpty ?? false)
            ? j['image_path'].toString()
            : null,
      );
}
