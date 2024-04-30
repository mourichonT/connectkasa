import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez ce package
import 'package:table_calendar/table_calendar.dart';

class EventPageView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => EventPageViewState();
}

class EventPageViewState extends State<EventPageView>
    with SingleTickerProviderStateMixin {
  DateTime today = DateTime.now();
  @override
  void initState() {
    super.initState();
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  Widget build(BuildContext context) {
    DateTime nextYear = DateTime.utc(today.year + 1, today.month, today.day);
    // Initialisez la localisation des formats de date pour le français
    initializeDateFormatting('fr_FR', null);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
              child: TableCalendar(
            locale: 'fr_FR',
            headerStyle:
                HeaderStyle(formatButtonVisible: false, titleCentered: true),
            availableGestures: AvailableGestures.all,
            selectedDayPredicate: (day) => isSameDay(day, today),
            focusedDay: today,
            firstDay: DateTime.utc(2023, 01, 01),
            lastDay: nextYear,
            onDaySelected: _onDaySelected,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  shape: BoxShape.circle),
            ),
          )),
          SizedBox(
            height: 20,
          ),
          Container(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8), // Espace entre l'icône et le texte
                  MyTextStyle.lotName('Ajouter un évenement', Colors.white),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
