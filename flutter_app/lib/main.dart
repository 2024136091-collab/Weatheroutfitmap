import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

// 로컬 개발: 'http://localhost:3001'
// 배포: 'https://weatherstyle-backend-773203738037.asia-northeast3.run.app'
const String _baseUrl = 'http://localhost:3001';

// ============================================================
// 🛍️ 상품 & 장바구니 모델
// ============================================================

class Product {
  final String id;
  final String name;
  final String brand;
  final int price;
  final String imageUrl;
  final String category;
  final List<String> sizes;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.sizes,
  });
}

class CartItem {
  int? serverId;
  final Product product;
  String size;
  int quantity;
  CartItem({this.serverId, required this.product, required this.size, this.quantity = 1});
}

// ============================================================
// 📮 배송지 모델
// ============================================================
class DeliveryAddress {
  final String id;
  String name;
  String phone;
  String zipCode;
  String address;
  String detailAddress;
  String label;
  bool isDefault;

  DeliveryAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.zipCode,
    required this.address,
    required this.detailAddress,
    this.label = '집',
    this.isDefault = false,
  });
}

const List<String> _categories = ['전체', '상의', '하의', '아우터', '신발', '악세서리'];

final List<Product> _allProducts = [
  Product(
    id: '1',
    name: '오버핏 코튼 셔츠',
    brand: 'MUSINSA Standard',
    price: 39000,
    imageUrl: 'https://picsum.photos/seed/p1/400/500',
    category: '상의',
    sizes: ['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: '2',
    name: '와이드 데님 팬츠',
    brand: "Levi's",
    price: 89000,
    imageUrl: 'https://picsum.photos/seed/p2/400/500',
    category: '하의',
    sizes: ['28', '30', '32', '34'],
  ),
  Product(
    id: '3',
    name: '크롭 후드 집업',
    brand: 'Nike',
    price: 69000,
    imageUrl: 'https://picsum.photos/seed/p3/400/500',
    category: '상의',
    sizes: ['XS', 'S', 'M', 'L'],
  ),
  Product(
    id: '4',
    name: '슬림 슬랙스',
    brand: 'SPAO',
    price: 49000,
    imageUrl: 'https://picsum.photos/seed/p4/400/500',
    category: '하의',
    sizes: ['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: '5',
    name: '울 블렌드 코트',
    brand: 'ZARA',
    price: 159000,
    imageUrl: 'https://picsum.photos/seed/p5/400/500',
    category: '아우터',
    sizes: ['XS', 'S', 'M', 'L'],
  ),
  Product(
    id: '6',
    name: '캔버스 스니커즈',
    brand: 'Converse',
    price: 79000,
    imageUrl: 'https://picsum.photos/seed/p6/400/500',
    category: '신발',
    sizes: ['240', '245', '250', '255', '260', '265', '270'],
  ),
  Product(
    id: '7',
    name: '스트라이프 니트',
    brand: 'H&M',
    price: 35000,
    imageUrl: 'https://picsum.photos/seed/p7/400/500',
    category: '상의',
    sizes: ['S', 'M', 'L'],
  ),
  Product(
    id: '8',
    name: '카고 팬츠',
    brand: 'Carhartt',
    price: 119000,
    imageUrl: 'https://picsum.photos/seed/p8/400/500',
    category: '하의',
    sizes: ['28', '30', '32', '34', '36'],
  ),
  Product(
    id: '9',
    name: '데님 재킷',
    brand: 'Wrangler',
    price: 99000,
    imageUrl: 'https://picsum.photos/seed/p9/400/500',
    category: '아우터',
    sizes: ['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: '10',
    name: '로퍼 슈즈',
    brand: 'ALDO',
    price: 89000,
    imageUrl: 'https://picsum.photos/seed/p10/400/500',
    category: '신발',
    sizes: ['240', '245', '250', '255', '260', '265'],
  ),
  Product(
    id: '11',
    name: '미니멀 크루넥 티',
    brand: 'COS',
    price: 45000,
    imageUrl: 'https://picsum.photos/seed/p11/400/500',
    category: '상의',
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
  ),
  Product(
    id: '12',
    name: '플리스 집업',
    brand: 'Patagonia',
    price: 189000,
    imageUrl: 'https://picsum.photos/seed/p12/400/500',
    category: '아우터',
    sizes: ['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: '13',
    name: '스키니 진',
    brand: 'Uniqlo',
    price: 59000,
    imageUrl: 'https://picsum.photos/seed/p13/400/500',
    category: '하의',
    sizes: ['26', '27', '28', '29', '30', '32'],
  ),
  Product(
    id: '14',
    name: '청키 스니커즈',
    brand: 'New Balance',
    price: 129000,
    imageUrl: 'https://picsum.photos/seed/p14/400/500',
    category: '신발',
    sizes: ['245', '250', '255', '260', '265', '270', '275'],
  ),
  Product(
    id: '15',
    name: '레더 벨트',
    brand: 'Tommy Hilfiger',
    price: 49000,
    imageUrl: 'https://picsum.photos/seed/p15/400/500',
    category: '악세서리',
    sizes: ['Free'],
  ),
  Product(
    id: '16',
    name: '버킷햇',
    brand: 'Kangol',
    price: 55000,
    imageUrl: 'https://picsum.photos/seed/p16/400/500',
    category: '악세서리',
    sizes: ['Free'],
  ),
  Product(
    id: '17',
    name: '린넨 셔츠',
    brand: 'Massimo Dutti',
    price: 89000,
    imageUrl: 'https://picsum.photos/seed/p17/400/500',
    category: '상의',
    sizes: ['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: '18',
    name: '와이드 조거팬츠',
    brand: 'Adidas',
    price: 69000,
    imageUrl: 'https://picsum.photos/seed/p18/400/500',
    category: '하의',
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
  ),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherStyleApp());
}

class WeatherStyleApp extends StatelessWidget {
  const WeatherStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Style',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.grey,
        ),
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String token;
  final String userName;
  final String userEmail;
  final String userAge;
  final String userStyle;
  final String? profileImage;
  final String? withdrawalRequestedAt;

  const MainScreen({
    super.key,
    this.token = '',
    this.userName = '',
    this.userEmail = '',
    this.userAge = '20대',
    this.userStyle = '캐주얼',
    this.profileImage,
    this.withdrawalRequestedAt,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 사용자 정보
  late String _token;
  late String _userName;
  late String _userEmail;
  late String _userAge;
  late String _userStyle;
  String? _profileImage;
  DateTime? _withdrawalRequestedAt;

  bool get _isLoggedIn => _token.isNotEmpty;

  // ==========================================
  // ⭐️ [STATE] 실시간 데이터를 저장할 변수들
  // ==========================================
  bool _isLoading = true; // 로딩 상태
  String _errorMessage = ""; // 에러 메시지

  // 기본값 설정 (서버 연결 실패 시 보여줄 데이터)
  String _city = "내 위치";
  double? _latitude;
  double? _longitude;
  double _temperature = 0.0;
  String _weatherStatus = "날씨 정보 없음";
  String _aiRecommendation = "실시간 날씨 기반 AI 코멘트가 여기에 표시됩니다.";
  String _ootdImageUrl =
      "https://images.unsplash.com/photo-1550639525-c97d455acf70?auto=format&fit=crop&w=600&q=80"; // 기본 옷 사진

  // 날씨 상세 데이터 (날씨 탭에서 사용)
  double _humidity = 0.0;
  double _windSpeed = 0.0;

  // 검색
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '전체';
  final List<String> _recentSearches = [];

  // 장바구니
  final List<CartItem> _cartItems = [];

  // 찜한 상품
  final Set<String> _wishlist = {}; // product.id 저장

  void _toggleWishlist(Product product) {
    setState(() {
      if (_wishlist.contains(product.id)) {
        _wishlist.remove(product.id);
      } else {
        _wishlist.add(product.id);
      }
    });
    if (_wishlist.contains(product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('찜 목록에 추가되었습니다. ❤️'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '찜 목록 보기',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WishlistScreen(
                  wishlistedProducts: _allProducts
                      .where((p) => _wishlist.contains(p.id))
                      .toList(),
                  wishlist: _wishlist,
                  onToggleWishlist: _toggleWishlist,
                  onAddToCart: _addToCart,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('찜 목록에서 제거되었습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadCartFromServer() async {
    if (!_isLoggedIn) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/cart'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _cartItems.clear();
          for (final row in data) {
            final product = _allProducts.firstWhere(
              (p) => p.id == row['product_id'],
              orElse: () => Product(
                id: row['product_id'],
                name: row['name'],
                brand: row['brand'] ?? '',
                price: row['price'] ?? 0,
                imageUrl: row['image_url'] ?? '',
                category: '기타',
                sizes: [row['size']],
              ),
            );
            _cartItems.add(CartItem(
              serverId: row['id'],
              product: product,
              size: row['size'],
              quantity: row['quantity'],
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _addToCart(Product product, String size) async {
    if (!_isLoggedIn) return;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/cart'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': product.id,
          'name': product.name,
          'brand': product.brand,
          'price': product.price,
          'image_url': product.imageUrl,
          'size': size,
          'quantity': 1,
        }),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _cartItems.clear();
          for (final row in data) {
            final p = _allProducts.firstWhere(
              (p) => p.id == row['product_id'],
              orElse: () => Product(
                id: row['product_id'],
                name: row['name'],
                brand: row['brand'] ?? '',
                price: row['price'] ?? 0,
                imageUrl: row['image_url'] ?? '',
                category: '기타',
                sizes: [row['size']],
              ),
            );
            _cartItems.add(CartItem(
              serverId: row['id'],
              product: p,
              size: row['size'],
              quantity: row['quantity'],
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _updateCartQuantity(CartItem item, int newQuantity) async {
    if (!_isLoggedIn || item.serverId == null) return;
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/cart/${item.serverId}'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: jsonEncode({'quantity': newQuantity}),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        _syncCartFromResponse(data);
      }
    } catch (_) {}
  }

  Future<void> _removeCartItem(CartItem item) async {
    if (!_isLoggedIn || item.serverId == null) {
      setState(() => _cartItems.remove(item));
      return;
    }
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/cart/${item.serverId}'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        _syncCartFromResponse(data);
      }
    } catch (_) {
      setState(() => _cartItems.remove(item));
    }
  }

  void _syncCartFromResponse(List data) {
    setState(() {
      _cartItems.clear();
      for (final row in data) {
        final p = _allProducts.firstWhere(
          (p) => p.id == row['product_id'],
          orElse: () => Product(
            id: row['product_id'],
            name: row['name'],
            brand: row['brand'] ?? '',
            price: row['price'] ?? 0,
            imageUrl: row['image_url'] ?? '',
            category: '기타',
            sizes: [row['size']],
          ),
        );
        _cartItems.add(CartItem(
          serverId: row['id'],
          product: p,
          size: row['size'],
          quantity: row['quantity'],
        ));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _userName = widget.userName;
    _userEmail = widget.userEmail;
    _userAge = widget.userAge;
    _userStyle = widget.userStyle;
    _profileImage = widget.profileImage;
    if (widget.withdrawalRequestedAt != null) {
      _withdrawalRequestedAt = DateTime.tryParse(widget.withdrawalRequestedAt!);
    }
    _initLocationAndFetch();
    if (_isLoggedIn) _loadCartFromServer();
  }

  // ==========================================
  // 📍 [GPS] 위치 권한 요청 및 좌표 가져오기
  // ==========================================
  Future<void> _initLocationAndFetch() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스 비활성화 → 기본 도시로 폴백
      fetchWeatherData();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // 권한 거부 → 기본 도시로 폴백
      fetchWeatherData();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      // GPS 오류 → 기본 도시로 폴백
    }

    fetchWeatherData();
  }

  // ==========================================
  // 🐍 [API 연동] 파이썬 서버와 통신하는 함수
  // ==========================================
  Future<void> _getNewRecommendation() async {
    // AI 스타일리스트 추천 새로고침
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final Uri url;
    if (_latitude != null && _longitude != null) {
      url = Uri.parse(
        '$_baseUrl/recommend-smart?lat=$_latitude&lon=$_longitude',
      );
    } else {
      url = Uri.parse('$_baseUrl/recommend-smart?city=$_city');
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _aiRecommendation = data['ai_recommendation'] ?? "추천을 불러올 수 없습니다.";
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = "추천을 불러올 수 없습니다.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("추천 새로고침 오류: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "서버와 연결할 수 없습니다.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchWeatherData() async {
    setState(() {
      _isLoading = true; // 로딩 시작
      _errorMessage = ""; // 에러 초기화
    });

    // 💡 크롬 환경이면 127.0.0.1, 에뮬레이터면 10.0.2.2 (본인 환경에 맞게 확인!)
    // GPS 좌표가 있으면 lat/lon으로 요청, 없으면 기본 도시명으로 요청
    final Uri url;
    if (_latitude != null && _longitude != null) {
      url = Uri.parse(
        '$_baseUrl/recommend-smart?lat=$_latitude&lon=$_longitude',
      );
    } else {
      url = Uri.parse('$_baseUrl/recommend-smart?city=Seongnam');
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        // 서버 응답 성공!
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          // 받아온 진짜 데이터로 변수 업데이트!
          _city = data['city'] ?? _city;
          _temperature = data['temperature'];
          _weatherStatus = data['weather_status'];
          _aiRecommendation = data['ai_recommendation'] ?? _aiRecommendation;

          // 상세 날씨 데이터 (날씨 탭용)
          _humidity = (data['humidity'] ?? 0).toDouble();
          _windSpeed = (data['wind_speed'] ?? 0).toDouble();

          // 추천 코디 사진 (첫 번째 옷 사용)
          if (data['recommended_clothes'] != null &&
              data['recommended_clothes'].isNotEmpty) {
            _ootdImageUrl = data['recommended_clothes'][0]['image_url'];
          }
          _isLoading = false; // 로딩 완료
        });
      } else {
        // 서버 응답 에러 (예: 500 에러)
        throw Exception('서버 응답 오류 (상태코드: ${response.statusCode})');
      }
    } catch (e) {
      // 네트워크 에러 등 발생 시
      print("🚨 API 연결 에러: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "서버와 연결할 수 없습니다. \n파이썬 서버가 켜져 있는지 확인해 주세요!";
      });
    }
  }

  // ==========================================
  // 👤 [프로필] 수정 및 로그아웃
  // ==========================================
  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

    final uri = Uri.parse('$_baseUrl/auth/profile-image');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_token'
      ..files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: picked.name,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg')));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final data = jsonDecode(body);
    if (streamed.statusCode == 200 && data['profile_image'] != null) {
      setState(() => _profileImage = data['profile_image']);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? '업로드 실패')),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    String selectedAge = _userAge;
    String selectedStyle = _userStyle;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('스타일 프로필 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedAge,
                decoration: const InputDecoration(labelText: '연령대'),
                items: ['10대', '20대', '30대', '40대', '50대이상']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedAge = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStyle,
                decoration: const InputDecoration(labelText: '스타일'),
                items: ['캐주얼', '스트릿', '포멀', '스포티', '미니멀']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedStyle = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(context);
                await _updateProfile(selectedAge, selectedStyle);
              },
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile(String age, String style) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'age': age, 'style': style}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _userAge = age;
          _userStyle = style;
        });
        fetchWeatherData(); // 변경된 스타일로 AI 추천 갱신
      }
    } catch (e) {
      print('프로필 업데이트 오류: $e');
    }
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    String errorMsg = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '현재 비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 확인',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorMsg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                if (newPwController.text != confirmPwController.text) {
                  setDialogState(() => errorMsg = '새 비밀번호가 일치하지 않습니다.');
                  return;
                }
                if (newPwController.text.length < 6) {
                  setDialogState(() => errorMsg = '비밀번호는 6자 이상이어야 합니다.');
                  return;
                }
                try {
                  final response = await http.put(
                    Uri.parse('$_baseUrl/auth/password'),
                    headers: {
                      'Authorization': 'Bearer $_token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'current_password': currentPwController.text,
                      'new_password': newPwController.text,
                    }),
                  );
                  if (response.statusCode == 200) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
                      );
                    }
                  } else {
                    final data = jsonDecode(utf8.decode(response.bodyBytes));
                    setDialogState(
                      () => errorMsg = data['detail'] ?? '변경에 실패했습니다.',
                    );
                  }
                } catch (_) {
                  setDialogState(() => errorMsg = '서버와 연결할 수 없습니다.');
                }
              },
              child: const Text('변경', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text(
          '탈퇴 신청 후 30일간 계정이 유지되며\n그 기간 내에 취소할 수 있습니다.\n30일 후 모든 정보가 영구 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.delete(
                  Uri.parse('$_baseUrl/auth/withdraw'),
                  headers: {'Authorization': 'Bearer $_token'},
                );
                if (response.statusCode == 200 && mounted) {
                  setState(() => _withdrawalRequestedAt = DateTime.now());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('탈퇴 신청됐습니다. 30일 후 계정이 삭제됩니다.')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('서버와 연결할 수 없습니다.')),
                  );
                }
              }
            },
            child: const Text('탈퇴 신청', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelWithdrawal() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/withdraw/cancel'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _withdrawalRequestedAt = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('탈퇴 신청이 취소됐습니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버와 연결할 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    setState(() {
      _token = '';
      _userName = '';
      _userEmail = '';
      _userAge = '20대';
      _userStyle = '캐주얼';
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) async {
    // 장바구니(3), 마이페이지(4)는 로그인 필요
    if ((index == 3 || index == 4) && !_isLoggedIn) {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(returnAfterLogin: true),
        ),
      );
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token']);
        setState(() {
          _token = result['token'];
          _userName = result['name'];
          _userEmail = result['email'];
          _userAge = result['age'];
          _userStyle = result['style'];
          _selectedIndex = index;
        });
        fetchWeatherData();
        _loadCartFromServer();
      }
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 5개의 탭 화면 리스트
    final List<Widget> pages = [
      _buildHomeScreen(), // 0: 홈 (진짜 데이터 연동)
      _buildWeatherScreen(), // 1: 날씨 (진짜 데이터 연동)
      _buildSearchScreen(), // 2: 검색 (준비 중)
      _buildCartScreen(), // 3: 장바구니 (준비 중)
      _buildMyPageScreen(), // 4: 마이 (준비 중)
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny),
            label: '날씨',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🏠 [탭 0] 홈 화면 (OOTD) - 진짜 데이터 연동
  // ==========================================
  Widget _buildHomeScreen() {
    // ⭐️ 오늘 날짜 가져오기 (intl 패키지 사용)
    String todayDate = DateFormat('yyyy년 M월 d일').format(DateTime.now());

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: fetchWeatherData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(), // Pull-to-refresh 작동 보장
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "OOTD",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: fetchWeatherData,
              ), // 새로고침 버튼
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ), // ⭐️ 진짜 오늘 날짜
                  Text(
                    _city,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ), // ⭐️ 진짜 도시명
                  const SizedBox(height: 10),
                  Text(
                    "${_temperature.toInt()}°",
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                    ),
                  ), // ⭐️ 진짜 온도
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 40),
                  const SizedBox(height: 5),
                  Text(
                    _weatherStatus,
                    style: const TextStyle(fontSize: 14),
                  ), // ⭐️ 진짜 날씨 상태
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          const Text(
            "오늘의 추천 코디",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // ⭐️ 파이썬 서버에서 받은 코디 사진
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _ootdImageUrl,
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 400,
                color: Colors.grey[100],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AI 스타일리스트 추천",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: _isLoading ? null : _getNewRecommendation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "다른 추천 보기",
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          _aiRecommendation, // ⭐️ 진짜 Gemini AI 코멘트!
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // ☀️ [탭 1] 날씨 상세 화면 - 진짜 데이터 연동
  // ==========================================
  Widget _buildWeatherScreen() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "날씨",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(
          _city,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ), // ⭐️ 진짜 도시명
        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_temperature.toInt()}°",
                  style: const TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.w300,
                    height: 1.0,
                  ),
                ), // ⭐️ 진짜 온도
                Text(
                  _weatherStatus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ), // ⭐️ 진짜 날씨 상태
                const Text(
                  "체감 29°",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ), // (체감온도는 추후 구현 가능)
              ],
            ),
            const Icon(Icons.wb_sunny_outlined, size: 80),
          ],
        ),
        const SizedBox(height: 40),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          children: [
            _weatherDetailItem(
              Icons.water_drop_outlined,
              "습도",
              "${_humidity.toInt()}%",
            ), // ⭐️ 진짜 습도!
            _weatherDetailItem(
              Icons.air,
              "풍속",
              "${_windSpeed.toInt()} m/s",
            ), // ⭐️ 진짜 풍속!
            _weatherDetailItem(Icons.visibility_outlined, "가시거리", "10 km"),
            _weatherDetailItem(Icons.speed, "기압", "1013 hPa"),
          ],
        ),

        const Divider(height: 40, color: Colors.black12),

        const Text(
          "대기질",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "통합 대기질 지수",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "42",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "좋음",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "대기질이 양호합니다. 외출하기 좋은 날씨예요.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherDetailItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  // --- 나머지 탭 (검색, 장바구니, 마이) 화면은 기존 도면 UI 유지 (데이터 연동 안 함) ---

  Widget _buildSearchScreen() {
    final filteredProducts = _allProducts.where((p) {
      final matchQuery =
          _searchQuery.isEmpty ||
          p.name.contains(_searchQuery) ||
          p.brand.contains(_searchQuery);
      final matchCategory =
          _selectedCategory == '전체' || p.category == _selectedCategory;
      return matchQuery && matchCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '검색',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '상품명 또는 브랜드를 검색해보세요',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _recentSearches.remove(v.trim());
                      _recentSearches.insert(0, v.trim());
                      if (_recentSearches.length > 10) {
                        _recentSearches.removeLast();
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // 카테고리 칩
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 최근 검색어 (검색어 없을 때만)
        if (_searchQuery.isEmpty && _recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 검색어',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => setState(() => _recentSearches.clear()),
                  child: Text(
                    '전체삭제',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _recentSearches.map((tag) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = tag;
                    setState(() => _searchQuery = tag);
                  },
                  child: Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        setState(() => _recentSearches.remove(tag)),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 8),

        // 상품 그리드
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (_, i) => _buildProductCard(filteredProducts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final formatter = NumberFormat('#,###');
    final isWished = _wishlist.contains(product.id);
    return GestureDetector(
      onTap: () => _showProductDetail(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                // 찜 하트 버튼
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(product),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWished ? Icons.favorite : Icons.favorite_border,
                        color: isWished ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.brand,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            product.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${formatter.format(product.price)}원',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(Product product) {
    String? selectedSize;
    final formatter = NumberFormat('#,###');
    final mainContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 280,
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 브랜드 + 찜 버튼 행
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.brand,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        StatefulBuilder(
                          builder: (_, setHeartState) {
                            final isWished = _wishlist.contains(product.id);
                            return GestureDetector(
                              onTap: () {
                                _toggleWishlist(product);
                                setHeartState(() {});
                                setSheetState(() {});
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    isWished
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isWished ? Colors.red : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isWished ? '찜 완료' : '찜하기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isWished
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatter.format(product.price)}원',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '사이즈',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.sizes.map((size) {
                        final selected = selectedSize == size;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedSize = size),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? Colors.black : Colors.white,
                              border: Border.all(
                                color: selected
                                    ? Colors.black
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              size,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: selectedSize == null
                            ? null
                            : () async {
                                Navigator.pop(sheetContext);
                                await _addToCart(product, selectedSize!);
                                if (!mainContext.mounted) return;
                                ScaffoldMessenger.of(mainContext).showSnackBar(
                                  SnackBar(
                                    content: const Text('장바구니에 담았습니다.'),
                                    action: SnackBarAction(
                                      label: '장바구니 보기',
                                      onPressed: () =>
                                          setState(() => _selectedIndex = 3),
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          selectedSize == null ? '사이즈를 선택해주세요' : '장바구니 담기',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 찜하기 버튼
                    StatefulBuilder(
                      builder: (_, setWishBtnState) {
                        final isWished = _wishlist.contains(product.id);
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isWished ? Colors.red : Colors.black26,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _toggleWishlist(product);
                              setWishBtnState(() {});
                              setSheetState(() {});
                            },
                            icon: Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              color: isWished ? Colors.red : Colors.black87,
                              size: 20,
                            ),
                            label: Text(
                              isWished ? '찜 취소' : '찜하기',
                              style: TextStyle(
                                color: isWished ? Colors.red : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartScreen() {
    final formatter = NumberFormat('#,###');
    final subtotal = _cartItems.fold<int>(
      0,
      (sum, item) => sum + item.product.price * item.quantity,
    );
    final shipping = (subtotal == 0 || subtotal >= 50000) ? 0 : 3000;
    final total = subtotal + shipping;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '장바구니',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.black12),

        if (_cartItems.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '장바구니가 비어있습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ..._cartItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _cartItemCard(item),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 16),
                _priceRow('상품금액', '${formatter.format(subtotal)}원'),
                const SizedBox(height: 12),
                _priceRow(
                  '배송비',
                  shipping == 0 ? '무료' : '${formatter.format(shipping)}원',
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '총 결제금액',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${formatter.format(total)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final res = await http.post(
                        Uri.parse('$_baseUrl/orders'),
                        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'total_price': subtotal,
                          'shipping': shipping,
                          'items': _cartItems.map((c) => {
                            'product_id': c.product.id,
                            'name': c.product.name,
                            'brand': c.product.brand,
                            'price': c.product.price,
                            'image_url': c.product.imageUrl,
                            'size': c.size,
                            'quantity': c.quantity,
                          }).toList(),
                        }),
                      );
                      if (res.statusCode == 200 && mounted) {
                        setState(() => _cartItems.clear());
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('주문 완료'),
                            content: const Text('주문이 접수됐습니다.\n마이탭 > 주문/배송 조회에서 확인하세요.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() => _selectedIndex = 4);
                                },
                                child: const Text('주문 확인', style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Text(
                      '${formatter.format(total)}원 결제하기',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cartItemCard(CartItem item) {
    final formatter = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[100],
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '사이즈: ${item.size}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(item.product.price)}원',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.quantity > 1) {
                                _updateCartQuantity(item, item.quantity - 1);
                              } else {
                                _removeCartItem(item);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => _updateCartQuantity(item, item.quantity + 1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _removeCartItem(item),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    );
  }

  Widget _buildMyPageScreen() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "마이",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 30),

        Row(
          children: [
            GestureDetector(
              onTap: _isLoggedIn ? _uploadProfileImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.black,
                    backgroundImage: (_profileImage != null && _profileImage!.isNotEmpty)
                        ? NetworkImage('$_baseUrl$_profileImage')
                        : null,
                    child: (_profileImage == null || _profileImage!.isEmpty)
                        ? Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : "?",
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                          )
                        : null,
                  ),
                  if (_isLoggedIn)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: const Icon(Icons.camera_alt, size: 13, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_userName님",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _myStatItem("연령대", _userAge),
            _myStatItem("스타일", _userStyle),
            _myStatItem("등급", "일반"),
          ],
        ),
        const SizedBox(height: 30),
        const Divider(height: 1, color: Colors.black12),
        const SizedBox(height: 20),

        const Text("쇼핑 정보", style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.checkroom_outlined, color: Colors.black87),
          title: const Text("내 옷장", style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ClosetScreen(token: _token)),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.inventory_2_outlined, color: Colors.black87),
          title: const Text("주문/배송 조회", style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderListScreen(token: _token)),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.favorite_border, color: Colors.black87),
          title: Row(
            children: [
              const Text("찜한 상품", style: TextStyle(fontSize: 16)),
              if (_wishlist.isNotEmpty) ...[
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(
                    '${_wishlist.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WishlistScreen(
                wishlistedProducts: _allProducts
                    .where((p) => _wishlist.contains(p.id))
                    .toList(),
                wishlist: _wishlist,
                onToggleWishlist: _toggleWishlist,
                onAddToCart: _addToCart,
              ),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.location_on_outlined,
            color: Colors.black87,
          ),
          title: const Text("배송지 관리", style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeliveryAddressScreen()),
          ),
        ),

        const SizedBox(height: 30),

        const Text("설정", style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_none, color: Colors.black87),
          title: const Text("알림 설정", style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NotificationSettingsScreen(token: _token)),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_outlined, color: Colors.black87),
          title: const Text("스타일 프로필 수정", style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: _showEditProfileDialog,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline, color: Colors.black87),
          title: const Text("비밀번호 변경", style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: _showChangePasswordDialog,
        ),

        const SizedBox(height: 30),
        const Divider(height: 1, color: Colors.black12),
        const SizedBox(height: 10),

        if (_withdrawalRequestedAt != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '탈퇴 신청 중 · ${_withdrawalRequestedAt!.add(const Duration(days: 30)).difference(DateTime.now()).inDays + 1}일 후 계정 삭제',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _cancelWithdrawal,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('취소', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        TextButton(
          onPressed: _logout,
          child: const Text(
            "로그아웃",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        if (_withdrawalRequestedAt == null)
          TextButton(
            onPressed: _showWithdrawDialog,
            child: const Text(
              "회원탈퇴",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _myStatItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _myMenuTile(IconData icon, String title, {String? badge}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          if (badge != null) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black,
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

// ============================================================
// 🔐 AuthWrapper — 저장된 토큰 확인 후 화면 분기
// ============================================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainScreen(
                token: token,
                userName: data['name'],
                userEmail: data['email'],
                userAge: data['age'],
                userStyle: data['style'],
                profileImage: data['profile_image'],
                withdrawalRequestedAt: data['withdrawal_requested_at']?.toString(),
              ),
            ),
          );
          return;
        }
      } catch (_) {}
      await prefs.remove('token');
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}

// ============================================================
// 🔑 LoginScreen
// ============================================================
class LoginScreen extends StatefulWidget {
  final bool returnAfterLogin;
  const LoginScreen({super.key, this.returnAfterLogin = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (mounted) {
          if (widget.returnAfterLogin) {
            Navigator.of(context).pop(data);
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainScreen(
                  token: data['token'],
                  userName: data['name'],
                  userEmail: data['email'],
                  userAge: data['age'],
                  userStyle: data['style'],
                  profileImage: data['profile_image'],
                  withdrawalRequestedAt: data['withdrawal_requested_at']?.toString(),
                ),
              ),
            );
          }
        }
      } else {
        setState(() => _errorMessage = data['detail'] ?? '로그인에 실패했습니다.');
      }
    } catch (_) {
      setState(() => _errorMessage = '서버와 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Weather\nStyle',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '날씨에 맞는 오늘의 코디를 추천해드려요.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _login(),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(
                        returnAfterLogin: widget.returnAfterLogin,
                      ),
                    ),
                  ),
                  child: const Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 📝 RegisterScreen
// ============================================================
class RegisterScreen extends StatefulWidget {
  final bool returnAfterLogin;
  const RegisterScreen({super.key, this.returnAfterLogin = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedAge = '20대';
  String _selectedStyle = '캐주얼';
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = '모든 항목을 입력해주세요.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = '비밀번호는 6자 이상이어야 합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'age': _selectedAge,
          'style': _selectedStyle,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (mounted) {
          if (widget.returnAfterLogin) {
            Navigator.of(context).pop(data);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => MainScreen(
                  token: data['token'],
                  userName: data['name'],
                  userEmail: data['email'],
                  userAge: data['age'],
                  userStyle: data['style'],
                  profileImage: data['profile_image'],
                  withdrawalRequestedAt: data['withdrawal_requested_at']?.toString(),
                ),
              ),
              (route) => false,
            );
          }
        }
      } else {
        setState(() => _errorMessage = data['detail'] ?? '회원가입에 실패했습니다.');
      }
    } catch (_) {
      setState(() => _errorMessage = '서버와 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '회원가입',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                '연령대',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedAge,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['10대', '20대', '30대', '40대', '50대이상']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAge = v!),
              ),
              const SizedBox(height: 16),

              const Text(
                '선호 스타일',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStyle,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['캐주얼', '스트릿', '포멀', '스포티', '미니멀']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStyle = v!),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          '가입하기',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 👗 ClosetScreen — 내 옷장
// ============================================================
class ClosetScreen extends StatefulWidget {
  final String token;
  const ClosetScreen({super.key, required this.token});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _filterCategory = '전체';

  static const _filterOptions = [
    '전체',
    '상의',
    '하의',
    '아우터',
    '신발',
    '악세서리',
    '원피스',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCloset();
  }

  Future<void> _fetchCloset() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/closet'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _items = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    // 카메라 / 갤러리 선택
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      // 1단계: 파일 읽기
      print('[옷장] 파일 읽는 중: ${pickedFile.name}');
      final bytes = await pickedFile.readAsBytes();
      print('[옷장] 파일 크기: ${bytes.length} bytes');

      // 2단계: 요청 구성
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/closet/upload'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      final filename = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'image.jpg';

      // MIME 타입 자동 감지
      String mimeType = 'image/jpeg'; // 기본값
      if (filename.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filename.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (filename.endsWith('.heic')) {
        mimeType = 'image/heic';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: http.MediaType('image', mimeType.split('/')[1]),
        ),
      );

      // 3단계: 전송
      print('[옷장] 서버로 전송 중...');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      print('[옷장] 서버 응답: ${response.statusCode}');

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final items = List<dynamic>.from(data['items'] ?? []);
        setState(() {
          for (var item in items.reversed) {
            _items.insert(0, item);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '옷장에 추가됐어요!')),
        );
      } else if (mounted) {
        print('[옷장] 실패 응답: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패 (${response.statusCode})')),
        );
      }
    } catch (e, stack) {
      print('[옷장] 오류 발생: $e');
      print('[옷장] 스택: $stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteItem(Map item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제'),
        content: Text('\'${item['description']}\' 을(를) 옷장에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/closet/${item['id']}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _items.removeWhere((i) => i['id'] == item['id']));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCategory == '전체'
        ? _items
        : _items.where((i) => i['category'] == _filterCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '내 옷장',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickAndUpload,
        backgroundColor: Colors.black,
        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                // 카테고리 필터
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _filterOptions[i];
                      final selected = _filterCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _filterCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 아이템 수
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length}개',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),

                // 그리드
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.checkroom_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filterCategory == '전체'
                                    ? '옷장이 비어있습니다.'
                                    : '$_filterCategory 카테고리에 옷이 없습니다.',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                              if (_filterCategory == '전체') ...[
                                const SizedBox(height: 8),
                                const Text(
                                  '+ 버튼으로 옷 사진을 추가해보세요.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 이미지 카드
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          '$_baseUrl${item['image_url']}',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (_, _, _) => Container(
                                            color: Colors.grey[100],
                                            child: const Center(
                                              child: Icon(
                                                Icons.checkroom_outlined,
                                                color: Colors.grey,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 계절 뱃지 (좌상단)
                                      if (item['season'] != null)
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.65,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              item['season'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // 삭제 X 버튼 (우상단)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => _deleteItem(item),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // 설명 (제목)
                                Text(
                                  item['description'] ?? '기타',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // 색상 · 스타일
                                Text(
                                  '${item['color'] ?? ''} · ${item['style'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// 📋 DeliveryAddressScreen — 배송지 목록 화면
// ============================================================
class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final List<DeliveryAddress> _addresses = [];

  void _setDefault(DeliveryAddress addr) {
    setState(() {
      for (final a in _addresses) {
        a.isDefault = false;
      }
      addr.isDefault = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기본 배송지로 설정되었습니다.')));
  }

  void _delete(DeliveryAddress addr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('배송지 삭제'),
        content: Text('\'${addr.address}\' 배송지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _addresses.remove(addr));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('배송지가 삭제되었습니다.')));
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddEdit({DeliveryAddress? existing}) async {
    final result = await Navigator.of(context).push<DeliveryAddress>(
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(existing: existing),
      ),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final idx = _addresses.indexWhere((a) => a.id == existing.id);
          if (idx >= 0) _addresses[idx] = result;
        } else {
          if (_addresses.isEmpty) result.isDefault = true;
          _addresses.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '배송지 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _openAddEdit(),
            child: const Text(
              '+ 추가',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '등록된 배송지가 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => _openAddEdit(),
                    child: const Text(
                      '배송지 추가하기',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _addressCard(_addresses[i]),
            ),
      bottomNavigationBar: _addresses.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _openAddEdit(),
                    child: const Text(
                      '+ 새 배송지 추가',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _addressCard(DeliveryAddress addr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: addr.isDefault ? Colors.black : Colors.black12,
          width: addr.isDefault ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 라벨 + 기본배송지 뱃지 + 수정/삭제
          Row(
            children: [
              Text(
                addr.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (addr.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '기본 배송지',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _openAddEdit(existing: addr),
                child: const Text(
                  '수정',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              const Text(' | ', style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () => _delete(addr),
                child: const Text(
                  '삭제',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 수령인 + 연락처
          Row(
            children: [
              Text(
                addr.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                addr.phone,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '[${addr.zipCode}] ${addr.address}',
            style: const TextStyle(fontSize: 14),
          ),
          if (addr.detailAddress.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              addr.detailAddress,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
          if (!addr.isDefault) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _setDefault(addr),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '기본 배송지로 설정',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ✏️ AddEditAddressScreen — 배송지 추가 / 수정 폼
// ============================================================
class AddEditAddressScreen extends StatefulWidget {
  final DeliveryAddress? existing;

  const AddEditAddressScreen({super.key, this.existing});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _detailCtrl;
  String _selectedLabel = '집';

  final List<String> _labels = ['집', '회사', '기타'];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _zipCtrl = TextEditingController(text: e?.zipCode ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _detailCtrl = TextEditingController(text: e?.detailAddress ?? '');
    _selectedLabel = e?.label ?? '집';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _zipCtrl.dispose();
    _addressCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = DeliveryAddress(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      detailAddress: _detailCtrl.text.trim(),
      label: _selectedLabel,
      isDefault: widget.existing?.isDefault ?? false,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? '배송지 수정' : '배송지 추가',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 배송지 이름 (라벨) 선택 ───
                const Text(
                  '배송지 이름',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _labels.map((label) {
                    final selected = _selectedLabel == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedLabel = label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : Colors.white,
                            border: Border.all(
                              color: selected ? Colors.black : Colors.black26,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ─── 수령인 ───
                _fieldLabel('수령인'),
                _textField(
                  controller: _nameCtrl,
                  hint: '이름을 입력해주세요',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '수령인을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                // ─── 연락처 ───
                _fieldLabel('연락처'),
                _textField(
                  controller: _phoneCtrl,
                  hint: '010-0000-0000',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '연락처를 입력해주세요';
                    }
                    final clean = v.replaceAll('-', '').replaceAll(' ', '');
                    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(clean)) {
                      return '올바른 전화번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── 우편번호 ───
                _fieldLabel('우편번호'),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _zipCtrl,
                        hint: '우편번호',
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '우편번호를 입력해주세요'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        // TODO: 카카오 우편번호 API 연동
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '우편번호 검색 API를 연동해주세요 (카카오 주소 API 권장)',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        '검색',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── 기본 주소 ───
                _fieldLabel('기본 주소'),
                _textField(
                  controller: _addressCtrl,
                  hint: '도로명 또는 지번 주소',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '주소를 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                // ─── 상세 주소 ───
                _fieldLabel('상세 주소'),
                _textField(controller: _detailCtrl, hint: '아파트명, 동/호수 등 (선택)'),
                const SizedBox(height: 40),

                // ─── 저장 버튼 ───
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _save,
                    child: Text(
                      _isEdit ? '수정 완료' : '배송지 저장',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

// ============================================================
// ❤️ WishlistScreen — 찜한 상품 목록 + 결제
// ============================================================
class WishlistScreen extends StatefulWidget {
  final List<Product> wishlistedProducts;
  final Set<String> wishlist;
  final void Function(Product) onToggleWishlist;
  final void Function(Product, String) onAddToCart;

  const WishlistScreen({
    super.key,
    required this.wishlistedProducts,
    required this.wishlist,
    required this.onToggleWishlist,
    required this.onAddToCart,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // 체크박스 선택 상태
  final Set<String> _selected = {};
  // 선택된 상품별 사이즈
  final Map<String, String?> _selectedSizes = {};

  late List<Product> _products;

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.wishlistedProducts);
    for (final p in _products) {
      _selected.add(p.id);
      _selectedSizes[p.id] = null;
    }
  }

  bool get _allSelected =>
      _products.isNotEmpty && _selected.length == _products.length;

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(_products.map((p) => p.id));
      }
    });
  }

  void _removeFromWishlist(Product product) {
    widget.onToggleWishlist(product);
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
      _selected.remove(product.id);
      _selectedSizes.remove(product.id);
    });
  }

  // 선택된 상품 중 사이즈 미선택 항목 확인
  List<Product> get _selectedWithoutSize => _products
      .where((p) => _selected.contains(p.id) && _selectedSizes[p.id] == null)
      .toList();

  List<Product> get _selectedProducts =>
      _products.where((p) => _selected.contains(p.id)).toList();

  int get _selectedSubtotal =>
      _selectedProducts.fold(0, (sum, p) => sum + p.price);

  // 사이즈 선택 바텀시트
  Future<void> _showSizePicker(Product product) async {
    String? picked = _selectedSizes[product.id];
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '사이즈를 선택해주세요',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.sizes.map((size) {
                  final sel = picked == size;
                  return GestureDetector(
                    onTap: () => setSS(() => picked = size),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? Colors.black : Colors.white,
                        border: Border.all(
                          color: sel ? Colors.black : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        size,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: picked == null
                      ? null
                      : () => Navigator.pop(ctx, picked),
                  child: Text(
                    picked == null ? '사이즈를 선택해주세요' : '선택 완료',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() => _selectedSizes[product.id] = picked);
    }
  }

  // 선택 상품 장바구니 담기
  void _addSelectedToCart() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품을 선택해주세요.')));
      return;
    }
    if (_selectedWithoutSize.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '사이즈를 선택해주세요: ${_selectedWithoutSize.map((p) => p.name).join(', ')}',
          ),
        ),
      );
      return;
    }
    for (final p in _selectedProducts) {
      widget.onAddToCart(p, _selectedSizes[p.id]!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedProducts.length}개 상품을 장바구니에 담았습니다.')),
    );
  }

  // 선택 상품 바로 결제
  void _checkoutSelected() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품을 선택해주세요.')));
      return;
    }
    if (_selectedWithoutSize.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '사이즈를 선택해주세요: ${_selectedWithoutSize.map((p) => p.name).join(', ')}',
          ),
        ),
      );
      return;
    }
    final items = _selectedProducts
        .map((p) => CartItem(product: p, size: _selectedSizes[p.id]!))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WishlistCheckoutScreen(
          items: items,
          onConfirm: () {
            for (final p in _selectedProducts) {
              widget.onAddToCart(p, _selectedSizes[p.id]!);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final shipping = (_selectedSubtotal == 0 || _selectedSubtotal >= 50000)
        ? 0
        : 3000;
    final total = _selectedSubtotal + shipping;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '찜한 상품 (${_products.length})',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '찜한 상품이 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '상품 카드의 ♡ 버튼으로 찜해보세요.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 전체선택 행
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSelectAll,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _allSelected
                                    ? Colors.black
                                    : Colors.white,
                                border: Border.all(
                                  color: _allSelected
                                      ? Colors.black
                                      : Colors.grey[400]!,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _allSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 15,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '전체선택 (${_selected.length}/${_products.length})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.black12),
                // 상품 목록
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 24, color: Colors.black12),
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      final isChecked = _selected.contains(p.id);
                      final chosenSize = _selectedSizes[p.id];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 체크박스
                          GestureDetector(
                            onTap: () => _toggleSelect(p.id),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, right: 12),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? Colors.black
                                      : Colors.white,
                                  border: Border.all(
                                    color: isChecked
                                        ? Colors.black
                                        : Colors.grey[400]!,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isChecked
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 15,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // 이미지
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.imageUrl,
                              width: 90,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 90,
                                height: 100,
                                color: Colors.grey[100],
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.brand,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatter.format(p.price)}원',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 사이즈 선택
                                GestureDetector(
                                  onTap: () => _showSizePicker(p),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: chosenSize != null
                                            ? Colors.black
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          chosenSize ?? '사이즈 선택',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: chosenSize != null
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: chosenSize != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 찜 삭제 버튼
                          GestureDetector(
                            onTap: () => _removeFromWishlist(p),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // 하단 결제 영역
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 금액 요약
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '선택 상품금액',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${formatter.format(_selectedSubtotal)}원',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '배송비',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _selectedSubtotal == 0
                                  ? '-'
                                  : shipping == 0
                                  ? '무료'
                                  : '${formatter.format(shipping)}원',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '총 결제금액',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _selectedSubtotal == 0
                                  ? '0원'
                                  : '${formatter.format(total)}원',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 버튼 두 개: 장바구니 담기 | 바로 구매
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.black54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _addSelectedToCart,
                                child: const Text(
                                  '장바구니 담기',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _checkoutSelected,
                                child: const Text(
                                  '바로 구매',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// 💳 WishlistCheckoutScreen — 찜 목록 결제 화면
// ============================================================
class WishlistCheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final VoidCallback onConfirm;

  const WishlistCheckoutScreen({
    super.key,
    required this.items,
    required this.onConfirm,
  });

  @override
  State<WishlistCheckoutScreen> createState() => _WishlistCheckoutScreenState();
}

class _WishlistCheckoutScreenState extends State<WishlistCheckoutScreen> {
  // 배송 방법
  String _deliveryMethod = '일반배송';

  // 결제 수단
  String _payMethod = '신용카드';

  bool _agreed = false;

  final List<String> _payMethods = ['신용카드', '카카오페이', '네이버페이', '무통장입금'];

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final subtotal = widget.items.fold<int>(
      0,
      (sum, item) => sum + item.product.price * item.quantity,
    );
    final shipping = subtotal >= 50000 ? 0 : 3000;
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '주문/결제',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 주문 상품 ──
          _sectionTitle('주문 상품 (${widget.items.length}개)'),
          const SizedBox(height: 12),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '사이즈: ${item.size} / 수량: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatter.format(item.product.price * item.quantity)}원',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 32, color: Colors.black12),

          // ── 배송 정보 ──
          _sectionTitle('배송 정보'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '배송지를 선택해주세요',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeliveryAddressScreen(),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '+ 배송지 선택/추가',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 배송 방법
          Row(
            children: ['일반배송', '빠른배송'].map((method) {
              final sel = _deliveryMethod == method;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _deliveryMethod = method),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? Colors.black : Colors.white,
                      border: Border.all(
                        color: sel ? Colors.black : Colors.black26,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      method,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Divider(height: 32, color: Colors.black12),

          // ── 결제 수단 ──
          _sectionTitle('결제 수단'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _payMethods.map((method) {
              final sel = _payMethod == method;
              return GestureDetector(
                onTap: () => setState(() => _payMethod = method),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? Colors.black : Colors.white,
                    border: Border.all(
                      color: sel ? Colors.black : Colors.black26,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    method,
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Divider(height: 32, color: Colors.black12),

          // ── 금액 ──
          _sectionTitle('결제 금액'),
          const SizedBox(height: 12),
          _checkoutRow('상품금액', '${formatter.format(subtotal)}원'),
          const SizedBox(height: 8),
          _checkoutRow(
            '배송비',
            shipping == 0 ? '무료' : '${formatter.format(shipping)}원',
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 결제금액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${formatter.format(total)}원',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 동의 ──
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _agreed ? Colors.black : Colors.white,
                    border: Border.all(
                      color: _agreed ? Colors.black : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _agreed
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '주문 내용을 확인했으며, 구매에 동의합니다.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── 결제하기 버튼 ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreed ? Colors.black : Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _agreed
                  ? () {
                      widget.onConfirm();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AlertDialog(
                          title: const Text('주문 완료 🎉'),
                          content: Text(
                            '${formatter.format(total)}원 결제가 완료되었습니다.\n($_payMethod / $_deliveryMethod)',
                          ),
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                  ..pop()
                                  ..pop()
                                  ..pop();
                              },
                              child: const Text(
                                '확인',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              child: Text(
                '${formatter.format(total)}원 결제하기',
                style: TextStyle(
                  color: _agreed ? Colors.white : Colors.grey[500],
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _checkoutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// ============================================================
// 📦 OrderListScreen — 주문/배송 조회
// ============================================================
class OrderListScreen extends StatefulWidget {
  final String token;
  const OrderListScreen({super.key, required this.token});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _loading = true;
  List<dynamic> _orders = [];

  static const _steps = ['주문접수', '결제완료', '배송준비중', '배송중', '배송완료'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/orders'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        setState(() => _orders = jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('주문/배송 조회', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('주문 내역이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.black,
                  onRefresh: _fetch,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _orderCard(_orders[i]),
                  ),
                ),
    );
  }

  Widget _orderCard(dynamic order) {
    final formatter = NumberFormat('#,###');
    final statusInfo = order['status_info'] as Map<String, dynamic>;
    final step = statusInfo['step'] as int;
    final label = statusInfo['label'] as String;
    final items = order['items'] as List<dynamic>;
    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();

    final statusColor = step == 4
        ? Colors.green
        : step == 3
            ? Colors.blue
            : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(createdAt),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          // 상품 목록
          ...items.map((item) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item['image_url'] ?? '',
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56, color: Colors.grey[100],
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${item['size']}  ·  ${item['quantity']}개', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${formatter.format(item['price'])}원', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.black12),

          // 배송 타임라인
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('배송 현황', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_steps.length, (i) {
                    final done = i <= step;
                    final active = i == step;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: done ? Colors.black : Colors.grey[200],
                                    border: Border.all(color: done ? Colors.black : Colors.grey[300]!),
                                  ),
                                  child: active
                                      ? const Icon(Icons.circle, color: Colors.white, size: 8)
                                      : done
                                          ? const Icon(Icons.check, color: Colors.white, size: 11)
                                          : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _steps[i],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: done ? Colors.black : Colors.grey,
                                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (i < _steps.length - 1)
                            Container(
                              height: 1,
                              width: 12,
                              color: i < step ? Colors.black : Colors.grey[300],
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // 합계
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 결제금액', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Text(
                  '${formatter.format((order['total_price'] ?? 0) + (order['shipping'] ?? 0))}원',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🔔 NotificationSettingsScreen — 알림 설정
// ============================================================
class NotificationSettingsScreen extends StatefulWidget {
  final String token;
  const NotificationSettingsScreen({super.key, required this.token});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _weatherAlert = true;
  bool _styleTips = true;
  bool _orderUpdates = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/notifications/settings'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _weatherAlert  = (data['weather_alert']  ?? 1) == 1;
          _styleTips     = (data['style_tips']      ?? 1) == 1;
          _orderUpdates  = (data['order_updates']   ?? 1) == 1;
          _promotions    = (data['promotions']      ?? 0) == 1;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/notifications/settings'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'weather_alert': _weatherAlert,
          'style_tips': _styleTips,
          'order_updates': _orderUpdates,
          'promotions': _promotions,
        }),
      );
    } catch (_) {}
  }

  Widget _tile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          setState(() => onChanged(v));
          _save();
        },
        activeColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('알림 설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('날씨 알림', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                _tile(Icons.wb_sunny_outlined, '날씨 알림', '오늘의 날씨 변화를 알려드립니다', _weatherAlert, (v) => _weatherAlert = v),
                _tile(Icons.style_outlined, '스타일 팁', '날씨에 맞는 스타일 추천을 받아보세요', _styleTips, (v) => _styleTips = v),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 24),
                const Text('쇼핑 알림', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                _tile(Icons.local_shipping_outlined, '주문·배송 알림', '주문 상태 변경 시 알려드립니다', _orderUpdates, (v) => _orderUpdates = v),
                _tile(Icons.campaign_outlined, '이벤트·프로모션', '특가 혜택 및 이벤트 소식을 알려드립니다', _promotions, (v) => _promotions = v),
              ],
            ),
    );
  }
}
