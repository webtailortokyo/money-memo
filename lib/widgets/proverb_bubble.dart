import 'package:flutter/material.dart';
import '../utils/proverbs.dart';
import '../theme.dart';
import '../app_state.dart';

class ProverbBubble extends StatelessWidget {
  const ProverbBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12), // 全体を少し上へ移動してブタに近づける
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側面の上下中央より少し上に配置するくるりとしたしっぽ
            Padding(
              padding: const EdgeInsets.only(top: 16.0), // 上下中央より少し上
              child: CustomPaint(
                size: const Size(20, 24),
                painter: _CurlyTailPainter(
                  color: context.appColors.sectionBg,
                ),
              ),
            ),
            // 吹き出しの本体
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: context.appColors.sectionBg,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: languageNotifier,
                        builder: (context, _, __) {
                          // languageNotifierが変更されたらことわざも再取得される
                          final proverb = Proverbs.getDailyProverb();
                          return Text(
                            proverb,
                            style: TextStyle(
                              color: context.appColors.mainText,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurlyTailPainter extends CustomPainter {
  final Color color;

  _CurlyTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // 右端（吹き出し本体にくっつく部分）からスタート
    path.moveTo(size.width, size.height * 0.6);
    
    // ブタのしっぽのようにくるっと一回転するループを描く
    // P0: (w, h*0.6)
    // P1: (w*0.1, h*1.1) 左下へ
    // P2: (w*-0.2, h*0.1) 左上へ
    // P3: (w*0.7, h*0.2) 右上へ（ループの頂点）
    path.cubicTo(
      size.width * 0.1, size.height * 1.1, 
      -size.width * 0.2, size.height * 0.1, 
      size.width * 0.7, size.height * 0.2
    );
    
    // P3: (w*0.7, h*0.2)
    // P4: (w*0.8, h*0.7) ループの内側を通って右下へ
    // P5: (-size.width * 0.3, -size.height * 0.3) 最後に左上（ブタさんの方向）へピンと跳ねる
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.7, 
      -size.width * 0.3, -size.height * 0.3
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
