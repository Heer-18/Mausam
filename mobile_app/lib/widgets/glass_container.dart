import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'dynamic_weather_background.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final bool useBlur;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 20.0,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurSigma = 8.0,
    this.useBlur = true,
    this.onTap,
    this.gradient,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final atmosphere = WeatherAtmosphereScope.of(context);
    final effectiveFill = fillColor ?? atmosphere?.cardGlassFill ?? AppColors.glassFill;
    final effectiveBorder = borderColor ?? atmosphere?.cardGlassBorder ?? AppColors.glassBorder;

    Widget innerBox = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveFill : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: (useBlur && blurSigma > 0)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: innerBox,
              ),
            )
          : innerBox,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
