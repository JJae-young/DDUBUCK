import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Infopage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('뚜벅 정보'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 축제 정보
              Text(
                '축제 정보',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/festival1.png', '제주국제 걷기축제', 'https://playjeju.co.kr/bbs/board.php?bo_table=festival&wr_id=1101'),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/festival2.png', '제주올레 걷기축제', 'https://contents.ollepass.org/static/festival_view/2024/01/index.html?name=festival'),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/festival3.png', '남해바래길 걷기축제', 'https://namhaetour.org/01254/01255.web?gcode=1,001&idx=714&amode=view&'),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/festival4.png', '거제 파노라마 단풍 레이스', 'https://danpoongrace.modoo.at/'),
              SizedBox(height: 30),
              // 마라톤 정보
              Text(
                '마라톤 정보',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/marathon1.png', '정서진 아라뱃길 전국 마라톤 대회', 'http://www.jeongseojin.co.kr/'),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/marathon2.png', '서울 라이프 마라톤 대회', 'https://lifemarathon.co.kr/'),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/marathon3.png', '여의도 밤섬 마라톤 대회', 'http://bamseom.com/'),
              SizedBox(height: 10),
              _buildImageCard(
                  'assets/marathon4.png', '서울 시즌 오프 레이스', 'http://www.irunman.kr/'),
            ],
          ),
        ),
      ),
    );
  }

  // 이미지 카드를 만드는 함수
  Widget _buildImageCard(String imagePath, String description, String url) {
    return GestureDetector(
      onTap: () => _launchURL(url), // 이미지 클릭 시 해당 URL로 이동
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 부분
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                imagePath,
                width: double.infinity, // 페이지 너비에 맞추기
                height: 200, // 이미지 높이
                fit: BoxFit.cover, // 이미지를 컨테이너 크기에 맞춰 비율 유지하며 변형
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // URL을 여는 함수 (외부 브라우저에서 열리도록 수정)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // 외부 브라우저에서 열리도록 명시
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
