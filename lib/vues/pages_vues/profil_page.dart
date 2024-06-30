import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ProfilPage extends StatefulWidget {
  final String uid;
  final Color? color;

  const ProfilPage({
    super.key,
    required this.uid,
    this.color,
  });
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName("Profile", Colors.black87, SizeFont.h1.size),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilTile(widget.uid, 45, 40, 45, false),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {},
                  child: MyTextStyle.lotName("Modifier la photo",
                      widget.color ?? Colors.black87, SizeFont.h3.size)),
              Icon(Icons.camera_alt_outlined)
            ],
          ),
        ],
      ),
    );
  }
}
