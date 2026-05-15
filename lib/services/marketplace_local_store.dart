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

  bool _loaded = false;

  List<ProjectSummary> _projects = [];
  List<OrderFeedItem> _orderFeed = [];
  Map<String, List<MasterBid>> _bids = {};
  List<DirectChatThread> _directChats = [];
  List<MasterMyBidRecord> _myBids = [];

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
    }
    _loaded = true;
  }

  MasterProfile profileById(String masterId) =>
      MarketplaceSeedCatalog.profileById(masterId);

  List<MasterBid> bidsForProject(String projectId) =>
      List.from(_bids[projectId] ?? const []);

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
        teaser: 'Заявка опубликована в ARThouse.',
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
      _projects[pi] = ProjectSummary(
        id: old.id,
        title: old.title,
        status: old.status,
        updatedAt: DateTime.now(),
        responsesCount: old.responsesCount + 1,
      );
    }

    _myBids.insert(
      0,
      MasterMyBidRecord(
        id: bid.id,
        projectTitle: projectTitleForMyBids,
        state: 'Отправлен заказчику',
        price: bid.priceOffer,
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

  Future<void> _persistAll(SharedPreferences prefs) async {
    await _persistProjects(prefs);
    await _persistOrderFeed(prefs);
    await _persistBids(prefs);
    await _persistChats(prefs);
    await _persistMyBids(prefs);
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
}
