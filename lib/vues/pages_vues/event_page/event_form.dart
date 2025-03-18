import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/event_type.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class EventForm extends StatefulWidget {
  final String residence;
  final String uid;
  final DateTime? dateSelected;
  final VoidCallback onEventAdded;
  final Lot? preferedLot;

  const EventForm({
    super.key,
    required this.residence,
    required this.uid,
    this.dateSelected,
    required this.onEventAdded,
    required this.preferedLot,
  });

  @override
  State<StatefulWidget> createState() => EventFormState();
}

class EventFormState extends State<EventForm> {
  final DataBasesResidenceServices _databaseContactServices =
      DataBasesResidenceServices();
  final StorageServices _storageServices = StorageServices();
  File? _selectedImage;

  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  final TextEditingController _dateEventController = TextEditingController();
  final TextEditingController _timeEventController = TextEditingController();
  String imagePath = "";
  bool anonymPost = false;
  late List<String> labelsCat;
  String idPost = const Uuid().v1();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  late Timestamp eventDate;
  Set<EventType> _selectedEventTypes = {};
  List<String> itemsCSMembers = [];
  late Future<List<Contact>> itemsPresta;
  String? presta;

  void updateItem(String updatedElement) {
    setState(() {
      presta = updatedElement;
    });
  }

  @override
  void initState() {
    super.initState();
    updateEventDate(dateSelected: widget.dateSelected);
    itemsCSMembers =
        List<String>.from(widget.preferedLot!.residenceData['csmembers']);
    _selectedEventTypes =
        !itemsCSMembers.contains(widget.uid) ? {EventType.evenement} : {};
    itemsPresta =
        _databaseContactServices.getContactByResidence(widget.residence);
  }

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    _dateEventController.dispose();
    _timeEventController.dispose();
    super.dispose();
  }

  void updateEventDate({DateTime? dateSelected}) {
    if (dateSelected != null) {
      selectedDate = dateSelected;
      selectedTime = TimeOfDay.fromDateTime(selectedDate!);
      eventDate = Timestamp.fromMillisecondsSinceEpoch(
        selectedDate!.millisecondsSinceEpoch,
      );

      setState(() {
        _timeEventController.text = DateFormat('HH:mm').format(selectedDate!);
        _dateEventController.text =
            DateFormat('dd-MM-yyyy').format(selectedDate!);
      });
    } else if (selectedDate != null && selectedTime != null) {
      final DateTime combinedDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      eventDate = Timestamp.fromMillisecondsSinceEpoch(
        combinedDateTime.millisecondsSinceEpoch,
      );

      setState(() {
        _timeEventController.text =
            DateFormat('HH:mm').format(combinedDateTime);
        _dateEventController.text =
            DateFormat('dd-MM-yyyy').format(selectedDate!);
      });
    }
  }

  void downloadImagePath(String downloadUrl) {
    setState(() {
      imagePath = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List<String> itemsPresta =
    //     ["teste1", "teste2"];

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Créer un nouvel évenement",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ProfilTile(
                        widget.uid,
                        22,
                        19,
                        22,
                        true,
                        Colors.black87,
                        SizeFont.h2.size,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          child: MyTextStyle.lotName(
                            "Date : ",
                            Colors.black87,
                            SizeFont.h3.size,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: _dateEventController,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.calendar_today, size: 14),
                              suffixIcon:
                                  const Icon(Icons.arrow_drop_down, size: 23),
                              label: MyTextStyle.lotDesc(
                                "Date de l'événement",
                                SizeFont.para.size,
                                FontStyle.normal,
                              ),
                            ),
                            readOnly: true,
                            onTap: () {
                              _selectDate();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          child: MyTextStyle.lotName(
                            "Heure : ",
                            Colors.black87,
                            SizeFont.h3.size,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: _timeEventController,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.access_time, size: 14),
                              suffixIcon:
                                  const Icon(Icons.arrow_drop_down, size: 23),
                              label: MyTextStyle.lotDesc(
                                "Heure de l'événement",
                                SizeFont.para.size,
                                FontStyle.normal,
                              ),
                            ),
                            readOnly: true,
                            onTap: () {
                              _selectHour();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: itemsCSMembers.contains(widget.uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Color(0xFFF5F6F9)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MyTextStyle.lotDesc(
                              "-- Vous êtes membre du Conseil Syndical -- ",
                              SizeFont.h3.size,
                              FontStyle.italic),
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text("Evénement participatif"),
                                    value: _selectedEventTypes.contains(EventType
                                        .evenement), // Vérifie si l'option est sélectionnée
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value != null && value) {
                                          // Ajoute EventType.evenement à l'ensemble
                                          _selectedEventTypes
                                              .add(EventType.evenement);
                                        } else {
                                          // Retire EventType.evenement de l'ensemble
                                          _selectedEventTypes
                                              .remove(EventType.evenement);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text("Prestation externe"),
                                    value: _selectedEventTypes.contains(EventType
                                        .prestation), // Vérifie si l'option est sélectionnée
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value != null && value) {
                                          // Ajoute EventType.prestation à l'ensemble
                                          _selectedEventTypes
                                              .add(EventType.prestation);
                                        } else {
                                          // Retire EventType.prestation de l'ensemble
                                          _selectedEventTypes
                                              .remove(EventType.prestation);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: _selectedEventTypes
                                .contains(EventType.prestation),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 10, left: 20, right: 20),
                              child: FutureBuilder<List<Contact>>(
                                future:
                                    itemsPresta, // Attend la récupération des contacts
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator(); // Affiche un loader en attendant
                                  } else if (snapshot.hasError) {
                                    return Text("Erreur : ${snapshot.error}");
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text(
                                        "Aucun prestataire trouvé.");
                                  } else {
                                    List<String> prestataireNoms = snapshot
                                        .data!
                                        .map((contact) => contact.name)
                                        .toList();

                                    return MyDropDownMenu(
                                      MediaQuery.of(context).size.width,
                                      "Prestataire",
                                      "Choisir un prestataire",
                                      true,
                                      items: prestataireNoms,
                                      onValueChanged: (String value) {
                                        setState(() {
                                          presta = value;
                                          updateItem(presta!);
                                        });
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomTextFieldWidget(
                          label: "Titre",
                          text: "Définissez un titre pour votre post",
                          controller: title,
                          isEditable: true,
                          minLines: 1,
                          maxLines: 1,
                        ),

                        /// 📝 **Description (Remplacé par CustomTextFieldWidget)**
                        CustomTextFieldWidget(
                            label: "Description",
                            controller: desc,
                            isEditable: true,
                            minLines: 6,
                            maxLines: 6,
                            text: "Donnez des précisions sur la déclaration"),
                        CameraOrFiles(
                          racineFolder: "residences",
                          residence: widget.residence,
                          folderName: "events",
                          title: title.text,
                          onImageUploaded: downloadImagePath,
                          cardOverlay: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: ButtonAdd(
                color: Theme.of(context).primaryColor,
                //icon: Icons.add,
                text: "Ajouter l'événement",
                horizontal: 20,
                vertical: 5,
                size: SizeFont.h3.size,
                function: () {
                  if (imagePath.isEmpty ||
                      _dateEventController.text.isEmpty ||
                      title.text.isEmpty ||
                      desc.text.isEmpty ||
                      imagePath.isEmpty) {
                    // Show an error message or disable the button
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(
                          'Tous les champs sont requis!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                    return;
                  }
                  SubmitPostController.submitForm(
                    uid: widget.uid,
                    idPost: idPost,
                    eventType: _selectedEventTypes.map((e) => e.value).toList(),
                    prestaName: presta,
                    selectedLabel: "events",
                    imagePath: imagePath,
                    eventDate: eventDate,
                    title: title,
                    desc: desc,
                    docRes: widget.residence,
                  );
                  widget.onEventAdded();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime today = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 1),
    );

    setState(() {
      selectedDate = picked;
      updateEventDate(dateSelected: picked);
    });
  }

  Future<void> _selectHour() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        updateEventDate();
      });
    }
  }
}
