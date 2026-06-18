import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/marketplace_seed_catalog.dart';
import '../models/marketplace_project.dart';

/// Локальное хранилище маркетплейса (SharedPreferences). Работает без бэкенда;
/// при появлении API можно синхронизировать или заменить источник данных.
class MarketplaceLocalStore {
  MarketplaceLocalStore._();
  static final MarketplaceLocalStore instance = MarketplaceLocalStore._();

  static const _kInit = 'mkt_v2_initialized';
  static const _kProjects = 'mkt_v2_projects';
  static const _kOrderFeed = 'mkt_v2_order_feed';
  static const _kBids = 'mkt_v2_bids';
  static const _kChats = 'mkt_v2_direct_chats';
  static const _kMyBids = 'mkt_v2_master_my_bids';
  static const _kMessages = 'mkt_v2_chat_messages';

  bool _loaded = false;

  List<ProjectSummary> _projects = [];
  List<OrderFeedItem> _orderFeed = [];
  Map<String, List<MasterBid>> _bids = {};
  List<DirectChatThread> _directChats = [];
  List<MasterMyBidRecord> _myBids = [];
  Map<String, List<ChatMessage>> _messages = {};

  List<ProjectSummary> get customerProjects => List.unmodifiable(_projects);
  List<OrderFeedItem> get orderFeed => List.unmodifiable(_orderFeed);
  List<DirectChatThread> get directChats => List.unmodifiable(_directChats);
  List<MasterMyBidRecord> get myMasterBids => List.unmodifiable(_myBids);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kInit) != true) {
      _projects = List.from(MarketplaceSeedCatalog.customerProjects);
      _orderFeed = List.from(MarketplaceSeedCatalog.orderFeed);
      _directChats = List.from(MarketplaceSeedCatalog.directChats);
      _bids = {'p2': List.from(MarketplaceSeedCatalog.bidsForProject('p2'))};
      _myBids = [];
      _messages = {};
      await _persistAll(prefs);
      await prefs.setBool(_kInit, true);
    } else {
      _projects = _decodeList(
        prefs.getString(_kProjects),
        ProjectSummary.fromJson,
      );
      _orderFeed = _decodeList(
        prefs.getString(_kOrderFeed),
        OrderFeedItem.fromJson,
      );
      _directChats = _decodeList(
        prefs.getString(_kChats),
        DirectChatThread.fromJson,
      );
      _bids = _decodeBidMap(prefs.getString(_kBids));
      _myBids = _decodeList(
        prefs.getString(_kMyBids),
        MasterMyBidRecord.fromJson,
      );
      _messages = _decodeMessageMap(prefs.getString(_kMessages));
    }
    _loaded = true;
  }

  MasterProfile profileById(String masterId) =>
      MarketplaceSeedCatalog.profileById(masterId);

  List<MasterBid> bidsForProject(String projectId) =>
      List.from(_bids[projectId] ?? const []);

  /// Реальное число откликов по проекту — единый источник правды для карточек
  /// и счётчиков (чтобы не расходилось с самим списком откликов).
  int responsesCountFor(String projectId) => _bids[projectId]?.length ?? 0;

  Future<void> saveCustomerProjects(List<ProjectSummary> list) async {
    await ensureLoaded();
    _projects = List.from(list);
    await _persistProjects();
  }

  /// Добавляет карточку в ленту заказов при публикации проекта заказчиком.
  Future<void> syncPublishedProject(
    ProjectSummary project, {
    String districtLine = 'Регион уточняется у заказчика',
  }) async {
    await ensureLoaded();
    if (project.status != 'Опубликован') return;
    final exists = _orderFeed.any((e) => e.id == project.id);
    if (exists) return;
    _orderFeed.insert(
      0,
      OrderFeedItem(
        id: project.id,
        workType: project.title,
        budgetLabel: 'По согласованию',
        district: districtLine,
        addressShort: '',
        teaser: 'Заявка опубликована в Приделе.',
        has3d: false,
        fullSpec:
            'Подробности уточняйте у заказчика в переписке или по контактам в профиле.',
      ),
    );
    await _persistOrderFeed();
  }

  Future<void> submitMasterBid({
    required String orderId,
    required MasterBid bid,
    required String projectTitleForMyBids,
  }) async {
    await ensureLoaded();
    _bids.putIfAbsent(orderId, () => []);
    _bids[orderId]!.add(bid);

    final pi = _projects.indexWhere((p) => p.id == orderId);
    if (pi != -1) {
      final old = _projects[pi];
      _projects[pi] = old.copyWith(
        updatedAt: DateTime.now(),
        responsesCount: _bids[orderId]!.length,
      );
    }

    _myBids.insert(
      0,
      MasterMyBidRecord(
        id: bid.id,
        projectTitle: projectTitleForMyBids,
        state: 'Отправлен заказчику',
        price: bid.priceOffer,
        projectId: orderId,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await _persistBids(prefs);
    await _persistProjects(prefs);
    await _persistMyBids(prefs);
  }

  Future<void> replaceDirectChats(List<DirectChatThread> list) async {
    await ensureLoaded();
    _directChats = List.from(list);
    await _persistChats();
  }

  /// Закрытие сделки: заказчик выбрал мастера по проекту.
  /// BACKEND: `POST /projects/{projectId}/select-master {bid_id}` →
  /// проект → `in_work`, выбранный отклик → `selected`, остальные → `declined`,
  /// проект уходит из ленты заказов, создаётся чат заказчик ↔ мастер.
  /// Возвращает диалог с выбранным мастером.
  Future<DirectChatThread> selectMasterForProject({
    required String projectId,
    required MasterBid bid,
    required String projectTitle,
  }) async {
    await ensureLoaded();

    // 1. Проект → «В работе» + кто выбран.
    final pi = _projects.indexWhere((p) => p.id == projectId);
    if (pi != -1) {
      _projects[pi] = _projects[pi].copyWith(
        status: 'В работе',
        updatedAt: DateTime.now(),
        selectedMasterId: bid.masterId,
        selectedMasterName: bid.masterName,
      );
    }

    // 2. Статусы откликов: выбранный → selected, остальные → declined.
    final list = _bids[projectId];
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(
          status: list[i].id == bid.id ? 'selected' : 'declined',
        );
      }
    }

    // 3. «Мои отклики» мастера: выбранный → «Выбран», прочие по проекту → «Не выбран».
    for (var i = 0; i < _myBids.length; i++) {
      final r = _myBids[i];
      final samProject = r.projectId == projectId;
      if (r.id == bid.id) {
        _myBids[i] = r.copyWith(state: 'Выбран заказчиком');
      } else if (samProject) {
        _myBids[i] = r.copyWith(state: 'Не выбран');
      }
    }

    // 4. Сделка закрыта — заказ уходит из ленты мастеров.
    _orderFeed.removeWhere((e) => e.id == projectId);

    // 5. Чат с выбранным мастером.
    final thread = _ensureThread(
      masterId: bid.masterId,
      peerName: bid.masterName,
      projectTitle: projectTitle,
      projectId: projectId,
      seedPreview:
          'Спасибо за выбор! Готов приступить к проекту «$projectTitle». Когда удобно созвониться?',
    );

    final prefs = await SharedPreferences.getInstance();
    await _persistProjects(prefs);
    await _persistBids(prefs);
    await _persistMyBids(prefs);
    await _persistOrderFeed(prefs);
    await _persistChats(prefs);
    await _persistMessages(prefs);
    return thread;
  }

  /// Создаёт или находит диалог с мастером (кнопка «Написать»).
  /// BACKEND: `POST /chats {master_id, project_id}`.
  Future<DirectChatThread> ensureChatThread({
    required String masterId,
    required String peerName,
    required String projectTitle,
    String? projectId,
  }) async {
    await ensureLoaded();
    final thread = _ensureThread(
      masterId: masterId,
      peerName: peerName,
      projectTitle: projectTitle,
      projectId: projectId,
      seedPreview:
          'Здравствуйте! Рад помочь с объектом «$projectTitle». Какие вопросы?',
    );
    final prefs = await SharedPreferences.getInstance();
    await _persistChats(prefs);
    await _persistMessages(prefs);
    return thread;
  }

  /// Находит диалог по проекту (для кнопки «Чат» в проекте).
  DirectChatThread? chatForProject(String projectId) {
    final idx = _directChats.indexWhere((t) => t.projectId == projectId);
    return idx == -1 ? null : _directChats[idx];
  }

  DirectChatThread _ensureThread({
    required String masterId,
    required String peerName,
    required String projectTitle,
    String? projectId,
    String? seedPreview,
  }) {
    final existingIdx = _directChats.indexWhere((t) =>
        t.masterId == masterId &&
        ((projectId != null && t.projectId == projectId) ||
            (projectId == null && t.projectTitle == projectTitle)));
    if (existingIdx != -1) return _directChats[existingIdx];

    final now = DateTime.now();
    final thread = DirectChatThread(
      id: 'chat_${now.millisecondsSinceEpoch}',
      peerName: peerName,
      masterId: masterId,
      lastMessagePreview: seedPreview ?? 'Диалог по объекту «$projectTitle».',
      updatedAt: now,
      projectTitle: projectTitle,
      projectId: projectId,
    );
    _directChats.insert(0, thread);
    if (seedPreview != null && seedPreview.isNotEmpty) {
      _messages[thread.id] = [
        ChatMessage(
          id: 'm_${now.millisecondsSinceEpoch}',
          text: seedPreview,
          mine: false,
          at: now,
        ),
      ];
    }
    return thread;
  }

  // --- Сообщения в переписке ---

  List<ChatMessage> messagesForThread(String threadId) =>
      List.from(_messages[threadId] ?? const []);

  /// Засевает первые сообщения диалога, если он ещё пустой (демо-чаты).
  Future<void> seedThreadMessages(
    String threadId,
    List<ChatMessage> messages,
  ) async {
    await ensureLoaded();
    if ((_messages[threadId] ?? const []).isNotEmpty) return;
    _messages[threadId] = List.from(messages);
    await _persistMessages();
  }

  /// Добавляет сообщение и обновляет превью диалога.
  /// BACKEND: `POST /chats/{threadId}/messages`.
  Future<void> appendMessage(String threadId, ChatMessage message) async {
    await ensureLoaded();
    final list = _messages.putIfAbsent(threadId, () => []);
    list.add(message);

    final ti = _directChats.indexWhere((t) => t.id == threadId);
    if (ti != -1) {
      final preview = message.text.isEmpty && message.imagePath != null
          ? '📷 Фото'
          : message.text;
      _directChats[ti] = _directChats[ti].copyWith(
        lastMessagePreview: message.mine ? 'Вы: $preview' : preview,
        updatedAt: message.at,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await _persistMessages(prefs);
    await _persistChats(prefs);
  }

  Future<void> _persistAll(SharedPreferences prefs) async {
    await _persistProjects(prefs);
    await _persistOrderFeed(prefs);
    await _persistBids(prefs);
    await _persistChats(prefs);
    await _persistMyBids(prefs);
    await _persistMessages(prefs);
  }

  Future<void> _persistProjects([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _kProjects,
      jsonEncode(_projects.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistOrderFeed([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _kOrderFeed,
      jsonEncode(_orderFeed.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistBids([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _bids.forEach((k, v) {
      map[k] = v.map((e) => e.toJson()).toList();
    });
    await p.setString(_kBids, jsonEncode(map));
  }

  Future<void> _persistChats([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _kChats,
      jsonEncode(_directChats.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistMyBids([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _kMyBids,
      jsonEncode(_myBids.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistMessages([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _messages.forEach((k, v) {
      map[k] = v.map((e) => e.toJson()).toList();
    });
    await p.setString(_kMessages, jsonEncode(map));
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Map<String, List<MasterBid>> _decodeBidMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, List<MasterBid>>{};
    map.forEach((k, v) {
      final list = (v as List)
          .map((e) => MasterBid.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      out[k] = list;
    });
    return out;
  }

  static Map<String, List<ChatMessage>> _decodeMessageMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, List<ChatMessage>>{};
    map.forEach((k, v) {
      out[k] = (v as List)
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
    return out;
  }
}
