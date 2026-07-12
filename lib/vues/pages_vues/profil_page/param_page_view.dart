import 'package:konodal/controllers/features/load_user_controller.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/privacy_policy_page.dart';
import 'package:konodal/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:konodal/vues/pages_vues/profil_page/account_secu_modify.dart';
import 'package:konodal/vues/pages_vues/profil_page/notifications_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParamPage extends ConsumerStatefulWidget {
  final String uid;
  final Color color;
  final String idLot;

  const ParamPage({
    super.key,
    required this.uid,
    required this.color,
    required this.idLot,
  });

  @override
  ConsumerState<ParamPage> createState() => _ParamPageState();
}

class _ParamPageState extends ConsumerState<ParamPage> {
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
        builder: (context) => AccountSecuPageModify(
          email: email,
          uid: widget.uid,
          color: widget.color,
          // Invalide le cache partagé plutôt que de recharger un état
          // local : ParamPage n'affiche de toute façon aucune donnée
          // utilisateur directement, seuls les autres widgets qui
          // consomment userByIdProvider(uid) (profilTile...) en
          // bénéficient.
          refresh: () => ref.invalidate(userByIdProvider(widget.uid)),
          user: user,
          idLot: widget.idLot,
        ),
      ),
    );
  }

  void _navigateToNotifications() async {
    final user = await ref.read(userByIdProvider(widget.uid).future);
    if (user == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsSettingsPage(
          user: user,
          refresh: () => ref.invalidate(userByIdProvider(widget.uid)),
        ),
      ),
    );
  }

  void _navigateToPrivacyPolicy() async {
    final user = await ref.read(userByIdProvider(widget.uid).future);
    if (user == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivatePolicyPage(
          user: user,
          refresh: () => ref.invalidate(userByIdProvider(widget.uid)),
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
        title:
            MyTextStyle.lotName("Paramètres", Colors.black87, SizeFont.h1.size),
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
                  text: "Compte & sécurité",
                  icon: const Icon(Icons.person_2_rounded, size: 22),
                  press:
                      _navigateToModifyPage, // Utilisation de la fonction pour naviguer et récupérer les données mises à jour
                  isLogOut: false,
                ),
                Visibility(
                  visible: false,
                  child: ProfileMenu(
                    uid: widget.uid,
                    color: widget.color,
                    idLot: widget.idLot,
                    text: "Paiements & versements",
                    icon: const Icon(Icons.euro, size: 22),
                    press: () {},
                    isLogOut: false,
                  ),
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  idLot: widget.idLot,
                  text: "Notifications",
                  icon: const Icon(Icons.notifications_none_rounded, size: 22),
                  press: _navigateToNotifications,
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  idLot: widget.idLot,
                  text: "Politique de confidentialité",
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  press: _navigateToPrivacyPolicy,
                  isLogOut: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
