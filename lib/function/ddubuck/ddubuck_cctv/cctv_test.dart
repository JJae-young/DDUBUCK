import 'package:flutter/material.dart';

class CCTVMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              "현재 점검중입니다.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "더 나은 서비스로 찾아뵙겠습니다.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: CCTVMap()));
