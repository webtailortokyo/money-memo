import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/piggy_character.dart';
import '../theme.dart';
import '../constants.dart';

enum MilestoneAnimationType {
  none,
  spin,    // 蝗櫁ｻ｢縺励※逋ｻ蝣ｴ
  slide,   // 讓ｪ縺九ｉ繧ｹ繝ｩ繧､繝・
  bounce,  // 縺ｴ繧・ｓ縺ｴ繧・ｓ霍ｳ縺ｭ繧・
  dance,   // 繝昴・繧ｺ繧呈ｬ｡縲・↓蛻・ｊ譖ｿ縺医ｋ
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

  // 陦ｨ遉ｺ逕ｨ static 繝｡繧ｽ繝・ラ
  static Future<void> show(
    BuildContext context, {
    required String message,
    PiggyPose pose = PiggyPose.joy,
    PiggyEyes eyes = PiggyEyes.smile,
    PiggyMouth mouth = PiggyMouth.normal,
    String lottieAsset = 'assets/lottie/confetti.json',
    MilestoneAnimationType? animationType,
  }) {
    // 繧｢繝九Γ繝ｼ繧ｷ繝ｧ繝ｳ繧ｿ繧､繝励′謖・ｮ壹＆繧後※縺・↑縺・ｴ蜷医・繝ｩ繝ｳ繝繝縺ｫ驕ｸ謚橸ｼ・one莉･螟厄ｼ・
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

    // dance繧｢繝九Γ繝ｼ繧ｷ繝ｧ繝ｳ縺ｮ蝣ｴ蜷医・繝昴・繧ｺ繧貞・繧頑崛縺医ｋ
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
    // 譛蠕後・蜈・・繝昴・繧ｺ縺ｫ謌ｻ縺・
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
          // 閭梧勹縺ｮ逋ｽ縺・き繝ｼ繝・
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.mainText,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppStrings.closeButtonText,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Lottie繧｢繝九Γ繝ｼ繧ｷ繝ｧ繝ｳ・亥燕髱｢・・
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

          // 繧ｭ繝｣繝ｩ繧ｯ繧ｿ繝ｼ・井ｸ企擇・・
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
            final double bounce = sin(_controller.value * pi * 4) * 20; // 2蝗槭ヰ繧ｦ繝ｳ繝・
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
