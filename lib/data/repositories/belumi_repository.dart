import '../../core/network/api_client.dart';
import '../models/belumi_models.dart';

class BelumiRepository {
  BelumiRepository(this.api);

  final ApiClient api;
  AuthUser? currentUser;
  String currentPlan = 'free';
  final Set<String> localWishlistIds = {};

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isPro => currentPlan == 'pro';

  Future<AuthUser> login(String email, String password) async {
    final data =
        await api.post('/auth/login', {'email': email, 'password': password})
            as Map<String, dynamic>;
    return _setUser(AuthUser.fromJson(data));
  }

  Future<AuthUser> register(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    final data =
        await api.post('/auth/register', {
              'email': email,
              'password': password,
              'fullName': fullName,
              'phone': phone,
            })
            as Map<String, dynamic>;
    return _setUser(AuthUser.fromJson(data));
  }

  Future<AuthUser> googleMockLogin() async {
    final data =
        await api.post('/auth/google-mock', {
              'email': 'customer@belumi.com',
              'password': 'GoogleMock@2026',
              'fullName': 'Belumi Customer',
              'phone': '0909000000',
            })
            as Map<String, dynamic>;
    return _setUser(AuthUser.fromJson(data));
  }

  Future<AuthUser> adminLogin(String email, String password) async {
    final data =
        await api.post('/auth/admin-login', {
              'email': email,
              'password': password,
            })
            as Map<String, dynamic>;
    return _setUser(AuthUser.fromJson(data));
  }

  void logout() {
    currentUser = null;
    api.token = null;
    currentPlan = 'free';
  }

  void activatePlan(String planCode) {
    currentPlan = planCode;
  }

  AuthUser _setUser(AuthUser user) {
    currentUser = user;
    api.token = user.token;
    return user;
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

  Future<List<BlogPost>> blogs() async {
    try {
      final data = await api.get('/blogs') as List<dynamic>;
      return data
          .map((x) => BlogPost.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return sampleBlogs;
    }
  }

  Future<SkinAnalysisResult> analyzeSkin({
    required String skinType,
    required List<String> concerns,
    required String goal,
    required String planCode,
    String? imageUrl,
  }) async {
    try {
      final data =
          await api.post('/skin-analysis', {
                'imageUrl': imageUrl,
                'skinType': skinType,
                'concerns': concerns,
                'goal': goal,
                'planCode': planCode,
              })
              as Map<String, dynamic>;
      return SkinAnalysisResult.fromJson(data);
    } catch (_) {
      final concernText = concerns.isEmpty
          ? 'Routine consistency'
          : concerns.join(', ');
      return SkinAnalysisResult(
        skinType: skinType,
        concerns: concernText,
        recommendations:
            'Analysis: $skinType skin with $concernText. Goal: $goal. Mock Gemini fallback is active.\n\nMorning routine: Gentle cleanser -> hydrating toner -> niacinamide -> moisturizer -> SPF 50.\n\nEvening routine: Cleanser -> targeted serum -> barrier cream.\n\nIngredients to use: Niacinamide, Hyaluronic Acid, Ceramide, Panthenol.\n\nIngredients to avoid: Harsh scrubs, over-layering acids, unprotected daytime retinoids.\n\nProduct suggestions: Belumi Glow Serum, Belumi Barrier Cream, Belumi Daily SPF 50.',
        score: planCode == 'pro' ? 90 : 82,
      );
    }
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
          'Dung kem chong nang ban ngay.',
          'Khong layer qua nhieu active trong cung routine.',
        ],
      );
    }
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

  Future<PaymentQr> createPaymentQr(String planCode, String email) async {
    try {
      final data =
          await api.post('/payments/vietqr', {
                'planCode': planCode,
                'customerEmail': email,
              })
              as Map<String, dynamic>;
      return PaymentQr.fromJson(data);
    } catch (_) {
      final amount = planCode == 'pro' ? 199000 : 99000;
      return PaymentQr(
        planCode: planCode,
        amount: amount,
        vietQrUrl:
            'https://img.vietqr.io/image/BIDV-1234567890-compact2.png?amount=$amount&addInfo=BELUMI%20${planCode.toUpperCase()}',
      );
    }
  }

  Future<List<Plan>> plans() async {
    try {
      final data = await api.get('/payments/plans') as List<dynamic>;
      return data.map((x) => Plan.fromJson(x as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        Plan(
          code: 'free',
          name: 'Free',
          price: 0,
          features: ['Skin AI mock', 'News', 'Wishlist basic'],
        ),
        Plan(
          code: 'plus',
          name: 'Plus',
          price: 99000,
          features: ['Ingredient OCR lookup', 'More AI scans', 'Wishlist sync'],
        ),
        Plan(
          code: 'pro',
          name: 'Pro',
          price: 199000,
          features: [
            'Virtual makeup',
            'Advanced AI consultation',
            'Priority recommendations',
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
    final data = await api.get('/admin/contacts') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> adminDashboard() async {
    final data = await api.get('/admin/dashboard') as Map<String, dynamic>;
    return data;
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final data = await api.get('/admin/users') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> adminAiUsage() async {
    final data = await api.get('/admin/ai-usage') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
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
}

final sampleProducts = [
  Product(
    id: '1',
    name: 'Belumi Glow Serum',
    description: 'Serum vitamin mong nhe giup da sang va am muot.',
    price: 420000,
    categoryName: 'Skincare',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be',
  ),
  Product(
    id: '2',
    name: 'Belumi Barrier Cream',
    description: 'Kem duong phuc hoi hang rao bao ve da.',
    price: 360000,
    categoryName: 'Skincare',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1617897903246-719242758050',
  ),
];

final sampleBlogs = [
  BlogPost(
    title: 'Routine buoi sang nhe ma hieu qua',
    content: 'Lam sach nhe, cap am tot, chong nang deu va dung active vua du.',
    author: 'Belumi Team',
    coverImageUrl:
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
  ),
  BlogPost(
    title: 'Niacinamide hop voi ai?',
    content:
        'Ho tro dau thua, sac to va hang rao bao ve da khi dung dung nong do.',
    author: 'Belumi Lab',
    coverImageUrl:
        'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b',
  ),
];
