import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
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
  final Lot? preferedLot;
  final String residenceSelected;
  final String uid;
  final Color colorStatut;
  final String? type;

  const EventPageView({
    super.key,
    required this.preferedLot,
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
  late Post? selectedPost;
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late Future<List<Post>> _allEventsFuture;
  late List<Post> _futureEvents;
  late List<Post> _pastEvents;
  DateTime _today = DateTime.now();
  late List<DateTime> _eventDays;
  bool _isPastDate = false; // Variable pour suivre si la date sélectionnée est passée

  late TabController _tabController;
  
 @override
void initState() {
  super.initState();
  initializeDateFormatting('fr_FR', null);
  _allEventsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
  _eventDays = [];
  _futureEvents = [];
  _pastEvents = [];
  _tabController = TabController(length: 2, vsync: this);

  _loadEventDays();
  _filterEvents(); //  Filtrer directement les événements
}
@override
void dispose() {
  _tabController.dispose(); // Annule le TabController
  super.dispose();
}


void _filterEvents() async {
  List<Post> allEvents = await _allEventsFuture;
  if (!mounted) return; 

  setState(() {
    _futureEvents = allEvents
        .where((event) =>
            event.eventDate != null &&
            event.eventDate!.toDate().isAfter(DateTime.now()))
        .toList();

    _pastEvents = allEvents
        .where((event) =>
            event.eventDate != null &&
            event.eventDate!.toDate().isBefore(DateTime.now()))
        .toList();
  });
}


void _onDaySelected(DateTime day, DateTime focusedDay) {
    if (!mounted) return;

  setState(() {
    _today = day;
    _filterEventsForSelectedDay(day);
    _isPastDate = day.isBefore(DateTime.now());
  });

  _showEventsDialog(day);
}

void _filterEventsForSelectedDay(DateTime day) async {
  List<Post> allEvents = await _allEventsFuture;

  DateTime today = DateTime.now();
  

 List<Post> selectedEvents = allEvents.where((event) {
  if (event.eventDate == null) return false; // Ignore les événements sans date
  DateTime eventDate = event.eventDate!.toDate();
  return isSameDay(eventDate, day);
}).toList();

  if (!mounted) return;

  setState(() {
    _futureEvents = selectedEvents.where((event) => event.eventDate!.toDate().isAfter(today)).toList();
    _pastEvents = selectedEvents.where((event) => event.eventDate!.toDate().isBefore(today)).toList();

    // Sélection automatique de l'onglet en fonction des événements trouvés
    if (_pastEvents.isNotEmpty && _futureEvents.isEmpty) {
      _tabController.animateTo(1); // Aller à "Événements passés"
    } else {
      _tabController.animateTo(0); // Aller à "Événements futurs"
    }
  });
}

  void _showEventsDialog(DateTime day) {
    DateTime now = DateTime.now();
    DateTime selectedDate = DateTime(day.year, day.month, day.day, now.hour, now.minute).subtract(Duration(seconds: 10));
    if (!mounted) return; 
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Événements pour le ${day.day}/${day.month}/${day.year}",
              Colors.black87,
              SizeFont.h1.size),
          content: (selectedDate.isBefore(DateTime.now()) ? _pastEvents.isEmpty : _futureEvents.isEmpty)
              ? MyTextStyle.annonceDesc(
                  "Aucun événement pour ce jour.", SizeFont.h3.size, 1)
              : SizedBox(
                  width: double.maxFinite,
                  child: 
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectedDate.isBefore(DateTime.now())?_pastEvents.length:_futureEvents.length,
                    itemBuilder: (context, index) {
                      Post event = selectedDate.isBefore(DateTime.now())?_pastEvents[index]:_futureEvents[index] ;
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
                        title: Text(event.title),
                        // subtitle: MyTextStyle.annonceDesc(
                        //     event.description ?? "", SizeFont.h3.size, 3),
                        onTap: () async {
                          selectedPost = await _databaseServices.getUpdatePost(
                              widget.residenceSelected, event.id);
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>  EventPageDetails(
                                  returnHomePage: false,
                                  post: selectedPost!,
                                  uid: widget.uid,
                                  residence: widget.residenceSelected,
                                  colorStatut: widget.colorStatut,
                                  scrollController: 0.0,
                                ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                
                
                if (selectedDate.isBefore(now)) {
                  return; // Désactive le bouton si la date et l'heure sont passées
                }
                
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => EventForm(
                      dateSelected: day,
                      preferedLot: widget.preferedLot,
                      residence: widget.residenceSelected,
                      uid: widget.uid,
                      onEventAdded: () {
                        _refreshEventList();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
              child: Text(
                "Ajouter un événement",
                style: TextStyle(
                  color: selectedDate.isBefore(now)
                      ? Colors.grey
                      : Colors.black87, // Change la couleur si désactivé
                ),
              ),
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
    _eventDays.clear(); 
    if (!mounted) return; 
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
    setState(() {}); 
  }

  void _refreshEventList() {
    if (!mounted) return; 
    setState(() {
      _allEventsFuture =
          _databaseServices.getAllPosts(widget.residenceSelected);
      _loadEventDays();
    });
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
                          SizeFont.h3.size),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(
                      height: 0,
                      fontSize: SizeFont.h3.size,
                      color: widget.colorStatut),
                  weekdayStyle: TextStyle(
                    height: 0,
                    fontSize: SizeFont.h3.size,
                  ),
                ),
                availableGestures: AvailableGestures.all,
                selectedDayPredicate: (day) => isSameDay(day, _today),
                focusedDay: _today,
                firstDay: DateTime.utc(2023, 01, 01),
                lastDay: nextYear,
                onDaySelected: _onDaySelected,
                calendarStyle: CalendarStyle(
                  markerSizeScale: 0.2,
                  markerSize: 7,
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
                rowHeight: 35,
                startingDayOfWeek: StartingDayOfWeek.monday,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              child: ButtonAdd(
                color: Theme.of(context).primaryColor,
                icon: Icons.add,
                text: 'Ajouter un événement',
                horizontal: 20,
                vertical: 5,
                size: SizeFont.h3.size,
                function: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => EventForm(
                        preferedLot: widget.preferedLot,
                        residence: widget.residenceSelected,
                        uid: widget.uid,
                        onEventAdded: () {
                          _refreshEventList();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Événements futurs'),
                Tab(text: 'Événements passés'),
              ],
            ),
            SizedBox(
              height: 400, // Hauteur à ajuster selon vos besoins
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(_futureEvents),
                  _buildEventList(_pastEvents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<Post> events) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final post = events[index];
        return InkWell(
          onTap: () async {
            updatedPost = await _databaseServices.getUpdatePost(
                widget.residenceSelected, events[0].id);
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
          child: EventTileComp(
            post: post,
            residence: widget.residenceSelected,
            uid: widget.uid,
          ),
        );
      },
    );
  }
}
