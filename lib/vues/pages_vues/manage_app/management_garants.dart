import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/core/repositories/user_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_user_repository.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/my_info_garant.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/my_infos_rent.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail_withheader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementGarants extends StatefulWidget {
  final Color color;
  final String uid;

  const ManagementGarants({
    super.key,
    required this.color,
    required this.uid,
  });

  @override
  ManagementGarantsState createState() => ManagementGarantsState();
}

class ManagementGarantsState extends State<ManagementGarants> {
  late Future<List<GuarantorInfo?>> _garantByUser;
  final IUserRepository _userRepository = FirestoreUserRepository();

  @override
  void initState() {
    super.initState();
    _garantByUser = _userRepository
        .getGarants(widget.uid)
        .then((result) => result.when(
            success: (v) => v, failure: (error) => throw error));
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
                  title: MyTextStyle.lotName('${garant.surname} ${garant.name}',
                      Colors.black87, SizeFont.h3.size),
                  subtitle: MyTextStyle.lotName(garant.email, Colors.black87,
                      SizeFont.h3.size, FontWeight.normal),
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
                      _garantByUser = _userRepository
                          .getGarants(widget.uid)
                          .then((result) => result.when(
                              success: (v) => v,
                              failure: (error) => throw error));
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
                  _garantByUser = _userRepository
                      .getGarants(widget.uid)
                      .then((result) => result.when(
                          success: (v) => v,
                          failure: (error) => throw error));
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
