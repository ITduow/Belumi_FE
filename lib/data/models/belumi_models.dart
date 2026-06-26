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
    this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.features,
    this.billingCycle,
  });

  final String? id;
  final String code;
  final String name;
  final num price;
  final List<String> features;
  final String? billingCycle;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as String?,
    code: json['code'] as String? ?? 'free',
    name: json['name'] as String? ?? 'Free',
    price: json['price'] as num? ?? 0,
    features: List<String>.from(json['features'] as List<dynamic>? ?? const []),
    billingCycle: json['billingCycle'] as String?,
  );
}

class PayOsPaymentLinkResponse {
  PayOsPaymentLinkResponse({
    required this.checkoutUrl,
    required this.orderCode,
    required this.amount,
  });

  final String checkoutUrl;
  final int orderCode;
  final num amount;

  factory PayOsPaymentLinkResponse.fromJson(Map<String, dynamic> json) => PayOsPaymentLinkResponse(
    checkoutUrl: json['checkoutUrl'] as String? ?? '',
    orderCode: json['orderCode'] as int? ?? 0,
    amount: json['amount'] as num? ?? 0,
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
    // Level strings: "low" | "medium" | "high"
    this.pigmentationLevel = 'low',
    this.poreVisibilityLevel = 'low',
    this.visibleRednessLevel = 'low',
    this.oilinessLevel = 'low',
    this.oilinessZones = const [],
    this.skinToneEvennessLevel = 'low',
    this.visibleWrinkleLevel = 'low',
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

  /// Pigmentation/dark spots level: "low" | "medium" | "high"
  final String pigmentationLevel;

  /// Pore visibility level: "low" | "medium" | "high"
  final String poreVisibilityLevel;

  /// Visible redness level: "low" | "medium" | "high"
  final String visibleRednessLevel;

  /// Oiliness/shine level: "low" | "medium" | "high"
  final String oilinessLevel;

  /// Facial zones with visible oiliness: ["forehead", "nose", "chin", "cheeks"]
  final List<String> oilinessZones;

  /// Skin tone evenness: "low" = even, "high" = very uneven
  final String skinToneEvennessLevel;

  /// Visible wrinkle/fine line level: "low" | "medium" | "high"
  final String visibleWrinkleLevel;

  final double confidence;
  final String skinCondition;
  final String description;
  final List<String> advice;
  final List<String> warnings;
  final List<IngredientRecommendation> recommendedIngredients;
  final List<IngredientRecommendation> avoidOrProfessionalOnly;

  /// Convenience helpers for UI (replaces old bool fields)
  bool get hasPigmentation => pigmentationLevel == 'medium' || pigmentationLevel == 'high';
  bool get hasEnlargedPores => poreVisibilityLevel == 'medium' || poreVisibilityLevel == 'high';
  bool get hasRedness => visibleRednessLevel == 'medium' || visibleRednessLevel == 'high';
  bool get hasOiliness => oilinessLevel == 'medium' || oilinessLevel == 'high';
  bool get hasWrinkles => visibleWrinkleLevel == 'medium' || visibleWrinkleLevel == 'high';

  String get signalSummary {
    final signals = <String>[
      'Acne: $acneLevel',
      if (hasPigmentation) 'Thâm/sắc tố ($pigmentationLevel)',
      if (hasEnlargedPores) 'Lỗ chân lông to ($poreVisibilityLevel)',
      if (hasRedness) 'Đỏ da ($visibleRednessLevel)',
      if (hasOiliness) 'Dầu bóng ($oilinessLevel)',
      if (hasWrinkles) 'Nếp nhăn ($visibleWrinkleLevel)',
      if (acneTypes.isNotEmpty) 'Loại mụn: ${acneTypes.join(', ')}',
      if (skinCondition.isNotEmpty) 'Tình trạng: $skinCondition',
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

    final pigmentationLevel = json['pigmentation_level'] as String? ?? 'low';
    final poreVisibilityLevel = json['pore_visibility_level'] as String? ?? 'low';
    final visibleRednessLevel = json['visible_redness_level'] as String? ?? 'low';

    final concernsList = [
      if ((json['acne_level'] as String? ?? 'none').toLowerCase().trim() != 'none') 'acne',
      if (pigmentationLevel == 'medium' || pigmentationLevel == 'high') 'pigmentation',
      if (poreVisibilityLevel == 'medium' || poreVisibilityLevel == 'high') 'enlarged_pores',
      if (visibleRednessLevel == 'medium' || visibleRednessLevel == 'high') 'redness',
    ];

    final recommendations = [
      if (description.isNotEmpty) description,
      if (advice.isNotEmpty)
        'Lời khuyên:\n${advice.map((x) => '- $x').join('\n')}',
      if (warnings.isNotEmpty)
        'Cần lưu ý:\n${warnings.map((x) => '- $x').join('\n')}',
    ].join('\n\n');

    return SkinAnalysisResult(
      skinType: skinType,
      concerns: concernsList.join(', '),
      recommendations: recommendations,
      acneLevel: json['acne_level'] as String? ?? 'none',
      acneTypes: acneTypes,
      pigmentationLevel: pigmentationLevel,
      poreVisibilityLevel: poreVisibilityLevel,
      visibleRednessLevel: visibleRednessLevel,
      oilinessLevel: json['oiliness_level'] as String? ?? 'low',
      oilinessZones: _stringList(json['oiliness_zones']),
      skinToneEvennessLevel: json['skin_tone_evenness_level'] as String? ?? 'low',
      visibleWrinkleLevel: json['visible_wrinkle_level'] as String? ?? 'low',
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

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING QUIZ — BeautyProfile & QuizSubmitRequest
// ─────────────────────────────────────────────────────────────────────────────

/// Kết quả onboarding quiz lưu trên server (GET /api/profile/quiz)
class BeautyProfile {
  const BeautyProfile({
    this.nickname,
    this.gender,
    this.ageGroup,
    this.skinType,
    this.skinGoals = const [],
    this.skinSensitivity,
    this.avoidedIngredients = const [],
    this.budgetRange,
    this.currentProducts,
    this.quizCompletedAt,
  });

  /// Q1 — biệt danh
  final String? nickname;

  /// Q2 — "female" | "male" | "other"
  final String? gender;

  /// Q3 — "under18" | "18-22" | "23-26" | "over27"
  final String? ageGroup;

  /// Q4 — "normal" | "dry" | "combination" | "oily"
  final String? skinType;

  /// Q5 — max 3: "hydration" | "brightening" | "pore_control" | "dark_spot" | "anti_aging" | "soothing"
  final List<String> skinGoals;

  /// Q6 — "stable" | "mild" | "sensitive"
  final String? skinSensitivity;

  /// Q7 — max 3: "fragrance" | "alcohol" | "paraben" | "mineral_oil" | "retinol" | "none" | custom
  final List<String> avoidedIngredients;

  /// Q8 — "under200k" | "200-300k" | "300-500k" | "500k-1m" | "over1m"
  final String? budgetRange;

  /// Q9 — free text, tên mỹ phẩm đang dùng
  final String? currentProducts;

  final DateTime? quizCompletedAt;

  bool get quizCompleted => quizCompletedAt != null;

  factory BeautyProfile.fromJson(Map<String, dynamic> json) => BeautyProfile(
    nickname: json['nickname'] as String?,
    gender: json['gender'] as String?,
    ageGroup: json['age_group'] as String?,
    skinType: json['skin_type'] as String?,
    skinGoals: List<String>.from(json['skin_goals'] as List<dynamic>? ?? const []),
    skinSensitivity: json['skin_sensitivity'] as String?,
    avoidedIngredients: List<String>.from(
      json['avoided_ingredients'] as List<dynamic>? ?? const [],
    ),
    budgetRange: json['budget_range'] as String?,
    currentProducts: json['current_products'] as String?,
    quizCompletedAt: json['quiz_completed_at'] != null
        ? DateTime.tryParse(json['quiz_completed_at'] as String)
        : null,
  );
}

/// Request body cho POST/PUT /api/profile/quiz
class QuizSubmitRequest {
  const QuizSubmitRequest({
    this.nickname,
    this.gender,
    this.ageGroup,
    this.skinType,
    this.skinGoals = const [],
    this.skinSensitivity,
    this.avoidedIngredients = const [],
    this.budgetRange,
    this.currentProducts,
  });

  final String? nickname;
  final String? gender;
  final String? ageGroup;
  final String? skinType;
  final List<String> skinGoals;
  final String? skinSensitivity;
  final List<String> avoidedIngredients;
  final String? budgetRange;
  final String? currentProducts;

  Map<String, dynamic> toJson() => {
    if (nickname != null) 'nickname': nickname,
    if (gender != null) 'gender': gender,
    if (ageGroup != null) 'age_group': ageGroup,
    if (skinType != null) 'skin_type': skinType,
    if (skinGoals.isNotEmpty) 'skin_goals': skinGoals,
    if (skinSensitivity != null) 'skin_sensitivity': skinSensitivity,
    if (avoidedIngredients.isNotEmpty) 'avoided_ingredients': avoidedIngredients,
    if (budgetRange != null) 'budget_range': budgetRange,
    if (currentProducts != null) 'current_products': currentProducts,
  };
}
