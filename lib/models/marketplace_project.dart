class ProjectSummary {
  final String id;
  final String title;
  final String status;
  final DateTime updatedAt;
  final int responsesCount;
  final Map<String, dynamic> mapData;
  final String workType;
  final String budget;
  final String address;
  final String spec;

  /// Кто выбран по проекту (заполняется при закрытии сделки).
  /// BACKEND: приходит из проекта (`selected_master_id` / имя исполнителя).
  final String? selectedMasterId;
  final String? selectedMasterName;

  const ProjectSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.responsesCount = 0,
    this.mapData = const {},
    this.workType = '',
    this.budget = '',
    this.address = '',
    this.spec = '',
    this.selectedMasterId,
    this.selectedMasterName,
  });

  bool get hasBrief =>
      workType.trim().isNotEmpty ||
      budget.trim().isNotEmpty ||
      address.trim().isNotEmpty ||
      spec.trim().isNotEmpty;

  String get briefLine {
    if (workType.trim().isNotEmpty) return workType.trim();
    if (budget.trim().isNotEmpty) return budget.trim();
    return 'Заполните заявку';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'updated_at': updatedAt.toIso8601String(),
        'responses_count': responsesCount,
        'map_data': mapData,
        'work_type': workType,
        'budget': budget,
        'address': address,
        'spec': spec,
        'selected_master_id': selectedMasterId,
        'selected_master_name': selectedMasterName,
      };

  factory ProjectSummary.fromJson(Map<String, dynamic> j) {
    return ProjectSummary(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      responsesCount: (j['responses_count'] as num?)?.toInt() ?? 0,
      mapData: (j['map_data'] as Map<String, dynamic>?) ?? {},
      workType: j['work_type']?.toString() ?? '',
      budget: j['budget']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      spec: j['spec']?.toString() ?? '',
      selectedMasterId: (j['selected_master_id']?.toString().isNotEmpty ?? false)
          ? j['selected_master_id'].toString()
          : null,
      selectedMasterName:
          (j['selected_master_name']?.toString().isNotEmpty ?? false)
              ? j['selected_master_name'].toString()
              : null,
    );
  }

  ProjectSummary copyWith({
    String? id,
    String? title,
    String? status,
    DateTime? updatedAt,
    int? responsesCount,
    Map<String, dynamic>? mapData,
    String? workType,
    String? budget,
    String? address,
    String? spec,
    String? selectedMasterId,
    String? selectedMasterName,
  }) {
    return ProjectSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      responsesCount: responsesCount ?? this.responsesCount,
      mapData: mapData ?? this.mapData,
      workType: workType ?? this.workType,
      budget: budget ?? this.budget,
      address: address ?? this.address,
      spec: spec ?? this.spec,
      selectedMasterId: selectedMasterId ?? this.selectedMasterId,
      selectedMasterName: selectedMasterName ?? this.selectedMasterName,
    );
  }
}

/// Карточка в ленте заказов (мастер).
class OrderFeedItem {
  final String id;
  final String workType;
  final String budgetLabel;
  final String district;
  final String addressShort;
  final String teaser;
  final bool has3d;
  final String fullSpec;

  const OrderFeedItem({
    required this.id,
    required this.workType,
    required this.budgetLabel,
    required this.district,
    required this.addressShort,
    required this.teaser,
    required this.has3d,
    required this.fullSpec,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'work_type': workType,
        'budget_label': budgetLabel,
        'district': district,
        'address_short': addressShort,
        'teaser': teaser,
        'has_3d': has3d,
        'full_spec': fullSpec,
      };

  factory OrderFeedItem.fromJson(Map<String, dynamic> j) {
    return OrderFeedItem(
      id: j['id']?.toString() ?? '',
      workType: j['work_type']?.toString() ?? '',
      budgetLabel: j['budget_label']?.toString() ?? '',
      district: j['district']?.toString() ?? '',
      addressShort: j['address_short']?.toString() ?? '',
      teaser: j['teaser']?.toString() ?? '',
      has3d: j['has_3d'] as bool? ?? false,
      fullSpec: j['full_spec']?.toString() ?? '',
    );
  }
}

/// Отклик мастера на проект.
class MasterBid {
  final String id;
  final String masterId;
  final String masterName;
  final String specialty;
  final double rating;
  final int completedJobs;
  final String priceOffer;
  final String durationOffer;
  final String message;

  /// Статус отклика: `sent` · `selected` · `declined`.
  /// Меняется заказчиком при выборе мастера; обе стороны читают одно значение.
  final String status;

  const MasterBid({
    required this.id,
    required this.masterId,
    required this.masterName,
    required this.specialty,
    required this.rating,
    required this.completedJobs,
    required this.priceOffer,
    required this.durationOffer,
    required this.message,
    this.status = 'sent',
  });

  bool get isSelected => status == 'selected';
  bool get isDeclined => status == 'declined';

  Map<String, dynamic> toJson() => {
        'id': id,
        'master_id': masterId,
        'master_name': masterName,
        'specialty': specialty,
        'rating': rating,
        'completed_jobs': completedJobs,
        'price_offer': priceOffer,
        'duration_offer': durationOffer,
        'message': message,
        'status': status,
      };

  factory MasterBid.fromJson(Map<String, dynamic> j) {
    return MasterBid(
      id: j['id']?.toString() ?? '',
      masterId: j['master_id']?.toString() ?? '',
      masterName: j['master_name']?.toString() ?? '',
      specialty: j['specialty']?.toString() ?? '',
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      completedJobs: (j['completed_jobs'] as num?)?.toInt() ?? 0,
      priceOffer: j['price_offer']?.toString() ?? '',
      durationOffer: j['duration_offer']?.toString() ?? '',
      message: j['message']?.toString() ?? '',
      status: j['status']?.toString() ?? 'sent',
    );
  }

  MasterBid copyWith({String? status}) {
    return MasterBid(
      id: id,
      masterId: masterId,
      masterName: masterName,
      specialty: specialty,
      rating: rating,
      completedJobs: completedJobs,
      priceOffer: priceOffer,
      durationOffer: durationOffer,
      message: message,
      status: status ?? this.status,
    );
  }
}

/// Профиль мастера для просмотра заказчиком.
class MasterProfile {
  final String id;
  final String name;
  final String specialty;
  final String about;
  final double rating;
  final int reviewsCount;
  final int completedJobs;
  final String statusLabel;
  final List<String> portfolioPlaceholders;
  final List<String> certificates;
  final List<MasterReview> reviews;

  const MasterProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.about,
    required this.rating,
    required this.reviewsCount,
    required this.completedJobs,
    required this.statusLabel,
    required this.portfolioPlaceholders,
    required this.certificates,
    required this.reviews,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'about': about,
        'rating': rating,
        'reviews_count': reviewsCount,
        'completed_jobs': completedJobs,
        'status_label': statusLabel,
        'portfolio_placeholders': portfolioPlaceholders,
        'certificates': certificates,
        'reviews': reviews.map((e) => e.toJson()).toList(),
      };

  factory MasterProfile.fromJson(Map<String, dynamic> j) {
    final rev = j['reviews'];
    return MasterProfile(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      specialty: j['specialty']?.toString() ?? '',
      about: j['about']?.toString() ?? '',
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (j['reviews_count'] as num?)?.toInt() ?? 0,
      completedJobs: (j['completed_jobs'] as num?)?.toInt() ?? 0,
      statusLabel: j['status_label']?.toString() ?? '',
      portfolioPlaceholders: (j['portfolio_placeholders'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      certificates:
          (j['certificates'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      reviews: rev is List
          ? rev
              .map((e) => MasterReview.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

class MasterReview {
  final String author;
  final double rating;
  final String text;

  const MasterReview({
    required this.author,
    required this.rating,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'author': author,
        'rating': rating,
        'text': text,
      };

  factory MasterReview.fromJson(Map<String, dynamic> json) => MasterReview(
        author: json['author']?.toString() ?? 'Пользователь',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        text: json['text']?.toString() ?? '',
      );
}

/// Чат заказчик ↔ мастер.
class DirectChatThread {
  final String id;
  final String peerName;
  final String? masterId;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final String projectTitle;

  /// Привязка диалога к проекту заказчика (если есть).
  final String? projectId;

  const DirectChatThread({
    required this.id,
    required this.peerName,
    this.masterId,
    required this.lastMessagePreview,
    required this.updatedAt,
    required this.projectTitle,
    this.projectId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'peer_name': peerName,
        'master_id': masterId,
        'last_message_preview': lastMessagePreview,
        'updated_at': updatedAt.toIso8601String(),
        'project_title': projectTitle,
        'project_id': projectId,
      };

  factory DirectChatThread.fromJson(Map<String, dynamic> j) {
    return DirectChatThread(
      id: j['id']?.toString() ?? '',
      peerName: j['peer_name']?.toString() ?? '',
      masterId: j['master_id']?.toString(),
      lastMessagePreview: j['last_message_preview']?.toString() ?? '',
      updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      projectTitle: j['project_title']?.toString() ?? '',
      projectId: (j['project_id']?.toString().isNotEmpty ?? false)
          ? j['project_id'].toString()
          : null,
    );
  }

  DirectChatThread copyWith({
    String? lastMessagePreview,
    DateTime? updatedAt,
  }) {
    return DirectChatThread(
      id: id,
      peerName: peerName,
      masterId: masterId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      updatedAt: updatedAt ?? this.updatedAt,
      projectTitle: projectTitle,
      projectId: projectId,
    );
  }
}

/// Запись «Мои отклики» у мастера (локальное сохранение).
class MasterMyBidRecord {
  final String id;
  final String projectTitle;
  final String state;
  final String price;

  /// Проект, на который отправлен отклик (для смены статуса при выборе).
  final String? projectId;

  const MasterMyBidRecord({
    required this.id,
    required this.projectTitle,
    required this.state,
    required this.price,
    this.projectId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_title': projectTitle,
        'state': state,
        'price': price,
        'project_id': projectId,
      };

  factory MasterMyBidRecord.fromJson(Map<String, dynamic> j) {
    return MasterMyBidRecord(
      id: j['id']?.toString() ?? '',
      projectTitle: j['project_title']?.toString() ?? '',
      state: j['state']?.toString() ?? '',
      price: j['price']?.toString() ?? '',
      projectId: (j['project_id']?.toString().isNotEmpty ?? false)
          ? j['project_id'].toString()
          : null,
    );
  }

  MasterMyBidRecord copyWith({String? state}) {
    return MasterMyBidRecord(
      id: id,
      projectTitle: projectTitle,
      state: state ?? this.state,
      price: price,
      projectId: projectId,
    );
  }
}

/// Одно сообщение в переписке заказчик ↔ мастер (сохраняется на устройстве).
/// BACKEND: GET/POST `/chats/{threadId}/messages`.
class ChatMessage {
  final String id;
  final String text;

  /// `true` — сообщение текущего пользователя (исходящее).
  final bool mine;
  final DateTime at;

  /// Путь к прикреплённому изображению, если есть.
  final String? imagePath;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.mine,
    required this.at,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'mine': mine,
        'at': at.toIso8601String(),
        'image_path': imagePath,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      id: j['id']?.toString() ?? '',
      text: j['text']?.toString() ?? '',
      mine: j['mine'] as bool? ?? false,
      at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime.now(),
      imagePath: (j['image_path']?.toString().isNotEmpty ?? false)
          ? j['image_path'].toString()
          : null,
    );
  }
}
