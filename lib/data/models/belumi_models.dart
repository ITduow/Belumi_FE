class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.thumbnailUrl,
    this.categoryName,
  });

  final String id;
  final String name;
  final String description;
  final num price;
  final String? thumbnailUrl;
  final String? categoryName;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: json['price'] as num? ?? 0,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    categoryName: json['categoryName'] as String?,
  );
}

class AuthUser {
  AuthUser({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
    this.phone,
  });

  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String token;
  final String? phone;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['userId'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String? ?? 'Belumi User',
    role: _parseRole(json['role']),
    token: json['token'] as String,
    phone: json['phone'] as String?,
  );

  static String _parseRole(Object? value) {
    if (value is String) return value;
    if (value is num) return value == 1 ? 'Admin' : 'Customer';
    return 'Customer';
  }
}

class Plan {
  Plan({
    required this.code,
    required this.name,
    required this.price,
    required this.features,
  });

  final String code;
  final String name;
  final num price;
  final List<String> features;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    code: json['code'] as String? ?? 'free',
    name: json['name'] as String? ?? 'Free',
    price: json['price'] as num? ?? 0,
    features: List<String>.from(json['features'] as List<dynamic>? ?? const []),
  );
}

class NewsArticle {
  NewsArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.content,
    this.category = 'Skincare',
    this.coverImageUrl,
    this.author,
    this.tags = const [],
    this.status = 'Published',
    this.viewCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.publishedAt,
    this.isActive = true,
  });

  final String id;
  final String slug;
  final String title;
  final String summary;
  final String content;
  final String category;
  final String? coverImageUrl;
  final String? author;
  final List<String> tags;
  final String status;
  final int viewCount;
  final int likeCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime? publishedAt;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'summary': summary,
    'content': content,
    'coverImageUrl': coverImageUrl,
    'category': category,
    'tags': tags.join(', '),
    'author': author ?? 'Belumi Team',
    'status': _statusToWire(status),
    'viewCount': viewCount,
    'likeCount': likeCount,
    'isLiked': isLiked,
    'isSaved': isSaved,
    'publishedAt': (publishedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'isActive': isActive,
  };

  NewsArticle copyWith({
    String? title,
    String? slug,
    String? summary,
    String? content,
    String? category,
    String? coverImageUrl,
    String? author,
    List<String>? tags,
    String? status,
    int? viewCount,
    int? likeCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? publishedAt,
    bool? isActive,
  }) => NewsArticle(
    id: id,
    slug: slug ?? this.slug,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    content: content ?? this.content,
    category: category ?? this.category,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    author: author ?? this.author,
    tags: tags ?? this.tags,
    status: status ?? this.status,
    viewCount: viewCount ?? this.viewCount,
    likeCount: likeCount ?? this.likeCount,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    publishedAt: publishedAt ?? this.publishedAt,
    isActive: isActive ?? this.isActive,
  );

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Bài viết Belumi';
    final slug = json['slug'] as String? ?? _slugify(title);
    final content = json['content'] as String? ?? '';
    final summary = json['summary'] as String? ?? content;
    return NewsArticle(
      id: json['id'] as String? ?? slug,
      slug: slug,
      title: title,
      summary: summary,
      content: content,
      category: json['category'] as String? ?? 'Skincare',
      coverImageUrl:
          json['coverImageUrl'] as String? ?? json['thumbnailUrl'] as String?,
      author: json['author'] as String?,
      tags: _parseTags(json['tags']),
      status: _parseStatus(json['status']),
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      publishedAt: _parseDate(json['publishedAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static List<String> _parseTags(Object? value) {
    if (value is List) {
      return value
          .map((x) => x.toString().trim())
          .where((x) => x.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _parseStatus(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is num) {
      return switch (value.toInt()) {
        0 => 'Draft',
        2 => 'Hidden',
        _ => 'Published',
      };
    }
    return 'Published';
  }

  static int _statusToWire(String value) {
    return switch (value.toLowerCase()) {
      'draft' => 0,
      'hidden' => 2,
      _ => 1,
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _slugify(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');
}

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final num price;
  final int durationMinutes;
  final String? imageUrl;

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: json['price'] as num? ?? 0,
    durationMinutes: json['durationMinutes'] as int? ?? 0,
    imageUrl: json['imageUrl'] as String?,
  );
}

class SkinAnalysisResult {
  SkinAnalysisResult({
    required this.skinType,
    required this.concerns,
    required this.recommendations,
    this.acneLevel = 'none',
    this.acneTypes = const [],
    this.darkSpots = false,
    this.enlargedPores = false,
    this.redness = false,
    this.confidence = 0,
    this.skinCondition = '',
    this.description = '',
    this.advice = const [],
    this.warnings = const [],
    this.recommendedIngredients = const [],
    this.avoidOrProfessionalOnly = const [],
  });

  final String skinType;
  final String concerns;
  final String recommendations;
  final String acneLevel;
  final List<String> acneTypes;
  final bool darkSpots;
  final bool enlargedPores;
  final bool redness;
  final double confidence;
  final String skinCondition;
  final String description;
  final List<String> advice;
  final List<String> warnings;
  final List<IngredientRecommendation> recommendedIngredients;
  final List<IngredientRecommendation> avoidOrProfessionalOnly;

  String get signalSummary {
    final signals = <String>[
      'Acne: $acneLevel',
      if (darkSpots) 'Dark spots',
      if (enlargedPores) 'Enlarged pores',
      if (redness) 'Redness',
      if (acneTypes.isNotEmpty) 'Acne types: ${acneTypes.join(', ')}',
      if (skinCondition.isNotEmpty) 'Condition: $skinCondition',
    ];
    return signals.join('\n');
  }

  factory SkinAnalysisResult.fromApiJson(
    Map<String, dynamic> json, {
    required String skinType,
  }) {
    final acneTypes = _stringList(json['acne_types']);
    final advice = _stringList(json['advice']);
    final warnings = _stringList(json['warnings']);
    final recommendedIngredients = _ingredientRecommendations(
      json['recommended_ingredients'],
    );
    final avoidOrProfessionalOnly = _ingredientRecommendations(
      json['avoid_or_professional_only'],
    );
    final description = json['description'] as String? ?? '';
    final recommendations = [
      if (description.isNotEmpty) description,
      if (advice.isNotEmpty)
        'Lời khuyên:\n${advice.map((x) => '- $x').join('\n')}',
      if (warnings.isNotEmpty)
        'Cần lưu ý:\n${warnings.map((x) => '- $x').join('\n')}',
    ].join('\n\n');

    return SkinAnalysisResult(
      skinType: skinType,
      concerns: _concernsFromSignals(
        acneLevel: json['acne_level'] as String? ?? 'none',
        darkSpots: json['dark_spots'] as bool? ?? false,
        enlargedPores: json['enlarged_pores'] as bool? ?? false,
        redness: json['redness'] as bool? ?? false,
      ).join(', '),
      recommendations: recommendations,
      acneLevel: json['acne_level'] as String? ?? 'none',
      acneTypes: acneTypes,
      darkSpots: json['dark_spots'] as bool? ?? false,
      enlargedPores: json['enlarged_pores'] as bool? ?? false,
      redness: json['redness'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      skinCondition: json['skin_condition'] as String? ?? '',
      description: description,
      advice: advice,
      warnings: warnings,
      recommendedIngredients: recommendedIngredients,
      avoidOrProfessionalOnly: avoidOrProfessionalOnly,
    );
  }

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) {
    final apiResult = json['result'];
    if (apiResult is Map<String, dynamic>) {
      return SkinAnalysisResult.fromApiJson(
        apiResult,
        skinType: json['skinType'] as String? ?? 'Combination',
      );
    }

    return SkinAnalysisResult(
      skinType: json['skinType'] as String? ?? 'Combination',
      concerns: json['concerns'] as String? ?? '',
      recommendations: json['recommendations'] as String? ?? '',
    );
  }

  static List<String> _stringList(Object? value) =>
      (value as List<dynamic>? ?? const [])
          .map((x) => x.toString())
          .where((x) => x.trim().isNotEmpty)
          .toList();

  static List<String> _concernsFromSignals({
    required String acneLevel,
    required bool darkSpots,
    required bool enlargedPores,
    required bool redness,
  }) {
    return [
      if (acneLevel.toLowerCase().trim() != 'none') 'acne',
      if (darkSpots) 'dark_spots',
      if (enlargedPores) 'enlarged_pores',
      if (redness) 'redness',
    ];
  }

  static List<IngredientRecommendation> _ingredientRecommendations(
    Object? value,
  ) => (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(IngredientRecommendation.fromJson)
      .toList();
}

class IngredientRecommendation {
  const IngredientRecommendation({
    required this.name,
    required this.reason,
    required this.sourceIds,
  });

  final String name;
  final String reason;
  final List<String> sourceIds;

  factory IngredientRecommendation.fromJson(Map<String, dynamic> json) =>
      IngredientRecommendation(
        name: json['name'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        sourceIds: List<String>.from(
          json['source_ids'] as List<dynamic>? ?? const [],
        ),
      );
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.nameInc,
    required this.name,
    required this.category,
    required this.description,
    required this.links,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nameInc;
  final String name;
  final String category;
  final String description;
  final String links;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get linkList => links
      .split('|')
      .map((link) => link.trim())
      .where((link) => link.isNotEmpty)
      .toList();

  Map<String, dynamic> toJson() => {
    'nameInc': nameInc,
    'name': name,
    'category': category,
    'description': description,
    'links': links,
  };

  Ingredient copyWith({
    String? id,
    String? nameInc,
    String? name,
    String? category,
    String? description,
    String? links,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Ingredient(
    id: id ?? this.id,
    nameInc: nameInc ?? this.nameInc,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    links: links ?? this.links,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: json['id'] as String? ?? '',
    nameInc: json['nameInc'] as String? ?? '',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    links: json['links'] as String? ?? '',
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class IngredientListResult {
  const IngredientListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<Ingredient> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;

  factory IngredientListResult.fromJson(Map<String, dynamic> json) =>
      IngredientListResult(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Ingredient.fromJson)
            .toList(),
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 20,
      );
}

class IngredientResult {
  IngredientResult({
    required this.summary,
    required this.safeIngredients,
    required this.watchlist,
    required this.recommendations,
  });

  final String summary;
  final List<String> safeIngredients;
  final List<String> watchlist;
  final List<String> recommendations;

  factory IngredientResult.fromJson(Map<String, dynamic> json) =>
      IngredientResult(
        summary: json['summary'] as String? ?? '',
        safeIngredients: List<String>.from(
          json['safeIngredients'] as List<dynamic>? ?? const [],
        ),
        watchlist: List<String>.from(
          json['watchlist'] as List<dynamic>? ?? const [],
        ),
        recommendations: List<String>.from(
          json['recommendations'] as List<dynamic>? ?? const [],
        ),
      );
}

class IngredientScanItem {
  IngredientScanItem({
    required this.name,
    required this.category,
    required this.safety,
    required this.reason,
  });

  final String name;
  final String category;
  final String safety;
  final String reason;

  factory IngredientScanItem.fromJson(Map<String, dynamic> json) =>
      IngredientScanItem(
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        safety: json['safety'] as String? ?? 'neutral',
        reason: json['reason'] as String? ?? '',
      );
}

class IngredientScanResult {
  IngredientScanResult({
    required this.safetyScore,
    required this.status,
    required this.summary,
    required this.beneficial,
    required this.neutral,
    required this.harmful,
    required this.recommendations,
  });

  final int safetyScore;
  final String status;
  final String summary;
  final List<IngredientScanItem> beneficial;
  final List<IngredientScanItem> neutral;
  final List<IngredientScanItem> harmful;
  final List<String> recommendations;

  factory IngredientScanResult.fromJson(Map<String, dynamic> json) {
    List<IngredientScanItem> items(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((x) => IngredientScanItem.fromJson(x as Map<String, dynamic>))
            .toList();

    return IngredientScanResult(
      safetyScore: json['safetyScore'] as int? ?? 80,
      status: json['status'] as String? ?? 'safe',
      summary: json['summary'] as String? ?? '',
      beneficial: items('beneficial'),
      neutral: items('neutral'),
      harmful: items('harmful'),
      recommendations: List<String>.from(
        json['recommendations'] as List<dynamic>? ?? const [],
      ),
    );
  }
}

class MakeupResult {
  MakeupResult({
    required this.lookName,
    required this.base,
    required this.eyes,
    required this.lips,
    required this.productSuggestions,
  });

  final String lookName;
  final String base;
  final String eyes;
  final String lips;
  final List<String> productSuggestions;

  factory MakeupResult.fromJson(Map<String, dynamic> json) => MakeupResult(
    lookName: json['lookName'] as String? ?? '',
    base: json['base'] as String? ?? '',
    eyes: json['eyes'] as String? ?? '',
    lips: json['lips'] as String? ?? '',
    productSuggestions: List<String>.from(
      json['productSuggestions'] as List<dynamic>? ?? const [],
    ),
  );
}

class MakeupTryOnResult {
  MakeupTryOnResult({
    required this.productName,
    required this.productType,
    required this.shade,
    required this.hexColor,
    required this.matchScore,
    required this.previewNote,
    required this.applicationTips,
  });

  final String productName;
  final String productType;
  final String shade;
  final String hexColor;
  final int matchScore;
  final String previewNote;
  final List<String> applicationTips;

  factory MakeupTryOnResult.fromJson(Map<String, dynamic> json) =>
      MakeupTryOnResult(
        productName: json['productName'] as String? ?? '',
        productType: json['productType'] as String? ?? '',
        shade: json['shade'] as String? ?? '',
        hexColor: json['hexColor'] as String? ?? '#5ba4d2',
        matchScore: json['matchScore'] as int? ?? 88,
        previewNote: json['previewNote'] as String? ?? '',
        applicationTips: List<String>.from(
          json['applicationTips'] as List<dynamic>? ?? const [],
        ),
      );
}

class MakeupCatalogItem {
  MakeupCatalogItem({
    required this.name,
    required this.brand,
    required this.productType,
    required this.shade,
    required this.hexColor,
    required this.isPro,
  });

  final String name;
  final String brand;
  final String productType;
  final String shade;
  final String hexColor;
  final bool isPro;

  factory MakeupCatalogItem.fromJson(Map<String, dynamic> json) =>
      MakeupCatalogItem(
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? 'Belumi',
        productType: json['productType'] as String? ?? '',
        shade: json['shade'] as String? ?? '',
        hexColor: json['hexColor'] as String? ?? '#5ba4d2',
        isPro: json['isPro'] as bool? ?? false,
      );
}

class PaymentQr {
  PaymentQr({
    required this.planCode,
    required this.amount,
    required this.vietQrUrl,
  });

  final String planCode;
  final num amount;
  final String vietQrUrl;

  factory PaymentQr.fromJson(Map<String, dynamic> json) => PaymentQr(
    planCode: json['planCode'] as String? ?? 'plus',
    amount: json['amount'] as num? ?? 99000,
    vietQrUrl: json['vietQrUrl'] as String? ?? '',
  );
}

class NewsLikeState {
  const NewsLikeState({
    required this.newsId,
    required this.isLiked,
    required this.likeCount,
  });

  final String newsId;
  final bool isLiked;
  final int likeCount;

  factory NewsLikeState.fromJson(Map<String, dynamic> json) => NewsLikeState(
    newsId: json['newsId'] as String? ?? '',
    isLiked: json['isLiked'] as bool? ?? false,
    likeCount: json['likeCount'] as int? ?? 0,
  );
}

class NewsSaveState {
  const NewsSaveState({required this.newsId, required this.isSaved});

  final String newsId;
  final bool isSaved;

  factory NewsSaveState.fromJson(Map<String, dynamic> json) => NewsSaveState(
    newsId: json['newsId'] as String? ?? '',
    isSaved: json['isSaved'] as bool? ?? false,
  );
}

class ChatbotSource {
  const ChatbotSource({required this.type, required this.label, this.url});

  final String type;
  final String label;
  final String? url;

  factory ChatbotSource.fromJson(Map<String, dynamic> json) => ChatbotSource(
    type: json['type'] as String? ?? '',
    label: json['label'] as String? ?? '',
    url: json['url'] as String?,
  );
}

class ChatbotResponse {
  const ChatbotResponse({
    required this.answer,
    required this.tools,
    required this.sources,
  });

  final String answer;
  final List<String> tools;
  final List<ChatbotSource> sources;

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) =>
      ChatbotResponse(
        answer: json['answer'] as String? ?? '',
        tools: List<String>.from(json['tools'] as List<dynamic>? ?? const []),
        sources: (json['sources'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ChatbotSource.fromJson)
            .toList(),
      );
}
