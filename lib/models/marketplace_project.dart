/// Сводка проекта заказчика.
class ProjectSummary {
  final String id;
  final String title;
  final String status;
  final DateTime updatedAt;
  final int responsesCount;
  /// Карта квартиры: {before: {...}, after: {...}} или пусто
  final Map<String, dynamic> mapData;

  const ProjectSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.responsesCount = 0,
    this.mapData = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'updated_at': updatedAt.toIso8601String(),
        'responses_count': responsesCount,
        'map_data': mapData,
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
  });

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

  const DirectChatThread({
    required this.id,
    required this.peerName,
    this.masterId,
    required this.lastMessagePreview,
    required this.updatedAt,
    required this.projectTitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'peer_name': peerName,
        'master_id': masterId,
        'last_message_preview': lastMessagePreview,
        'updated_at': updatedAt.toIso8601String(),
        'project_title': projectTitle,
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
    );
  }
}

/// Запись «Мои отклики» у мастера (локальное сохранение).
class MasterMyBidRecord {
  final String id;
  final String projectTitle;
  final String state;
  final String price;

  const MasterMyBidRecord({
    required this.id,
    required this.projectTitle,
    required this.state,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_title': projectTitle,
        'state': state,
        'price': price,
      };

  factory MasterMyBidRecord.fromJson(Map<String, dynamic> j) {
    return MasterMyBidRecord(
      id: j['id']?.toString() ?? '',
      projectTitle: j['project_title']?.toString() ?? '',
      state: j['state']?.toString() ?? '',
      price: j['price']?.toString() ?? '',
    );
  }
}
