import '../../core/network/api_client.dart';
import '../models/belumi_models.dart';

class AuthApiService {
  AuthApiService(this.api);
  final ApiClient api;

  Future<AuthUser> firebaseLogin({
    required String firebaseUid,
    required String email,
    required String fullName,
    String? avatarUrl,
  }) async {
    final data =
        await api.post('/auth/firebase-login', {
              'firebaseUid': firebaseUid,
              'email': email,
              'fullName': fullName,
              'avatarUrl': avatarUrl,
            })
            as Map<String, dynamic>;
    return AuthUser.fromJson(data);
  }
}

class SkincareApiService {
  SkincareApiService(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> analyze({
    required String userId,
    required String skinType,
    required List<String> concerns,
    String? ageRange,
    String? sensitivityLevel,
    String? note,
  }) async {
    return await api.post('/skincare/analyze', {
          'userId': userId,
          'skinType': skinType,
          'skinConcerns': concerns,
          'ageRange': ageRange,
          'sensitivityLevel': sensitivityLevel,
          'userNote': note,
        })
        as Map<String, dynamic>;
  }
}

class IngredientApiService {
  IngredientApiService(this.api);
  final ApiClient api;

  Future<IngredientScanResult> analyzeText(String inputText) async {
    final data =
        await api.post('/ingredients/analyze-text', {'inputText': inputText})
            as Map<String, dynamic>;
    return IngredientScanResult.fromJson(data);
  }
}

class MakeupApiService {
  MakeupApiService(this.api);
  final ApiClient api;

  Future<MakeupResult> consult({
    required String skinTone,
    required String occasion,
    required String stylePreference,
    String? note,
  }) async {
    final data =
        await api.post('/makeup/consult', {
              'skinTone': skinTone,
              'occasion': occasion,
              'stylePreference': stylePreference,
              'note': note,
            })
            as Map<String, dynamic>;
    return MakeupResult.fromJson(data);
  }
}

class NewsApiService {
  NewsApiService(this.api);
  final ApiClient api;

  Future<List<NewsArticle>> list() async {
    final data = await api.get('/news') as List<dynamic>;
    return data
        .map((x) => NewsArticle.fromJson(x as Map<String, dynamic>))
        .toList();
  }
}

class ProductApiService {
  ProductApiService(this.api);
  final ApiClient api;

  Future<List<Product>> list() async {
    final data = await api.get('/products') as List<dynamic>;
    return data
        .map((x) => Product.fromJson(x as Map<String, dynamic>))
        .toList();
  }
}

class WishlistApiService {
  WishlistApiService(this.api);
  final ApiClient api;

  Future<List<dynamic>> list() async =>
      await api.get('/wishlist') as List<dynamic>;
}

class SubscriptionApiService {
  SubscriptionApiService(this.api);
  final ApiClient api;

  Future<List<Plan>> plans() async {
    final data = await api.get('/subscription/plans') as List<dynamic>;
    return data.map((x) => Plan.fromJson(x as Map<String, dynamic>)).toList();
  }
}

class AdminApiService {
  AdminApiService(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> dashboard() async =>
      await api.get('/admin/dashboard') as Map<String, dynamic>;

  Future<List<dynamic>> users() async =>
      await api.get('/admin/users') as List<dynamic>;
  Future<List<dynamic>> aiUsage() async =>
      await api.get('/admin/ai-usage') as List<dynamic>;
}
