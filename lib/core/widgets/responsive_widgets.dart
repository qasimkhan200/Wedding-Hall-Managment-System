import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../utils/responsive_utils.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? minFontSize;
  final double? maxFontSize;
  final Color? color;
  final FontWeight? fontWeight;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.minFontSize,
    this.maxFontSize,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style?.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      minFontSize: (minFontSize ?? 10.sp)
          .truncateToDouble(), // Ensure integer for safety, or align with stepGranularity if we keep 0.1
      stepGranularity: 0.1,
      maxFontSize: (maxFontSize ?? style?.fontSize ?? ResponsiveUtils.body1)
          .truncateToDouble(),
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? ResponsiveUtils.paddingSm,
      child: Card(
        color: color,
        elevation: elevation ?? 2,
        shape: RoundedRectangleBorder(
          borderRadius:
              borderRadius ?? BorderRadius.circular(ResponsiveUtils.radiusMd),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(ResponsiveUtils.radiusMd),
          child: Padding(
            padding: padding ?? ResponsiveUtils.paddingMd,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? ResponsiveUtils.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ?? ResponsiveUtils.paddingVerticalMd,
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ?? BorderRadius.circular(ResponsiveUtils.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: ResponsiveUtils.iconMd,
                height: ResponsiveUtils.iconMd,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: ResponsiveUtils.iconSm),
                    SizedBox(width: ResponsiveUtils.sm),
                  ],
                  ResponsiveText(
                    text,
                    style: TextStyle(
                      fontSize: fontSize ?? ResponsiveUtils.body1,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.width,
    this.height,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? ResponsiveUtils.paddingMd,
      decoration: decoration ??
          BoxDecoration(
            color: color,
            borderRadius:
                borderRadius ?? BorderRadius.circular(ResponsiveUtils.radiusMd),
          ),
      child: child,
    );
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final EdgeInsets? padding;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.padding,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? ResponsiveUtils.paddingMd,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveUtils.getGridColumns(context),
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: crossAxisSpacing ?? ResponsiveUtils.sm,
        mainAxisSpacing: mainAxisSpacing ?? ResponsiveUtils.sm,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;

  const ResponsiveListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: contentPadding ?? ResponsiveUtils.paddingHorizontalMd,
      minLeadingWidth: ResponsiveUtils.iconLg,
    );
  }
}

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final PreferredSizeWidget? bottom;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: ResponsiveText(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.headline6,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      toolbarHeight: ResponsiveUtils.buttonHeightLarge,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        ResponsiveUtils.buttonHeightLarge +
            (bottom?.preferredSize.height ?? 0.0),
      );
}
