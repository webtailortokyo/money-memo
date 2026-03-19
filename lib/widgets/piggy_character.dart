import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PiggyPose { basic, joy, think }

enum PiggyEyes { dot, smile, closed, shocked }

enum PiggyMouth { normal, shocked }

enum PiggyAccessory { none, question }

class PiggyCharacter extends StatefulWidget {
  final double width;
  final PiggyPose pose;
  final PiggyEyes eyes;
  final PiggyMouth mouth;
  final PiggyAccessory accessory;
  final bool isBlinking;

  const PiggyCharacter({
    super.key,
    required this.width,
    this.pose = PiggyPose.basic,
    this.eyes = PiggyEyes.dot,
    this.mouth = PiggyMouth.normal,
    this.accessory = PiggyAccessory.none,
    this.isBlinking = false,
  });

  @override
  State<PiggyCharacter> createState() => _PiggyCharacterState();
}

class _PiggyCharacterState extends State<PiggyCharacter> {
  bool _isEyeClosedLocal = false;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isBlinking) {
      _startBlinking();
    }
  }

  @override
  void didUpdateWidget(PiggyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking != oldWidget.isBlinking) {
      if (widget.isBlinking) {
        _startBlinking();
      } else {
        _blinkTimer?.cancel();
        setState(() => _isEyeClosedLocal = false);
      }
    }
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!mounted) return;
      setState(() => _isEyeClosedLocal = true);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _isEyeClosedLocal = false);
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  String _getPosePath() {
    switch (widget.pose) {
      case PiggyPose.basic:
        return 'assets/img/body_basic.svg';
      case PiggyPose.joy:
        return 'assets/img/body_joy.svg';
      case PiggyPose.think:
        return 'assets/img/body_think.svg';
    }
  }

  String _getEyesPath() {
    if (_isEyeClosedLocal && widget.eyes != PiggyEyes.shocked) {
      return 'assets/img/eye_closed.svg';
    }
    switch (widget.eyes) {
      case PiggyEyes.dot:
        return 'assets/img/eye_dot.svg';
      case PiggyEyes.smile:
        return 'assets/img/eye_smile.svg';
      case PiggyEyes.closed:
        return 'assets/img/eye_closed.svg';
      case PiggyEyes.shocked:
        return 'assets/img/eye_shocked.svg';
    }
  }

  String _getMouthPath() {
    switch (widget.mouth) {
      case PiggyMouth.normal:
        return 'assets/img/mouth_normal.svg';
      case PiggyMouth.shocked:
        return 'assets/img/mouth_shocked.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 全てのパーツは 792 x 915 のアスペクト比を持つ
    const double baseWidth = 792.0;
    const double baseHeight = 915.0;
    final double height = widget.width * (baseHeight / baseWidth);

    return SizedBox(
      width: widget.width,
      height: height,
      child: Stack(
        children: [
          // 1. 体
          SvgPicture.asset(
            _getPosePath(),
            width: widget.width,
            height: height,
          ),
          // 2. 口
          SvgPicture.asset(
            _getMouthPath(),
            width: widget.width,
            height: height,
          ),
          // 3. 目
          SvgPicture.asset(
            _getEyesPath(),
            width: widget.width,
            height: height,
          ),
          // 4. アクセサリー
          if (widget.accessory == PiggyAccessory.question)
            SvgPicture.asset(
              'assets/img/acc_question.svg',
              width: widget.width,
              height: height,
            ),
        ],
      ),
    );
  }
}
