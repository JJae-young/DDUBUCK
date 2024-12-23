import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:test2/function/community/Infopage.dart';
import 'package:test2/function/reward/BadgePage.dart';
import 'package:test2/sub_page.dart';
import 'package:test2/function/record/record_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '뚜벅뚜벅',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? _weatherDescription;
  double? _temperature;
  String? _locationName;
  String? _weatherIcon;
  double? _yesterdayTemp;
  LocationData? _locationData;

  double _weeklyGoal = 10.0;
  double _totalDistanceWalked = 0.0;
  late SharedPreferences _prefs;

  Location _location = Location(); // Location instance for tracking distance
  double _lastLatitude = 0.0;
  double _lastLongitude = 0.0;

  List<Map<String, String>> _quotes = [
    {"quote": "걷기는 가장 순수한 형태의 운동이다.", "author": "조지 마시"},
    {"quote": "목적 없이 산책할 때, 인생의 진정한 의미를 찾을 수 있다.", "author": "데이비드 소로우"},
    {"quote": "산책은 모든 문제를 해결할 수 있는 최고의 약이다.", "author": "톰 도브란스키"},
    {"quote": "걷기는 내게 가장 자유롭고 자연스러운 것이다.", "author": "헨리 데이비드 소로우"},
    {"quote": "한 걸음 한 걸음 걸으면서, 우리는 우리의 영혼에 더 가까이 다가간다.", "author": "나다니엘 호손"},
    {"quote": "길을 걸을 때는 모든 것을 다시 시작할 수 있다.", "author": "르네 샤르"},
    {"quote": "세상에 아무리 힘든 일이 있더라도 걸을 수 있으면 모든 것을 이겨낼 수 있다.", "author": "프리드리히 니체"},
    {"quote": "걷는다는 것은 내 영혼이 내 발걸음을 따라가는 것과 같다.", "author": "메리 올리버"},
    {"quote": "걷기는 언제나 우리의 마음을 평화롭게 만들어준다.", "author": "잭 커루악"},
    {"quote": "어느 길이든 우리가 선택한 길을 걸어갈 때마다 우리는 우리 자신을 발견하게 된다.", "author": "파울로 코엘료"},
    {"quote": "걷기는 생각의 여정을 통해 우리를 인도하는 것이다.", "author": "조지프 브로디"},
    {"quote": "도보는 가장 오래된 명상이며, 가장 새로운 여행이다.", "author": "로버트 맥팔레인"},
    {"quote": "느리게 걷는 사람은 더 많은 것을 본다.", "author": "캐서린 메이"},
    {"quote": "자연 속에서 걷다 보면, 문제들은 사라지고 새로운 길이 보인다.", "author": "존 뮤어"},
    {"quote": "걷기는 일상 속의 영감을 불러일으키는 힘이 있다.", "author": "줄리아 카메론"},
    {"quote": "하루에 한 시간씩 걷는 사람은 평생 동안 젊음을 유지할 것이다.", "author": "찰스 디킨스"},
    {"quote": "하루를 즐겁게 만드는 것은 천천히 걷는 것에 있다.", "author": "제프 미키"},
    {"quote": "생각은 걸으면서 가장 명확해진다.", "author": "프리드리히 니체"},
    {"quote": "걷기는 목적이 아니라 방법이다.", "author": "필립 커프맨"},
    {"quote": "걷는 사람은 천천히, 그리고 더 많은 것을 발견한다.", "author": "헨리 데이비드 소로우"}
  ];
  String _currentQuote = "";
  String _currentAuthor = "";

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();

    _fetchWeather();
    _getRandomQuote();
    _loadWeeklyGoal();
    _loadTotalDistanceWalked();

    // 거리 추적을 시작하는 부분
    _startTrackingDistance();
  }

  Future<void> _fetchWeather() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    if (_locationData != null) {
      double lat = _locationData!.latitude!;
      double lon = _locationData!.longitude!;

      String apiKey = 'b7ac9ed2a153ac22d5dfe22ad3c114d3';
      String url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=kr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var weatherData = json.decode(response.body);

        setState(() {
          _locationName = weatherData['name'];
          _weatherDescription = weatherData['weather'][0]['description'];
          _temperature = weatherData['main']['temp'];
          _weatherIcon = weatherData['weather'][0]['icon'];
        });
      }
    }
  }

  void _getRandomQuote() {
    final random = Random();
    int index = random.nextInt(_quotes.length);
    setState(() {
      _currentQuote = _quotes[index]["quote"]!;
      _currentAuthor = _quotes[index]["author"]!;
    });
  }

  Future<void> _loadWeeklyGoal() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _weeklyGoal = _prefs.getDouble('weeklyGoal') ?? 10.0;
    });
  }

  Future<void> _loadTotalDistanceWalked() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalDistanceWalked = _prefs.getDouble('totalDistanceWalked') ?? 0.0;
    });
  }

  Future<void> _saveWeeklyGoal(double newGoal) async {
    await _prefs.setDouble('weeklyGoal', newGoal);
    setState(() {
      _weeklyGoal = newGoal;
    });
  }

  Future<void> _saveTotalDistanceWalked(double distance) async {
    await _prefs.setDouble('totalDistanceWalked', distance);
    setState(() {
      _totalDistanceWalked = distance;
    });
  }

  // 주기적으로 위치를 확인하고 걸은 거리를 계산하는 함수
  Future<void> _startTrackingDistance() async {
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_lastLatitude != 0.0 && _lastLongitude != 0.0) {
        // 두 지점 사이의 거리를 계산
        double distance = _calculateDistance(
          _lastLatitude,
          _lastLongitude,
          currentLocation.latitude!,
          currentLocation.longitude!,
        );

        // 총 걸은 거리에 추가
        setState(() {
          _totalDistanceWalked += distance;
        });

        // SharedPreferences에 업데이트된 거리 저장
        _saveTotalDistanceWalked(_totalDistanceWalked);
      }

      // 현재 위치를 저장해 다음 거리 계산에 사용
      _lastLatitude = currentLocation.latitude!;
      _lastLongitude = currentLocation.longitude!;
    });
  }

  // 두 위치 사이의 거리를 계산하는 함수 (Haversine formula 사용)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // 지구의 반경 (km)
    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) * cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  void _showGoalDialog() {
    final TextEditingController controller =
    TextEditingController(text: _weeklyGoal.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('주간 목표 설정'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: '주간 목표 거리 (km)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                double newGoal =
                    double.tryParse(controller.text) ?? _weeklyGoal;
                _saveWeeklyGoal(newGoal);
                Navigator.of(context).pop();
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 네비게이션 바에 따른 페이지 구성을 위한 메소드
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return SubPage();
      case 1:
        return RecordPage();
      case 2:
        return _buildMainTtubuck();
      case 3:
        return Infopage();
      case 4:
        return BadgePage();
      default:
        return SubPage();
    }
  }

  // 메인뚜벅 화면을 구성하는 메소드
  Widget _buildMainTtubuck() {
    return SafeArea(
      child: _currentUser == null
          ? _buildSignInPrompt()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              SizedBox(height: 30),
              WeatherWidget(
                location: _locationName ?? '위치 정보 없음',
                date: "1월 3일 수요일",
                time: "12:41",
                weatherDescription: _weatherDescription ?? '날씨 정보 없음',
                currentTemp: _temperature ?? 0.0,
                yesterdayTemp: _yesterdayTemp ?? 0.0,
                weatherIcon: _weatherIcon ?? '01d',
              ),
              SizedBox(height: 30),
              _buildGoalProgressSection(),
              SizedBox(height: 30),
              _buildQuoteSection(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GoogleUserCircleAvatar(identity: _currentUser!),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.displayName ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
              tooltip: '로그아웃',
            ),
          ],
        ),
      ),
    );
  }

  // 주간 목표 진행률 섹션
  Widget _buildGoalProgressSection() {
    double progress = _totalDistanceWalked / _weeklyGoal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "주간 목표",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
              minHeight: 10,
            ),
            SizedBox(height: 8),
            Text(
              "${(progress * 100).toStringAsFixed(1)}% 달성",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("걸은 거리: ${_totalDistanceWalked.toStringAsFixed(2)} km"),
                Text("목표 거리: $_weeklyGoal km"),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showGoalDialog,
              child: Text("목표 수정"),
            ),
          ],
        ),
      ),
    );
  }

  // 명언 섹션
  Widget _buildQuoteSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "\"$_currentQuote\"",
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 8),
            Text(
              "- $_currentAuthor",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 유도 화면
  Widget _buildSignInPrompt() {
    return Center(
      child: GestureDetector(
        onTap: _handleSignIn,
        child: Image.asset(
          'assets/login.png',
          width: 500,
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('구글 로그인 실패: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: _currentUser != null // 사용자가 로그인된 상태일 때만 네비게이션 바 표시
          ? BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: '뚜벅뚜벅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '뚜벅기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '메인뚜벅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: '뚜벅정보',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: '뚜벅배지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      )
          : null, // 사용자가 로그인되지 않았으면 네비게이션 바를 숨김
    );
  }
}

// 날씨 위젯 컴포넌트
class WeatherWidget extends StatelessWidget {
  final String location;
  final String date;
  final String time;
  final String weatherDescription;
  final double currentTemp;
  final double yesterdayTemp;
  final String weatherIcon;

  WeatherWidget({
    required this.location,
    required this.date,
    required this.time,
    required this.weatherDescription,
    required this.currentTemp,
    required this.yesterdayTemp,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[700]),
                    SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Image.network(
                      'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                      width: 80,
                      height: 80,
                    ),
                    SizedBox(height: 8),
                    Text(
                      weatherDescription,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${currentTemp.toInt()}°',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
