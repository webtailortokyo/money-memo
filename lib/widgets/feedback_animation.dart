import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/money_type.dart';
import '../widgets/piggy_character.dart';

class FeedbackAnimation extends StatefulWidget {
  final MoneyType type;
  final double size;
  final VoidCallback onComplete;

  const FeedbackAnimation({
    super.key,
    required this.type,
    required this.size,
    required this.onComplete,
  });

  @override
  State<FeedbackAnimation> createState() => _FeedbackAnimationState();
}

class _FeedbackAnimationState extends State<FeedbackAnimation> with TickerProviderStateMixin {
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncrease = widget.type == MoneyType.increase;
    final isMemo = widget.type == MoneyType.memo;
    final screenHeight = MediaQuery.of(context).size.height;

    String lottieFile;
    if (isIncrease) {
      lottieFile = 'assets/lottie/increase.json';
    } else if (isMemo) {
      lottieFile = 'assets/lottie/sparkle_stars.json';
    } else {
      lottieFile = 'assets/lottie/decrease.json';
    }

    final lottieWidget = Lottie.asset(
      lottieFile,
      controller: _lottieController,
      width: (isIncrease || isMemo) ? widget.size * 1.5 : widget.size,
      height: (isIncrease || isMemo) ? widget.size * 1.5 : widget.size,
      onLoaded: (composition) {
        if (isMemo) {
          // メモの場合は「最初と最後を削った1.5秒」にする
          // 元のアニメーションの0.1から0.9までを1.5秒かけて再生
          _lottieController.duration = const Duration(milliseconds: 1500);
          _lottieController.value = 0.1;
          _lottieController.animateTo(0.9).then((_) {
            if (mounted) widget.onComplete();
          });
        } else {
          // それ以外は通常再生 (durationをcompositionに合わせて、少し長めに待つ)
          _lottieController.duration = composition.duration;
          _lottieController.forward().then((_) {
             // 少し余韻を残してから閉じる
             Future.delayed(composition.duration * 0.2, () {
               if (mounted) widget.onComplete();
             });
          });
        }
      },
    );

    Widget imageWidget;
    if (isMemo) {
      // メモの場合は執筆中のLottieを表示
      imageWidget = Lottie.asset(
        'assets/lottie/writing.json',
        width: widget.size * 1.2,
        height: widget.size * 1.2,
        repeat: true,
      );
    } else {
      imageWidget = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: screenHeight, end: 0),
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: child,
          );
        },
        child: isIncrease
            ? Padding(
                padding: const EdgeInsets.only(top: 150),
                child: SvgPicture.asset(
                  'assets/img/piggy_bank.svg',
                  width: widget.size * 0.7,
                ),
              )
            : PiggyCharacter(
                width: widget.size * 0.7,
                pose: PiggyPose.joy,
                eyes: PiggyEyes.smile,
                isBlinking: true,
              ),
      );
    }

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: (isIncrease || isMemo)
            ? Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  lottieWidget,
                  imageWidget,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  lottieWidget,
                  imageWidget,
                ],
              ),
      ),
    );
  }
}
