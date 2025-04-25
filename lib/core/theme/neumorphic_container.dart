import 'package:flutter/material.dart';
import 'colors.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool isPressed;
  final BorderRadius borderRadius;
  final Color? color;

  const NeumorphicContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.isPressed = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      constraints: const BoxConstraints(),
      decoration: BoxDecoration(
        color: color ?? AppColors.background,
        borderRadius: borderRadius,
        boxShadow:
            isPressed
                ? [
                  BoxShadow(
                    color: AppColors.shadowDark.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: AppColors.shadowLight,
                    offset: Offset(-2, -2),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ]
                : [
                  BoxShadow(
                    color: AppColors.shadowDark.withOpacity(0.5),
                    offset: const Offset(5, 5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: AppColors.shadowLight,
                    offset: Offset(-5, -5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? color;

  const NeumorphicButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.width = 60,
    this.height = 60,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.color,
  }) : super(key: key);

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (widget.onPressed != null) {
          setState(() {
            _isPressed = true;
          });
        }
      },
      onTapUp: (details) {
        if (widget.onPressed != null) {
          setState(() {
            _isPressed = false;
          });
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          setState(() {
            _isPressed = false;
          });
        }
      },
      child: NeumorphicContainer(
        width: widget.width,
        height: widget.height,
        isPressed: _isPressed,
        borderRadius: widget.borderRadius,
        color: widget.color,
        padding: EdgeInsets.zero,
        child: Center(child: widget.child),
      ),
    );
  }
}
