import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/event_tile_comp.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:connect_kasa/vues/pages_vues/event_form.dart';
import 'package:connect_kasa/vues/pages_vues/event_page_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez ce package
import 'package:table_calendar/table_calendar.dart';

class EventPageView extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final Color colorStatut;
  final String? type;

  const EventPageView({
    super.key,
    required this.residenceSelected,
    required this.uid,
    required this.colorStatut,
    this.type,
  });

  @override
  State<StatefulWidget> createState() => EventPageViewState();
}

class EventPageViewState extends State<EventPageView>
    with SingleTickerProviderStateMixin {
  late Post? updatedPost;
  final DataBasesPostServices _databaseServices = DataBasesPostServices();

  late Future<List<Post>> _allEventsFuture;
  late List<DateTime> _eventDays; // Liste des jours avec événements
  DateTime _today = DateTime.now();
  late List<Post> _eventsForSelectedDay =
      []; // Événements pour le jour sélectionné

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _allEventsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
    _eventDays = [];
    _loadEventDays();
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _today = day;
      _filterEventsForSelectedDay(day);
    });

    _showEventsDialog(day);
  }

  void _filterEventsForSelectedDay(DateTime day) async {
    List<Post> allEvents = await _allEventsFuture;
    _eventsForSelectedDay = allEvents
        .where((event) =>
            event.eventDate != null &&
            isSameDay(event.eventDate!.toDate(), day))
        .toList();
  }

  void _showEventsDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Événements pour le ${day.day}/${day.month}/${day.year}",
              Colors.black87,
              SizeFont.h1.size),
          content: _eventsForSelectedDay.isEmpty
              ? MyTextStyle.annonceDesc(
                  "Aucun événement pour ce jour.", SizeFont.h3.size, 1)
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _eventsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      Post event = _eventsForSelectedDay[index];
                      return ListTile(
                        trailing: MyTextStyle.lotDesc(
                            MyTextStyle.EventHours(event.eventDate!),
                            SizeFont.h3.size),

                        leading: (event.pathImage != "" &&
                                event.pathImage != null &&
                                event.pathImage!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(3.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  width: 70,
                                  height: 70,
                                  child: Image.network(
                                    event.pathImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(3.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  width: 70,
                                  height: 70,
                                  child: ImageAnnounced(context, 70, 70),
                                ),
                              ),
                        title: Text(event
                            .title), // Change this according to your Post model
                        subtitle: MyTextStyle.annonceDesc(
                            event.description ?? "",
                            SizeFont.h3.size,
                            3), // Change this according to your Post model
                        onTap: () async {
                          updatedPost = await _databaseServices.getUpdatePost(
                              widget.residenceSelected, event.id);
                          Navigator.of(context).push(CupertinoPageRoute(
                            builder: (context) => EventPageDetails(
                              returnHomePage: false,
                              post: updatedPost!,
                              uid: widget.uid,
                              residence: widget.residenceSelected,
                              colorStatut: widget.colorStatut,
                              scrollController: 0.0,
                            ),
                          ));
                        },
                      );
                    },
                  ),
                ),
          actions: <Widget>[
            TextButton(
              child: const Text("Ajouter un évenement"),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => EventForm(
                      dateSelected: day,
                      residence: widget.residenceSelected,
                      uid: widget.uid,
                      onEventAdded: () {
                        _refreshEventList();
                      },
                    ),
                  ),
                ).then((_) {
                  Navigator.of(context)
                      .pop(); // Ferme la boîte de dialogue après la navigation
                });
              },
            ),
            TextButton(
              child: const Text("Fermer"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadEventDays() async {
    List<Post> posts = await _allEventsFuture;
    _eventDays.clear(); // Efface les événements précédents
    for (var post in posts) {
      if (post.eventDate != null) {
        Timestamp timestamp = post.eventDate!;
        DateTime dateTime = timestamp.toDate();
        if (dateTime.year > _today.year ||
            (dateTime.year == _today.year && dateTime.month >= _today.month)) {
          _eventDays.add(DateTime(dateTime.year, dateTime.month, dateTime.day));
        }
      }
    }
    setState(
        () {}); // Met à jour l'interface utilisateur avec les nouveaux événements
  }

  @override
  Widget build(BuildContext context) {
    DateTime nextYear = DateTime.utc(_today.year + 1, _today.month, _today.day);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              child: TableCalendar(
                locale: 'fr_FR',
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  formatButtonTextStyle: TextStyle(
                      fontSize:
                          SizeFont.h3.size), // Exemple de taille de police
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(
                      height: 0,
                      fontSize: SizeFont.h3.size,
                      color: widget.colorStatut),
                  weekdayStyle: TextStyle(
                    height: 0,
                    fontSize: SizeFont.h3.size,
                  ), // Exemple de taille de police
                ),
                availableGestures: AvailableGestures.all,
                selectedDayPredicate: (day) => isSameDay(day, _today),
                focusedDay: _today,
                firstDay: DateTime.utc(2023, 01, 01),
                lastDay: nextYear,
                onDaySelected: _onDaySelected,
                calendarStyle: CalendarStyle(
                  markerSizeScale: 0.2,
                  markerSize: 5,
                  markersAlignment: Alignment.bottomCenter,
                  markerDecoration: BoxDecoration(
                      color: widget.colorStatut, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  return _eventDays
                      .where((eventDay) => isSameDay(eventDay, day))
                      .toList();
                },
                rowHeight: 40,
                startingDayOfWeek: StartingDayOfWeek.monday,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 30),
              child: ButtonAdd(
                color: Theme.of(context).primaryColor,
                icon: Icons.add,
                text: 'Ajouter un événement',
                horizontal: 20,
                vertical: 10,
                size: 18, // Exemple de taille de police
                function: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => EventForm(
                        residence: widget.residenceSelected,
                        uid: widget.uid,
                        onEventAdded: () {
                          _refreshEventList();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                  Navigator.of(context).pop;
                },
              ),
            ),
            FutureBuilder<List<Post>>(
              future: _allEventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  List<Post> allPosts = snapshot.data!;
                  return SizedBox(
                    height: 400, // Hauteur à ajuster selon vos besoins
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemCount: allPosts.length,
                      itemBuilder: (context, index) {
                        final post = allPosts[index];
                        if (post.type == widget.type) {
                          return InkWell(
                            onTap: () async {
                              updatedPost =
                                  await _databaseServices.getUpdatePost(
                                      widget.residenceSelected, allPosts[0].id);
                              Navigator.of(context).push(CupertinoPageRoute(
                                builder: (context) => EventPageDetails(
                                  returnHomePage: false,
                                  post: post,
                                  uid: widget.uid,
                                  residence: widget.residenceSelected,
                                  colorStatut: widget.colorStatut,
                                  scrollController: 0.0,
                                ),
                              ));
                            },
                            child: EventTileComp(
                              post: post,
                              residence: widget.residenceSelected,
                              uid: widget.uid,
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _refreshEventList() {
    setState(() {
      _allEventsFuture =
          _databaseServices.getAllPosts(widget.residenceSelected);
      _loadEventDays();
    });
  }
}
