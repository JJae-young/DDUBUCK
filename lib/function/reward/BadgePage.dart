import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgePage extends StatefulWidget {
  @override
  _BadgePageState createState() => _BadgePageState();
}

class _BadgePageState extends State<BadgePage> {
  double totalDistanceWalked = 0.0;
  int _totalLoginDays = 0;

  @override
  void initState() {
    super.initState();
    _loadBadgeStatus();
    _loadLoginDays();
    _checkLogin();
  }

  Future<void> _loadBadgeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      totalDistanceWalked = prefs.getDouble('totalDistanceWalked') ?? 0.0;
    });
  }

  Future<void> _loadLoginDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalLoginDays = prefs.getInt('totalLoginDays') ?? 0;
    });
  }

  void _checkLogin() async {
    DateTime now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastLoginDateStr = prefs.getString('lastLoginDate') ?? '';
    DateTime? lastLoginDate = lastLoginDateStr.isNotEmpty ? DateTime.tryParse(lastLoginDateStr) : null;

    if (lastLoginDate == null || now.difference(lastLoginDate).inDays >= 1) {
      setState(() {
        _totalLoginDays += 1;
      });
      prefs.setInt('totalLoginDays', _totalLoginDays);
      prefs.setString('lastLoginDate', now.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAttendanceBadgeSection('출석 배지', '출석', _totalLoginDays.toDouble(), [1, 3, 4, 7, 60, 100], assetPrefix: 'attend'),
              SizedBox(height: 16),
              _buildWalkingBadgeSection('도보 배지', '도보', totalDistanceWalked, [0, 1, 3, 30, 80, 100], assetPrefix: 'crown'),
            ],
          ),
        ),
      ),
    );
  }

  // 출석 배지
  Widget _buildAttendanceBadgeSection(String title, String type, double currentValue, List<int> thresholds, {required String assetPrefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 12),
        Column(
          children: thresholds.asMap().entries.map((entry) {
            int index = entry.key;
            int threshold = entry.value;
            bool isBadgeEarned = currentValue >= threshold;

            String iconPath = isBadgeEarned ? 'assets/${assetPrefix}${index + 1}.jpg' : 'assets/question.png';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: 645,
                height: 165,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isBadgeEarned ? Colors.blue : Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    iconPath,
                    width: 645,
                    height: 165,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildWalkingBadgeSection(String title, String type, double currentValue, List<int> thresholds, {required String assetPrefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 한 줄에 3개씩 배치
            childAspectRatio: 1, // 정사각형 비율
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: thresholds.length,
          itemBuilder: (context, index) {
            int threshold = thresholds[index];
            bool isBadgeEarned = currentValue >= threshold;

            // 배지 아이콘 경로 설정
            String iconPath = isBadgeEarned ? 'assets/${assetPrefix}${index + 1}.jpg' : 'assets/question.png';

            return Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: isBadgeEarned
                      ? Image.asset(
                    iconPath,
                    fit: BoxFit.cover,
                  )
                      : Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (currentValue / threshold).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                      Image.asset(
                        iconPath,
                        width: 60,
                        height: 60,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$type ${threshold}${type == '도보' ? 'km' : '일'}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
