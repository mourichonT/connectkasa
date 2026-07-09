import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/core/providers/user_by_id_provider.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_folder_rent.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_pers_page_modify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InfoPageView extends ConsumerStatefulWidget {
  final String uid;
  final Color color;
  final String idLot;
  final List<Lot>? lots;

  const InfoPageView({
    super.key,
    required this.uid,
    required this.color,
    required this.idLot,
    this.lots,
  });

  @override
  ConsumerState<InfoPageView> createState() => _InfoPageViewState();
}

class _InfoPageViewState extends ConsumerState<InfoPageView> {
  String email = "";

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    if (widget.uid.isEmpty) return;
    final fetchedEmail = await LoadUserController.getUserEmail(widget.uid);
    if (mounted) {
      setState(() {
        email = fetchedEmail;
      });
    }
  }

  void _navigateToModifyPage() async {
    final user = await ref.read(userByIdProvider(widget.uid).future);
    if (user == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoPersoPageModify(
          email: email,
          uid: widget.uid,
          color: widget.color,
          // Invalide le cache partagé plutôt que de recharger un état
          // local : InfoPageView n'affiche de toute façon aucune donnée
          // utilisateur directement, seuls les autres widgets qui
          // consomment userByIdProvider(uid) (ProfilTile...) en
          // bénéficient.
          refresh: () => ref.invalidate(userByIdProvider(widget.uid)),
          user: user,
          idLot: widget.idLot,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: MyTextStyle.lotName(
            "Mes informations", Colors.black87, SizeFont.h1.size),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  idLot: widget.idLot,
                  text: "Mes informations personnelles",
                  icon: const Icon(Icons.person_2_rounded, size: 22),
                  press:
                      _navigateToModifyPage, // Utilisation de la fonction pour naviguer et récupérer les données mises à jour
                  isLogOut: false,
                ),
                Visibility(
                  visible: true,
                  child: ProfileMenu(
                    uid: widget.uid,
                    color: widget.color,
                    idLot: widget.idLot,
                    text: "Mon dossier locataire",
                    icon: const Icon(Icons.euro, size: 22),
                    press: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManagementFolderRent(
                            uid: widget.uid,
                            color: widget.color,
                          ),
                        ),
                      );
                    },
                    isLogOut: false,
                  ),
                ),
                // ProfileMenu(
                //   uid: widget.uid,
                //   color: widget.color,
                //   idLot: widget.idLot,
                //   text: "Mes documents personnels",
                //   icon: const Icon(Icons.folder_outlined, size: 22),
                //   press: () {},
                //   isLogOut: false,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
