import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/my_info_garant.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/my_infos_rent.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementGarants extends StatefulWidget {
  final Color color;
  final String uid;
  final String docId; // Ajout du docId

  const ManagementGarants({
    super.key,
    required this.color,
    required this.uid,
    required this.docId,
  });

  @override
  ManagementGarantsState createState() => ManagementGarantsState();
}

class ManagementGarantsState extends State<ManagementGarants> {
  late Future<List<GuarantorInfo?>> _garantByUser;

  @override
  void initState() {
    super.initState();
    _garantByUser = DataBasesUserServices.getGarants(widget.uid, widget.docId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          'Gestion des garants',
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: FutureBuilder<List<GuarantorInfo?>>(
        future: _garantByUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun garant trouvé.'));
          } else {
            final garants = snapshot.data!;
            return ListView.separated(
              itemCount: garants.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final garant = garants[index];
                if (garant == null) {
                  return ListTile(title: Text('Garant non trouvé'));
                }
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${garant.surname} ${garant.name}'),
                  subtitle: Text(garant.email ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF757575), size: 22),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyGarantInfos(
                          uid: widget.uid,
                          color: widget.color,
                          garant: garant,
                        ),
                      ),
                    );
                    setState(() {
                      _garantByUser = DataBasesUserServices.getGarants(
                          widget.uid, widget.docId);
                    });
                  },
                );
              },
            );
          }
        },
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          height: 50,
          width: double.infinity,
          color: Colors.transparent,
          child: Center(
            child: ButtonAdd(
              function: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyGarantInfos(
                      uid: widget.uid,
                      color: widget.color,
                    ),
                  ),
                );
                setState(() {
                  _garantByUser = DataBasesUserServices.getGarants(
                      widget.uid, widget.docId);
                });
              },
              text: "Ajouter un garant",
              color: widget.color,
              horizontal: 30,
              vertical: 10,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
