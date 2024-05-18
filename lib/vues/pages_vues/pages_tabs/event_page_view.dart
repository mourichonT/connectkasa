import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez ce package
import 'package:table_calendar/table_calendar.dart';

class EventPageView extends StatefulWidget {
  final String residenceSelected;
  final String uid;

  const EventPageView(
      {super.key, required this.residenceSelected, required this.uid});

  @override
  State<StatefulWidget> createState() => EventPageViewState();
}

class EventPageViewState extends State<EventPageView>
    with SingleTickerProviderStateMixin {
  // Initialisez votre service de base de données
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
          ButtonAdd(
              color: Theme.of(context).primaryColor,
              icon: Icons.add,
              text: 'Ajouter un évenement',
              horizontal: 10,
              vertical: 2,
              size: 13),
          EventTile(widget.uid, widget.residenceSelected)
        ],
      ),
    );
  }
}
