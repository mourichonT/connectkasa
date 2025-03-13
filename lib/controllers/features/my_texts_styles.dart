import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_post_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

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

  static Widget styledText(
      BuildContext context, String text, TextStyle style, EdgeInsets padding) {
    return applyPadding(
        Text(
          text,
          style: style.copyWith(color: getColor(context)),
        ),
        padding);
  }

  static Text symbolKasa(String text, Color color, [double? size]) {
    return Text(
      text,
      style: GoogleFonts.majorMonoDisplay(
        fontSize: size,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  static Widget logo(
      BuildContext context, String text, EdgeInsets padding, double size) {
    return styledText(
      context,
      text,
      GoogleFonts.majorMonoDisplay(
        fontSize: size,
        fontWeight: FontWeight.w300,
      ),
      padding,
    );
  }

  static Widget iconDrawer(
      BuildContext context, IconData icon, EdgeInsets padding) {
    return applyPadding(
        Icon(
          icon,
          color: getColor(context),
        ),
        padding);
  }

  static Text lotName(String text, Color color, [double? size]) {
    return Text(text,
        style: GoogleFonts.robotoCondensed(
          fontWeight: FontWeight.w600,
          fontSize: size ?? 16,
          color: color,
        ));
  }

  static Text lotDesc(String text, double size,
      [FontStyle? fontsize, FontWeight? weight]) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: size,
        fontStyle: fontsize ?? FontStyle.italic,
        fontWeight: weight ?? FontWeight.normal,
      ),
    );
  }

  static Text postDesc(String text, double size, Color color) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: size,
        color: color,
      ),
    );
  }

  static Text login(
      String text, double size, Color color, FontWeight fontWeight) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }

  static Text commentTextFormat(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: SizeFont.h3.size,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  static Text annonceDesc(String text, double size, int maxLines) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: size,
        fontStyle: FontStyle.italic,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: TextAlign.left,
    );
  }

  static Text initialAvatar(String initiales, double size) {
    return Text(
      initiales,
      style: GoogleFonts.roboto(
          fontWeight: FontWeight.bold, fontSize: size, color: Colors.black54),
    );
  }

  static Widget postDate(Timestamp timeStamp) {
    DateTime tsdate = timeStamp.toDate();
    String formattedDate = DateFormat("le dd/MM/yyyy 'à' HH:mm").format(tsdate);

    return Text(
      formattedDate,
      style: GoogleFonts.roboto(
        fontStyle: FontStyle.italic,
        fontSize: SizeFont.para.size,
      ),
    );
  }

  static Widget chatdate(Timestamp timeStamp) {
    DateTime tsdate = timeStamp.toDate();
    String formattedDate = DateFormat("dd/MM, HH:mm").format(tsdate);

    return Text(
      formattedDate,
      style: GoogleFonts.roboto(
        fontStyle: FontStyle.italic,
        fontSize: SizeFont.para.size,
      ),
    );
  }

  static String completDate(Timestamp timeStamp) {
    tz.TZDateTime tsdate = tz.TZDateTime.from(timeStamp.toDate(), tz.local);
    tz.Location paris = tz.getLocation('Europe/Paris');
    tsdate = tz.TZDateTime.from(tsdate, paris);

    DateFormat formatter = DateFormat("dd MMM à HH'h'mm", 'fr_FR');
    String formattedDate = formatter.format(tsdate);
    return formattedDate;
  }

  static String EventHours(Timestamp timestamp) {
    tz.TZDateTime eventDate = tz.TZDateTime.from(timestamp.toDate(), tz.local);
    tz.Location paris = tz.getLocation('Europe/Paris');
    eventDate = tz.TZDateTime.from(eventDate, paris);

    DateFormat formattedDate = DateFormat("HH:mm", 'fr_FR');
    String date = formattedDate.format(eventDate);
    return date;
  }

  static commentDate(Timestamp timestamp) {
    // Convertir le Timestamp en millisecondes depuis l'époque Unix
    int milliseconds = timestamp.millisecondsSinceEpoch;

    // Convertir les millisecondes en objet DateTime
    DateTime commentTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    // Obtenir la durée écoulée depuis le timestamp jusqu'à maintenant
    Duration difference = DateTime.now().difference(commentTime);

    // Formater la durée écoulée
    if (difference.inSeconds < 60) {
      return const Text("à l'instant");
    } else if (difference.inMinutes < 60) {
      return Text('il y a ${difference.inMinutes} min');
    } else if (difference.inHours < 24) {
      return Text('il y a ${difference.inHours} h');
    } else if (difference.inDays < 30) {
      return Text('il y a ${difference.inDays} j');
    } else if (difference.inDays < 365) {
      int months =
          (difference.inDays / 30.44).floor(); // Convertir les jours en mois
      return Text('il y a $months mois');
    } else {
      int years = (difference.inDays / 365.25)
          .floor(); // Convertir les jours en années (compte les années bissextiles)
      return years > 1 ? Text('il y a $years ans') : Text('il y a $years an');
    }
  }

  static EventDateDay(Timestamp timestamp, double size) {
    // Convertir le Timestamp en millisecondes depuis l'époque Unix
    int milliseconds = timestamp.millisecondsSinceEpoch;
    DateTime eventDate = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    String formattedDate = DateFormat('dd').format(eventDate);
    return Text(
      formattedDate,
      style: TextStyle(fontSize: size),
    );
  }

  static EventDateMonth(Timestamp timestamp, double size) {
    // Convertir le Timestamp en millisecondes depuis l'époque Unix
    int milliseconds = timestamp.millisecondsSinceEpoch;
    DateTime eventDate = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    String formattedMonth = DateFormat.MMM('fr').format(eventDate);
    return Text(
      formattedMonth,
      style: TextStyle(fontSize: size),
    );
  }

  static MailDate(Timestamp timestamp) {
    // Convertir le Timestamp en millisecondes depuis l'époque Unix
    int milliseconds = timestamp.millisecondsSinceEpoch;

    // Convertir les millisecondes en objet DateTime
    DateTime commentTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    // Obtenir la durée écoulée depuis le timestamp jusqu'à maintenant
    Duration difference = DateTime.now().difference(commentTime);

    // Formater la durée écoulée
    if (difference.inSeconds < 60) {
      return const Text("à l'instant");
    } else if (difference.inMinutes < 60) {
      return Text('il y a ${difference.inMinutes} min');
    } else if (difference.inHours < 24) {
      return Text('il y a ${difference.inHours} h');
    } else {
      String formattedDate =
          DateFormat('dd/MM/yyyy à hh:ss').format(commentTime);
      return Text('Le $formattedDate');
    }
  }

  static Widget statuColor(String statusString, colorTheme) {
    // Conversion de la chaîne de caractères en énumération StatutPostList
    StatutPostList status = StatutPostList.fromString(statusString);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        color: _getColorForStatus(status, colorTheme),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          status.label, // Utilisation de la propriété `label` de l'énumération
          style: GoogleFonts.roboto(
              color: Colors.white, fontSize: SizeFont.para.size),
        ),
      ),
    );
  }

  static Color _getColorForStatus(StatutPostList status, colorTheme) {
    switch (status) {
      case StatutPostList.enAttente:
        return Colors.grey;
      case StatutPostList.priseEnCompte:
        return Colors.orange;
      case StatutPostList.termine:
        return colorTheme;
      default:
        return Colors.transparent;
    }
  }

  static void changeColor(BuildContext context, Color newColor) {
    final ThemeData theme = Theme.of(context).copyWith(primaryColor: newColor);
    final MaterialApp app = MaterialApp(
      theme: theme,
    );
    runApp(app);
  }

  static Text iconText(String text, {Color? color}) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: SizeFont.para.size,
        fontStyle: FontStyle.italic,
        color: color ?? Colors.black87,
      ),
    );
  }
}
