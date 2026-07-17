import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/event_tile_comp.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/pages_vues/event_page/event_form.dart';
import 'package:konodal/vues/pages_vues/event_page/event_page_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez ce package
import 'package:table_calendar/table_calendar.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class EventPageView extends ConsumerStatefulWidget {
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
  ConsumerState<EventPageView> createState() => EventPageViewState();
}

class EventPageViewState extends ConsumerState<EventPageView>
    with SingleTickerProviderStateMixin {
  final IPostRepository _databaseServices = FirestorePostRepository();
  Post? updatedPost;
  Post? selectedPost;
  DateTime _today = DateTime.now();
  // Jour sélectionné sur le calendrier : filtre "Événements futurs"/
  // "passés" sur ce seul jour. null = pas de filtre, liste complète.
  DateTime? _selectedDay;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Annule le TabController
    super.dispose();
  }

  List<Post> _eventsOnly(List<Post> allPosts) =>
      allPosts.where((post) => post.eventDate != null).toList();

  List<DateTime> _eventDaysFrom(List<Post> events) {
    return events
        .where((post) {
          final eventDate = post.eventDate!.toDate();
          return eventDate.year > _today.year ||
              (eventDate.year == _today.year &&
                  eventDate.month >= _today.month);
        })
        .map((post) {
          final d = post.eventDate!.toDate();
          return DateTime(d.year, d.month, d.day);
        })
        .toList();
  }

  void _onDaySelected(DateTime day, DateTime focusedDay, List<Post> allEvents) {
    if (!mounted) return;

    final now = DateTime.now();
    final dayEvents =
        allEvents.where((event) => isSameDay(event.eventDate!.toDate(), day)).toList();
    final futureOnDay =
        dayEvents.where((event) => event.eventDate!.toDate().isAfter(now)).toList();
    final pastOnDay =
        dayEvents.where((event) => event.eventDate!.toDate().isBefore(now)).toList();

    setState(() {
      _today = day;
      _selectedDay = day;
    });

    // Sélection automatique de l'onglet en fonction des événements trouvés
    if (pastOnDay.isNotEmpty && futureOnDay.isEmpty) {
      _tabController.animateTo(1); // Aller à "Événements passés"
    } else {
      _tabController.animateTo(0); // Aller à "Événements futurs"
    }

    _showEventsDialog(day, allEvents);
  }

  void _showEventsDialog(DateTime day, List<Post> allEvents) {
    DateTime now = DateTime.now();
    DateTime selectedDate =
        DateTime(day.year, day.month, day.day, now.hour, now.minute)
            .subtract(Duration(seconds: 10));
    final dayEvents =
        allEvents.where((event) => isSameDay(event.eventDate!.toDate(), day)).toList();
    final pastEvents =
        dayEvents.where((event) => event.eventDate!.toDate().isBefore(now)).toList();
    final futureEvents =
        dayEvents.where((event) => event.eventDate!.toDate().isAfter(now)).toList();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Événements pour le ${day.day}/${day.month}/${day.year}",
              Colors.black87,
              SizeFont.h1.size),
          content: (selectedDate.isBefore(DateTime.now())
                  ? pastEvents.isEmpty
                  : futureEvents.isEmpty)
              ? MyTextStyle.annonceDesc(
                  "Aucun événement pour ce jour.", SizeFont.h3.size, 1)
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectedDate.isBefore(DateTime.now())
                        ? pastEvents.length
                        : futureEvents.length,
                    itemBuilder: (context, index) {
                      Post event = selectedDate.isBefore(DateTime.now())
                          ? pastEvents[index]
                          : futureEvents[index];
                      return ListTile(
                        trailing: MyTextStyle.lotDesc(
                            MyTextStyle.eventHours(event.eventDate!),
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
                                  child: imageAnnounced(context, 70, 70),
                                ),
                              ),
                        title: Text(event.title),
                        // subtitle: MyTextStyle.annonceDesc(
                        //     event.description ?? "", SizeFont.h3.size, 3),
                        onTap: () async {
                          selectedPost = await _databaseServices
                              .getUpdatePost(
                                  widget.residenceSelected, event.id)
                              .then((result) => result.when(
                                  success: (v) => v, failure: (_) => null));
                          // Repli sur l'event déjà en main si la relecture
                          // ne retrouve rien - cf. event_widget.dart.
                          selectedPost ??= event;
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => EventPageDetails(
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

  void _refreshEventList() {
    ref.invalidate(allPostsByResidenceProvider(widget.residenceSelected));
    if (mounted) {
      setState(() {
        _selectedDay = null;
      });
    }
  }

  /// Rafraîchit la liste depuis l'extérieur (ex: my_nav_bar.dart au retour
  /// du formulaire de création de post), via un `GlobalKey<EventPageViewState>`.
  void refreshEvents() => _refreshEventList();

  @override
  Widget build(BuildContext context) {
    final eventsAsync =
        ref.watch(allPostsByResidenceProvider(widget.residenceSelected));

    return eventsAsync.when(
      loading: () =>
          const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
      data: (allPosts) {
        final allEvents = _eventsOnly(allPosts);
        final eventDays = _eventDaysFrom(allEvents);
        final now = DateTime.now();
        final relevantEvents = _selectedDay == null
            ? allEvents
            : allEvents
                .where((event) =>
                    isSameDay(event.eventDate!.toDate(), _selectedDay!))
                .toList();
        final futureEvents = relevantEvents
            .where((event) => event.eventDate!.toDate().isAfter(now))
            .toList();
        final pastEvents = relevantEvents
            .where((event) => event.eventDate!.toDate().isBefore(now))
            .toList();

        return _buildScaffold(context, allEvents, eventDays, futureEvents, pastEvents);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Post> allEvents,
    List<DateTime> eventDays,
    List<Post> futureEvents,
    List<Post> pastEvents,
  ) {
    DateTime nextYear = DateTime.utc(_today.year + 1, _today.month, _today.day);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
                locale: 'fr_FR',
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  formatButtonTextStyle: TextStyle(fontSize: SizeFont.h3.size),
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
                onDaySelected: (day, focusedDay) =>
                    _onDaySelected(day, focusedDay, allEvents),
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
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  return eventDays
                      .where((eventDay) => isSameDay(eventDay, day))
                      .toList();
                },
                rowHeight: 35,
                startingDayOfWeek: StartingDayOfWeek.monday,
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
                  _buildEventList(futureEvents),
                  _buildEventList(pastEvents),
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
            updatedPost = await _databaseServices
                .getUpdatePost(widget.residenceSelected, post.id)
                .then((result) =>
                    result.when(success: (v) => v, failure: (_) => null));
            // Repli sur le post déjà en main si la relecture ne retrouve
            // rien (ex: post écrit sans son champ "id") - cf. event_widget.dart.
            updatedPost ??= post;
            if (!context.mounted) return;
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
