import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/belumi_models.dart';

class BelumiRepository {
  BelumiRepository(this.api);

  final ApiClient api;
  AuthUser? currentUser;
  String currentPlan = 'free';
  final Set<String> localWishlistIds = {};

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isPro => currentPlan == 'yearly';

  Future<AuthUser> login(String email, String password) =>
      throw UnsupportedError('Use Firebase AuthService for email login.');

  Future<AuthUser> register(
    String email,
    String password,
    String fullName,
    String phone,
  ) => throw UnsupportedError('Use Firebase AuthService for registration.');

  Future<AuthUser> googleLogin() =>
      throw UnsupportedError('Use Firebase Google login.');

  Future<AuthUser> adminLogin(String email, String password) =>
      throw UnsupportedError('Use Firebase AdminAuthService.');

  void logout() {
    currentUser = null;
    api.token = null;
    currentPlan = 'free';
  }

  void activatePlan(String planCode) {
    currentPlan = planCode;
  }

  Future<void> deleteAccount() async {
    _requireLogin();
    await api.delete('/account');
    logout();
  }

  Future<List<Product>> products() async {
    try {
      final data = await api.get('/products') as List<dynamic>;
      return data
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return sampleProducts;
    }
  }

  Future<List<Product>> recommendProductsBySkin(String skinType) async {
    try {
      final query = _query({'skinType': skinType});
      final data = await api.get('/products/recommend-by-skin$query') as Map<String, dynamic>;
      final suitable = data['suitableProducts'] as List<dynamic>? ?? [];
      return suitable
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<NewsArticle>> news({
    String? category,
    String? search,
    String? sort,
  }) async {
    final query = _query({
      'category': category,
      'search': search,
      'sort': sort,
    });
    final data = await api.get('/news$query') as List<dynamic>;
    return data
        .map((x) => NewsArticle.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<NewsArticle?> newsDetail(String slug) async {
    try {
      final data = await api.get('/news/$slug') as Map<String, dynamic>;
      return NewsArticle.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> newsCategories() async {
    try {
      final data = await api.get('/news/categories') as List<dynamic>;
      return data
          .map((x) {
            if (x is Map<String, dynamic>) {
              return x['name']?.toString() ?? '';
            }
            return x.toString();
          })
          .where((x) => x.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<NewsArticle> likeNews(NewsArticle post) async {
    _requireLogin();
    final data =
        await api.post('/news/${post.id}/toggle-like', {})
            as Map<String, dynamic>;
    final state = NewsLikeState.fromJson(data);
    return post.copyWith(isLiked: state.isLiked, likeCount: state.likeCount);
  }

  Future<NewsArticle> toggleSaveNews(NewsArticle post) async {
    _requireLogin();
    final data =
        await api.post('/news/${post.id}/toggle-save', {})
            as Map<String, dynamic>;
    final state = NewsSaveState.fromJson(data);
    return post.copyWith(isSaved: state.isSaved);
  }

  Future<List<NewsArticle>> savedNews() async {
    _requireLogin();
    final data = await api.get('/news/saved') as List<dynamic>;
    return data
        .map((x) => NewsArticle.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<SkinAnalysisResult> analyzeSkin({
    required String skinType,
    required List<String> concerns,
    required String goal,
    required String planCode,
    String? imageUrl,
  }) async {
    try {
      if (imageUrl == null || imageUrl.isEmpty) {
        throw ArgumentError('Skin analysis requires an image.');
      }

      final normalizedSkinType = _normalizeSkinType(skinType);
      final data =
          await api.postMultipart(
                '/skin/analyze',
                fields: {
                  'skin_type': normalizedSkinType,
                  'image_base64': imageUrl,
                },
              )
              as Map<String, dynamic>;

      final result = data['result'];
      if (data['status'] != 'success' || result is! Map<String, dynamic>) {
        throw Exception(data['message'] as String? ?? 'Skin analysis failed.');
      }

      return SkinAnalysisResult.fromApiJson(
        result,
        skinType: _displaySkinType(normalizedSkinType),
      );
    } catch (_) {
      rethrow;
    }
  }

  String _normalizeSkinType(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('oily') || normalized.contains('dau')) {
      return 'oily';
    }
    if (normalized.contains('dry') || normalized.contains('kho')) {
      return 'dry';
    }
    if (normalized.contains('combination') || normalized.contains('hon hop')) {
      return 'combination';
    }
    if (normalized.contains('sensitive') || normalized.contains('nhay cam')) {
      return 'sensitive';
    }
    if (normalized.contains('normal') || normalized.contains('thuong')) {
      return 'normal';
    }
    return 'normal';
  }

  String _displaySkinType(String value) {
    return switch (value) {
      'oily' => 'Oily',
      'dry' => 'Dry',
      'combination' => 'Combination',
      'sensitive' => 'Sensitive',
      _ => 'Normal',
    };
  }

  Future<IngredientResult> lookupIngredient(String textOrImageUrl) async {
    try {
      final data =
          await api.post('/ingredients/lookup', {
                'textOrImageUrl': textOrImageUrl,
              })
              as Map<String, dynamic>;
      return IngredientResult.fromJson(data);
    } catch (_) {
      return IngredientResult(
        summary:
            'Mock OCR fallback: cong thuc co chat cap am tot, nen patch test neu co huong lieu.',
        safeIngredients: ['Niacinamide', 'Glycerin', 'Hyaluronic Acid'],
        watchlist: textOrImageUrl.toLowerCase().contains('fragrance')
            ? ['Fragrance/parfum']
            : [],
        recommendations: [
          'Dùng kem chống nắng ban ngày.',
          'Không layer quá nhiều active trong cùng routine.',
        ],
      );
    }
  }

  Future<IngredientListResult> searchIngredients({
    String? search,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = _query({
      'search': search,
      'category': category,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
    final data = await api.get('/ingredients$query') as Map<String, dynamic>;
    return IngredientListResult.fromJson(data);
  }

  Future<Ingredient?> ingredientDetail(String id) async {
    if (id.trim().isEmpty) return null;
    final data = await api.get('/ingredients/$id') as Map<String, dynamic>;
    return Ingredient.fromJson(data);
  }

  Future<Ingredient> createIngredient(Ingredient ingredient) async {
    final data =
        await api.post('/ingredients', ingredient.toJson())
            as Map<String, dynamic>;
    return Ingredient.fromJson(data);
  }

  Future<Ingredient> updateIngredient(Ingredient ingredient) async {
    final data =
        await api.put('/ingredients/${ingredient.id}', ingredient.toJson())
            as Map<String, dynamic>;
    return Ingredient.fromJson(data);
  }

  Future<void> deleteIngredient(Ingredient ingredient) async {
    await api.delete('/ingredients/${ingredient.id}');
  }

  Future<IngredientScanResult> scanIngredientLabel(
    String rawTextOrImageUrl, {
    String? skinType,
    List<String> allergies = const [],
  }) async {
    try {
      final data =
          await api.post('/ingredients/scan', {
                'rawTextOrImageUrl': rawTextOrImageUrl,
                'skinType': skinType,
                'allergies': allergies,
              })
              as Map<String, dynamic>;
      return IngredientScanResult.fromJson(data);
    } catch (_) {
      final harmful = rawTextOrImageUrl.toLowerCase().contains('fragrance')
          ? [
              IngredientScanItem(
                name: 'Fragrance',
                category: 'Irritation risk',
                safety: 'warning',
                reason: 'May irritate sensitive skin.',
              ),
            ]
          : <IngredientScanItem>[];
      return IngredientScanResult(
        safetyScore: harmful.isEmpty ? 92 : 74,
        status: harmful.isEmpty ? 'safe' : 'warning',
        summary: harmful.isEmpty
            ? 'Formula looks clean with hydrating ingredients.'
            : 'Formula has useful ingredients but includes possible irritants.',
        beneficial: [
          IngredientScanItem(
            name: 'Niacinamide',
            category: 'Active',
            safety: 'safe',
            reason: 'Supports pores, oil balance and tone.',
          ),
          IngredientScanItem(
            name: 'Glycerin',
            category: 'Humectant',
            safety: 'safe',
            reason: 'Draws water into the skin.',
          ),
        ],
        neutral: [
          IngredientScanItem(
            name: 'Aqua',
            category: 'Solvent',
            safety: 'neutral',
            reason: 'Common base ingredient.',
          ),
        ],
        harmful: harmful,
        recommendations: [
          'Patch test before full-face use.',
          'Use SPF when using actives.',
        ],
      );
    }
  }

  Future<MakeupResult> consultMakeup(
    String skinTone,
    String occasion,
    String style,
  ) async {
    try {
      final data =
          await api.post('/makeup/consultation', {
                'skinTone': skinTone,
                'occasion': occasion,
                'style': style,
              })
              as Map<String, dynamic>;
      return MakeupResult.fromJson(data);
    } catch (_) {
      return MakeupResult(
        lookName: 'Clean Daily Radiance',
        base: 'Neutral cushion, mong nhe',
        eyes: 'Taupe wash va mascara cong mi',
        lips: 'Peach nude tint',
        productSuggestions: [
          'Skin Veil Cushion',
          'Soft Focus Blush',
          'Cloud Tint Lip',
        ],
      );
    }
  }

  Future<MakeupTryOnResult> tryOnMakeup(
    MakeupCatalogItem item,
    String imageUrl,
  ) async {
    try {
      final data =
          await api.post('/makeup/try-on', {
                'imageUrl': imageUrl,
                'productName': item.name,
                'productType': item.productType,
                'shade': item.shade,
                'hexColor': item.hexColor,
              })
              as Map<String, dynamic>;
      return MakeupTryOnResult.fromJson(data);
    } catch (_) {
      return MakeupTryOnResult(
        productName: item.name,
        productType: item.productType,
        shade: item.shade,
        hexColor: item.hexColor,
        matchScore: item.isPro ? 94 : 86,
        previewNote: 'Mock try-on preview. Upload a selfie to enable overlay.',
        applicationTips: [
          'Apply in thin layers.',
          'Check color in natural light.',
        ],
      );
    }
  }

  Future<List<MakeupCatalogItem>> makeupCatalog() async {
    try {
      final data = await api.get('/makeup/catalog') as List<dynamic>;
      return data
          .map((x) => MakeupCatalogItem.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [
        MakeupCatalogItem(
          name: 'Cloud Tint Lip',
          brand: 'Belumi',
          productType: 'Lipstick',
          shade: 'Rose Latte',
          hexColor: '#c86a7a',
          isPro: false,
        ),
        MakeupCatalogItem(
          name: 'Soft Focus Blush',
          brand: 'Belumi',
          productType: 'Blush',
          shade: 'Petal Bloom',
          hexColor: '#e8a1aa',
          isPro: true,
        ),
      ];
    }
  }

  Future<PayOsPaymentLinkResponse> createPayOsLink(
    String planId,
    String cancelUrl,
    String returnUrl,
  ) async {
    final response = await api.post('/payments/payos-link', {
      'planId': planId,
      'cancelUrl': cancelUrl,
      'returnUrl': returnUrl,
    }) as Map<String, dynamic>;
    return PayOsPaymentLinkResponse.fromJson(response);
  }

  Future<String> checkPaymentStatus(int orderCode) async {
    final response = await api.get('/payments/status/$orderCode') as Map<String, dynamic>;
    return response['status'] as String? ?? 'Pending';
  }

  Future<List<Plan>> plans() async {
    try {
      final data = await api.get('/payments/plans') as List<dynamic>;
      return data.map((x) => Plan.fromJson(x as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        Plan(
          id: 'free-plan-id',
          code: 'free',
          name: 'Gói Miễn Phí',
          price: 0,
          billingCycle: 'monthly',
          features: [
            'Kết quả tra cứu thành phần mỹ phẩm và phân tích da bị hạn chế',
            'Giới hạn lượt giải thích với AI về tình trạng da hiện tại',
            'Quy trình chăm sóc da cá nhân hóa theo loại da bị hạn chế',
          ],
        ),
        Plan(
          id: 'monthly-plan-id',
          code: 'monthly',
          name: 'Gói Mỗi Tháng',
          price: 59000,
          billingCycle: 'monthly',
          features: [
            'Kết quả tra cứu thành phần mỹ phẩm và phân tích da đầy đủ',
            'Không giới hạn lượt giải thích với AI về tình trạng da hiện tại và so sánh các mỹ phẩm phù hợp với loại da',
            'Quy trình chăm sóc da cá nhân hóa theo loại da đầy đủ',
          ],
        ),
        Plan(
          id: 'yearly-plan-id',
          code: 'yearly',
          name: 'Gói Mỗi Năm',
          price: 599000,
          billingCycle: 'yearly',
          features: [
            'Chi phí mỗi tháng rẻ hơn',
            'Trải nghiệm miễn phí tính năng mới trang điểm ảo khi được ra mắt chính thức',
            'Kết quả tra cứu thành phần mỹ phẩm và phân tích da đầy đủ',
            'Không giới hạn lượt giải thích với AI về tình trạng da hiện tại và so sánh các mỹ phẩm phù hợp với loại da',
            'Quy trình chăm sóc da cá nhân hóa theo loại da đầy đủ',
          ],
        ),
      ];
    }
  }

  Future<List<Product>> wishlist() async {
    if (!isLoggedIn) {
      final all = await products();
      return all
          .where((product) => localWishlistIds.contains(product.id))
          .toList();
    }

    final data = await api.get('/wishlist') as List<dynamic>;
    return data
        .map(
          (x) =>
              (x as Map<String, dynamic>)['product'] as Map<String, dynamic>?,
        )
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<void> addWishlist(Product product) async {
    if (!isLoggedIn) {
      localWishlistIds.add(product.id);
      return;
    }
    await api.post('/wishlist/${product.id}', {});
  }

  Future<void> removeWishlist(Product product) async {
    if (!isLoggedIn) {
      localWishlistIds.remove(product.id);
      return;
    }
    await api.delete('/wishlist/${product.id}');
  }

  Future<List<Map<String, dynamic>>> adminContacts() async {
    final data = await api.get('/admin/contacts');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> adminDashboard() async {
    final data = await api.get('/admin/dashboard');
    if (data is Map<String, dynamic>) {
      return data;
    }
    return const {};
  }

  Future<Map<String, dynamic>> adminDashboardAnalytics(String period) async {
    final data = await api.get('/admin/dashboard/analytics?period=$period');
    if (data is Map<String, dynamic>) {
      return data;
    }
    return const {};
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final data = await api.get('/admin/users');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> adminPayments() async {
    final data = await api.get('/admin/payments');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> adminAiUsage() async {
    final data = await api.get('/admin/ai-usage');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<NewsArticle>> adminNews({
    String? status,
    String? category,
    String? search,
  }) async {
    final query = _query({
      'status': status,
      'category': category,
      'search': search,
    });
    final data = await api.get('/admin/news$query');
    if (data is List) {
      return data
          .map((x) => NewsArticle.fromJson(x as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> adminNewsStatistics() async {
    return await api.get('/admin/news/statistics') as Map<String, dynamic>;
  }

  Future<NewsArticle> createNews(NewsArticle post) async {
    final payload = post.toJson()..remove('id');
    final data = await api.post('/admin/news', payload) as Map<String, dynamic>;
    return NewsArticle.fromJson(data);
  }

  Future<NewsArticle> updateNews(NewsArticle post) async {
    final data =
        await api.put('/admin/news/${post.id}', post.toJson())
            as Map<String, dynamic>;
    return NewsArticle.fromJson(data);
  }

  Future<void> deleteNews(NewsArticle post) async {
    await api.delete('/admin/news/${post.id}');
  }

  Future<List<Map<String, dynamic>>> adminNewsCategories() async {
    final data = await api.get('/admin/news-categories') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> createNewsCategory(String name, String description) async {
    await api.post('/admin/news-categories', {
      'name': name,
      'slug': '',
      'description': description,
      'isActive': true,
    });
  }

  Future<void> deleteNewsCategory(String id) async {
    await api.delete('/admin/news-categories/$id');
  }

  Future<void> contact(
    String fullName,
    String phone,
    String email,
    String message,
  ) async {
    await api.post('/contact', {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'message': message,
    });
  }

  Future<ChatbotResponse> sendChatbotMessage(
    String message, {
    String? skinType,
  }) async {
    final data =
        await api.post('/chatbot/message', {
              'message': message,
              'skinType': skinType,
            })
            as Map<String, dynamic>;
    return ChatbotResponse.fromJson(data);
  }

  String _query(Map<String, String?> values) {
    final params = <String, String>{};
    values.forEach((key, value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty && trimmed != 'All') {
        params[key] = trimmed;
      }
    });
    if (params.isEmpty) return '';
    return '?${Uri(queryParameters: params).query}';
  }

  void _requireLogin() {
    if (!isLoggedIn) {
      throw const ApiException('Please login to continue.', statusCode: 401);
    }
  }

  // ── Quiz / BeautyProfile ───────────────────────────────────────────────────

  /// Kiểm tra user đã hoàn thành onboarding quiz chưa.
  /// Returns true nếu quiz đã hoàn thành.
  Future<bool> getQuizStatus() async {
    try {
      _requireLogin();
      final data =
          await api.get('/profile/quiz/status') as Map<String, dynamic>;
      return data['quiz_completed'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Lấy dữ liệu BeautyProfile của user đã lưu.
  /// Returns null nếu chưa có hoặc lỗi.
  Future<BeautyProfile?> getBeautyProfile() async {
    try {
      _requireLogin();
      final data =
          await api.get('/profile/quiz') as Map<String, dynamic>;
      return BeautyProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Submit onboarding quiz lần đầu (POST).
  /// Ném exception nếu quiz đã tồn tại (dùng [updateQuiz] để cập nhật).
  Future<BeautyProfile> submitQuiz(QuizSubmitRequest request) async {
    _requireLogin();
    final data =
        await api.post('/profile/quiz', request.toJson())
            as Map<String, dynamic>;
    return BeautyProfile.fromJson(data);
  }

  /// Cập nhật quiz đã làm (PUT).
  Future<BeautyProfile> updateQuiz(QuizSubmitRequest request) async {
    _requireLogin();
    final data =
        await api.put('/profile/quiz', request.toJson())
            as Map<String, dynamic>;
    return BeautyProfile.fromJson(data);
  }

  // ── Skin Analysis History ──────────────────────────────────────────────────

  /// Lấy danh sách lịch sử phân tích da của user (GET /api/skin/history/me)
  /// BE trả về dạng danh sách. Chúng ta bỏ '/api' prefix vì baseUrl đã có sẵn.
  Future<List<Map<String, dynamic>>> getSkinHistory({int page = 1, int pageSize = 20}) async {
    try {
      _requireLogin();
      final query = '?page=$page&pageSize=$pageSize';
      final data = await api.get('/skin/history/me$query');
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy thông tin chi tiết một lượt phân tích da (GET /api/skin/history/me/{id})
  Future<SkinAnalysisResult?> getSkinHistoryDetail(String id) async {
    try {
      _requireLogin();
      final data = await api.get('/skin/history/me/$id') as Map<String, dynamic>;
      
      final aiResultStr = data['aiResult'] ?? data['AiResult'] ?? data['ai_result'];
      if (aiResultStr != null && aiResultStr.toString().isNotEmpty) {
        final Map<String, dynamic> aiJson = jsonDecode(aiResultStr.toString()) as Map<String, dynamic>;
        final skinType = data['skinType'] ?? data['skin_type'] ?? data['SkinType'] ?? 'Normal';
        return SkinAnalysisResult.fromApiJson(aiJson, skinType: skinType.toString());
      }
      
      // Fallback in case the structure is different
      return SkinAnalysisResult.fromApiJson(data, skinType: data['skin_type'] as String? ?? 'Normal');
    } catch (_) {
      return null;
    }
  }
}


final sampleProducts = [
  Product(
    id: '1',
    name: 'Belumi Glow Serum',
    description: 'Serum vitamin mỏng nhẹ giúp da sáng và ẩm mượt.',
    price: 420000,
    categoryName: 'Skincare',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be',
  ),
  Product(
    id: '2',
    name: 'Belumi Barrier Cream',
    description: 'Kem dưỡng phục hồi hàng rào bảo vệ da.',
    price: 360000,
    categoryName: 'Skincare',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1617897903246-719242758050',
  ),
];
