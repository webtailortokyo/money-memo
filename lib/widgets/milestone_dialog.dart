import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  static Future<void> show(
    BuildContext context, {
    required String message,
    PiggyPose pose = PiggyPose.joy,
    PiggyEyes eyes = PiggyEyes.smile,
    PiggyMouth mouth = PiggyMouth.normal,
    String lottieAsset = 'assets/lottie/confetti.json',
    MilestoneAnimationType? animationType,
  }) {
    final types = MilestoneAnimationType.values.where((t) => t != MilestoneAnimationType.none).toList();
    final selectedType = animationType ?? types[Random().nextInt(types.length)];

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: const Color(0xFFFFFBF0), // 完全に不透明なクリーム色の背景
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) => MilestoneDialog(
        message: message,
        pose: pose,
        eyes: eyes,
        mouth: mouth,
        lottieAsset: lottieAsset,
        animationType: selectedType,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }
}

class _MilestoneDialogState extends State<MilestoneDialog> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _idleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _idleFloatAnimation;
  late Animation<double> _idleTiltAnimation;

  PiggyPose _currentPose = PiggyPose.joy;

  @override
  void initState() {
    super.initState();
    _currentPose = widget.pose;
    
    // 登場アニメーション用コントローラー
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );

    // スピン登場：2回転しながら登場
    _rotationAnimation = Tween<double>(begin: -4 * pi, end: 0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(-2, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    // アイドルアニメーション用コントローラー（継続的な動き）
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _idleFloatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOutSine),
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _idleController.reverse();
        else if (status == AnimationStatus.dismissed) _idleController.forward();
      });

    _idleTiltAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward().then((_) {
      _idleController.forward();
    });

    if (widget.animationType == MilestoneAnimationType.dance) {
      _startDance();
    }
  }

  void _startDance() async {
    final poses = [PiggyPose.basic, PiggyPose.joy, PiggyPose.think];
    int count = 0;
    while (mounted && count < 6) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _currentPose = poses[count % poses.length];
      });
      count++;
    }
    if (mounted) setState(() => _currentPose = widget.pose);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背面のLottie演出
          Center(
            child: IgnorePointer(
              child: Lottie.asset(
                widget.lottieAsset,
                width: screenWidth,
                repeat: true,
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. ぶたさん（揺れる）
                AnimatedBuilder(
                  animation: _idleController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _idleFloatAnimation.value),
                      child: Transform.rotate(
                        angle: _idleTiltAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildAnimatedCharacter(),
                ),
                
                // 2. メッセージボックス（四角・固定）
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.mainText,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              AppStrings.closeButtonText,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
          animation: _entranceController,
          builder: (context, child) => Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
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
          animation: _entranceController,
          builder: (context, child) {
            final double bounce = sin(_entranceController.value * pi * 4) * 30;
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
        return ScaleTransition(
          scale: _scaleAnimation,
          child: character,
        );
    }
  }
}

