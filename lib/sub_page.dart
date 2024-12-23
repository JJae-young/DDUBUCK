import 'package:flutter/material.dart';
import 'package:test2/function/ddubuck/ddubuck_1/ddubuck.dart'; // DdubuckMapScreen 경로
import 'package:test2/function/ddubuck/ddubuck_cctv/ddubuck_cctv.dart'; // CCTVMapScreen 경로
import 'package:test2/function/ddubuck/ddubuck_ii/ddubuck_ii.dart'; // DdubuckMapii 경로
import 'package:test2/function/ddubuck/ddubuck_cctv/cctv_test.dart'; // CCTVMapScreen 경로

class SubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'), // 배경 이미지 경로
                fit: BoxFit.cover, // 이미지가 화면 크기에 맞게 조정됨
              ),
            ),
          ),
          // 내용 레이아웃
          Padding(
            padding: const EdgeInsets.all(8.0), // 여백 최소화
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 버튼을 화면 가로로 꽉 채움
              children: [
                SizedBox(height: 50),
                _buildCourseCard(
                  context,
                  '일단뚜벅',
                  '길을 직접 개척하는 뚜벅',
                  Icons.directions_walk,
                  DdubuckMapii(),
                ),
                const SizedBox(height: 8),
                _buildCourseCard(
                  context,
                  '뚜벅뚜벅',
                  '코스를 정하지 못하는 당신을 위한 뚜벅',
                  Icons.shuffle,
                  DdubuckMapScreen(),
                ),
                const SizedBox(height: 8),
                _buildCourseCard(
                  context,
                  '안전뚜벅',
                  'CCTV를 활용한 안전한 코스를 위한 뚜벅',
                  Icons.security,
                  CCTVMapScreen(),
                ),
                const SizedBox(height: 8),
                _buildCourseCard(
                  context,
                  '애완뚜벅 (미구현)',
                  '',
                  Icons.pets,
                  CCTVMap(), // 미구현된 기능이므로 페이지 없음
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 코스 카드를 빌드하는 함수
  Widget _buildCourseCard(BuildContext context, String title, String description, IconData icon, Widget? page) {
    return Card(
      elevation: 4, // 카드에 그림자 효과 추가
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 모서리 둥글게
      child: InkWell( // 카드 전체에 클릭 효과 추가
        onTap: page != null
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
            : null, // 페이지가 없으면 탭 불가
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 카드 내부 여백
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor), // 아이콘
              const SizedBox(width: 16), // 아이콘과 텍스트 사이 간격
              Expanded( // 텍스트 부분을 확장해 화면을 꽉 채움
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4), // 타이틀과 설명 사이 간격
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600], // 설명 텍스트 색상
                      ),
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
}
