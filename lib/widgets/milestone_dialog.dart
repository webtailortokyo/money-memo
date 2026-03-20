import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/piggy_character.dart';
import '../theme.dart';
import '../constants.dart';

enum MilestoneAnimationType {
  none,
  spin,    // 回転して登場
  slide,   // 横からスライド
  bounce,  // ぴょんぴょん跳ねる
  dance,   // ポーズを次々に切り替える
}

class MilestoneDialog extends StatefulWidget {
  final String message;
  final PiggyPose pose;
  final PiggyEyes eyes;
  final PiggyMouth mouth;
  final String lottieAsset;
  final MilestoneAnimationType animationType;

  const MilestoneDialog({
    super.key,
    required this.message,
    this.pose = PiggyPose.joy,
    this.eyes = PiggyEyes.smile,
    this.mouth = PiggyMouth.normal,
    this.lottieAsset = 'assets/lottie/confetti.json',
    this.animationType = MilestoneAnimationType.none,
  });

  @override
  State<MilestoneDialog> createState() => _MilestoneDialogState();

  // 表示用 static メソッド
  static Future<void> show(
    BuildContext context, {
    required String message,
    PiggyPose pose = PiggyPose.joy,
    PiggyEyes eyes = PiggyEyes.smile,
    PiggyMouth mouth = PiggyMouth.normal,
    String lottieAsset = 'assets/lottie/confetti.json',
    MilestoneAnimationType? animationType,
  }) {
    // アニメーションタイプが指定されていない場合はランダムに選択（none以外）
    final types = MilestoneAnimationType.values.where((t) => t != MilestoneAnimationType.none).toList();
    final selectedType = animationType ?? types[Random().nextInt(types.length)];

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => MilestoneDialog(
        message: message,
        pose: pose,
        eyes: eyes,
        mouth: mouth,
        lottieAsset: lottieAsset,
        animationType: selectedType,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}

class _MilestoneDialogState extends State<MilestoneDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _mainAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;

  PiggyPose _currentPose = PiggyPose.joy;

  @override
  void initState() {
    super.initState();
    _currentPose = widget.pose;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _mainAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_mainAnimation);
    _slideAnimation = Tween<Offset>(begin: const Offset(-2, 0), end: Offset.zero).animate(_mainAnimation);

    _controller.forward();

    // danceアニメーションの場合はポーズを切り替える
    if (widget.animationType == MilestoneAnimationType.dance) {
      _startDance();
    }
  }

  void _startDance() async {
    final poses = [PiggyPose.basic, PiggyPose.joy, PiggyPose.think];
    int count = 0;
    while (mounted && count < 6) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _currentPose = poses[count % poses.length];
      });
      count++;
    }
    // 最後は元のポーズに戻す
    if (mounted) setState(() => _currentPose = widget.pose);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85 > 400.0 ? 400.0 : screenWidth * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 背景の白いカード
          Container(
            width: dialogWidth,
            padding: const EdgeInsets.fromLTRB(24, 140, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'とじる',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Lottieアニメーション（前面）
          Positioned(
            top: -120,
            child: IgnorePointer(
              child: Lottie.asset(
                widget.lottieAsset,
                width: dialogWidth * 1.3,
                repeat: true,
              ),
            ),
          ),

          // キャラクター（上面）
          Positioned(
            top: -130,
            child: IgnorePointer(
              child: _buildAnimatedCharacter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCharacter() {
    final character = PiggyCharacter(
      width: 180,
      pose: _currentPose,
      eyes: widget.eyes,
      mouth: widget.mouth,
      isBlinking: true,
    );

    switch (widget.animationType) {
      case MilestoneAnimationType.spin:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _mainAnimation.value,
              child: child,
            ),
          ),
          child: character,
        );
      case MilestoneAnimationType.slide:
        return SlideTransition(
          position: _slideAnimation,
          child: character,
        );
      case MilestoneAnimationType.bounce:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double bounce = sin(_controller.value * pi * 4) * 20; // 2回バウンド
            return Transform.translate(
              offset: Offset(0, bounce),
              child: child,
            );
          },
          child: character,
        );
      case MilestoneAnimationType.dance:
      case MilestoneAnimationType.none:
      default:
        return character;
    }
  }
}
