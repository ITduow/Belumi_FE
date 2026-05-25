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

class BlogPost {
  BlogPost({
    required this.title,
    required this.content,
    this.coverImageUrl,
    this.author,
  });

  final String title;
  final String content;
  final String? coverImageUrl;
  final String? author;

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    coverImageUrl: json['coverImageUrl'] as String?,
    author: json['author'] as String?,
  );
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
    required this.score,
    this.acneLevel = 'none',
    this.darkSpots = false,
    this.enlargedPores = false,
    this.redness = false,
    this.unevenTone = false,
    this.topConcerns = const [],
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
  final int score;
  final String acneLevel;
  final bool darkSpots;
  final bool enlargedPores;
  final bool redness;
  final bool unevenTone;
  final List<String> topConcerns;
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
      if (unevenTone) 'Uneven tone',
      if (skinCondition.isNotEmpty) 'Condition: $skinCondition',
    ];
    return signals.join('\n');
  }

  factory SkinAnalysisResult.fromApiJson(
    Map<String, dynamic> json, {
    required String skinType,
  }) {
    final topConcerns = _stringList(json['top_concerns']);
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
        'Loi khuyen:\n${advice.map((x) => '- $x').join('\n')}',
      if (warnings.isNotEmpty)
        'Can luu y:\n${warnings.map((x) => '- $x').join('\n')}',
    ].join('\n\n');

    return SkinAnalysisResult(
      skinType: skinType,
      concerns: topConcerns.isEmpty ? '' : topConcerns.join(', '),
      recommendations: recommendations,
      score: (json['overall_score'] as num?)?.round() ?? 0,
      acneLevel: json['acne_level'] as String? ?? 'none',
      darkSpots: json['dark_spots'] as bool? ?? false,
      enlargedPores: json['enlarged_pores'] as bool? ?? false,
      redness: json['redness'] as bool? ?? false,
      unevenTone: json['uneven_tone'] as bool? ?? false,
      topConcerns: topConcerns,
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
      score: json['score'] as int? ?? 0,
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
