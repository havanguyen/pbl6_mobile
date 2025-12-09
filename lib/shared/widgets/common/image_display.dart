import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

class CommonImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? placeholderText;

  const CommonImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderText,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    String finalUrl = imageUrl!;
    // Fix for placehold.co SVGs crashing flutter_svg with "Invalid double"
    if (finalUrl.contains('placehold.co') && finalUrl.contains('.svg')) {
      finalUrl = finalUrl.replaceFirst('.svg', '.png');
    }

    // Check if it's an SVG
    bool isSvg = finalUrl.toLowerCase().contains('.svg');

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: isSvg
          ? SvgPicture.network(
              finalUrl,
              width: width,
              height: height,
              fit: fit,
              placeholderBuilder: (context) => _buildPlaceholder(context),
            )
          : CachedNetworkImage(
              imageUrl: finalUrl,
              width: width,
              height: height,
              fit: fit,
              placeholder: (context, url) => _buildPlaceholder(context),
              errorWidget: (context, url, error) {
                return _buildErrorWidget(context);
              },
            ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: context.theme.muted,
      alignment: Alignment.center,
      child: placeholderText != null
          ? Text(
              placeholderText!.substring(0, 1),
              style: TextStyle(color: context.theme.mutedForeground),
            )
          : null, // Shimmer or simple color
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: context.theme.muted,
      child: Icon(
        Icons.broken_image,
        color: context.theme.mutedForeground,
        size: 24,
      ),
    );
  }
}
