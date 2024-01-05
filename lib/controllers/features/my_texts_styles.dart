import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTextStyle {

  static Color getColor(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return theme.primaryColor;
  }

  static Widget applyPadding(Widget widget, EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: widget,
    );
  }

  static Widget styledText(BuildContext context, String text, TextStyle style, EdgeInsets padding) {
    return applyPadding(
      Text(
        text,
        style: style.copyWith(color: getColor(context)),
      ),
      padding
    );
  }

  static Widget logo(BuildContext context, String text, EdgeInsets padding) {
    return styledText(
      context,
      text,
      GoogleFonts.majorMonoDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
      padding,
    );
  }

  static Widget IconDrawer(BuildContext context, IconData icon, EdgeInsets padding) {
    return applyPadding(
        Icon(
      icon,
      color: getColor(context),
    ),
      padding
    );
  }

  static Text lotName(String text) {
    return Text(
      text,
      style: GoogleFonts.robotoCondensed(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  static Text lotDesc(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 13,
      ),
    );
  }

  static void changeColor(BuildContext context, Color newColor) {
    final ThemeData theme = Theme.of(context).copyWith(primaryColor: newColor);
    final MaterialApp app = MaterialApp(
      theme: theme,
    );
    runApp(app);
  }
}
