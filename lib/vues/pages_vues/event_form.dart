import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:connect_kasa/vues/widget_view/camera_files_choices.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class EventForm extends StatefulWidget {
  final String residence;
  final String uid;
  final DateTime? dateSelected;
  final VoidCallback onEventAdded;

  const EventForm({
    Key? key,
    required this.residence,
    required this.uid,
    this.dateSelected,
    required this.onEventAdded,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => EventFormState();
}

class EventFormState extends State<EventForm> {
  final StorageServices _storageServices = StorageServices();
  File? _selectedImage;

  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController _dateEventController = TextEditingController();
  TextEditingController _timeEventController = TextEditingController();
  String imagePath = "";
  bool anonymPost = false;
  late List<String> labelsCat;
  String idPost = const Uuid().v1();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  late Timestamp eventDate;

  @override
  void initState() {
    super.initState();
    updateEventDate(dateSelected: widget.dateSelected);
  }

  void updateEventDate({DateTime? dateSelected}) {
    if (dateSelected != null) {
      selectedDate = dateSelected;
      selectedTime = TimeOfDay.fromDateTime(dateSelected);
      eventDate = Timestamp.fromMillisecondsSinceEpoch(
        dateSelected.millisecondsSinceEpoch,
      );

      setState(() {
        _timeEventController.text = DateFormat('HH:mm').format(dateSelected);
        _dateEventController.text =
            DateFormat('dd-MM-yyyy').format(dateSelected);
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                        Container(
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
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
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
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Row(
                            children: [
                              Container(
                                width: 90,
                                child: MyTextStyle.lotName(
                                  "Titre : ",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextField(
                                  controller: title,
                                  maxLines: 1,
                                  decoration: InputDecoration.collapsed(
                                    hintText:
                                        "Saisissez le titre de votre évenement",
                                    hintStyle: TextStyle(
                                      fontSize: SizeFont.h3.size,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 90,
                                child: MyTextStyle.lotName(
                                  "Description : ",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextField(
                                  controller: desc,
                                  maxLines: 4,
                                  decoration: InputDecoration.collapsed(
                                    hintText: "Saisissez une description",
                                    hintStyle: TextStyle(
                                      fontSize: SizeFont.h3.size,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                ],
              ),
            ),
            CameraOrFiles(
              racineFolder: "residences",
              residence: widget.residence,
              folderName: "events",
              title: title.text,
              onImageUploaded: downloadImagePath,
              cardOverlay: false,
            ),
            const SizedBox(height: 30),
            Divider(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
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
                  selectedLabel: "events",
                  imagePath: imagePath,
                  eventDate: eventDate,
                  title: title,
                  desc: desc,
                  docRes: widget.residence,
                );
                widget.onEventAdded();
              },
              child: MyTextStyle.lotName(
                "Ajouter",
                Theme.of(context).primaryColor,
                SizeFont.h3.size,
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime today = DateTime.now();

    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 1),
    );

    setState(() {
      selectedDate = _picked;
      updateEventDate(dateSelected: _picked);
    });
    }

  Future<void> _selectHour() async {
    TimeOfDay? _pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (_pickedTime != null) {
      setState(() {
        selectedTime = _pickedTime;
        updateEventDate();
      });
    }
  }
}
