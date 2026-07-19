import 'package:konodal/controllers/features/contact_features.dart';
import 'package:konodal/core/repositories/ad_campaign_repository.dart';
import 'package:konodal/core/repositories/firestore_ad_campaign_repository.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
import 'package:konodal/vues/widget_view/components/rounded_card.dart';
import 'package:flutter/material.dart';

/// Carte publicitaire (campagne partagée entre résidences, gérée par le
/// backoffice - cf. AdCampaign) : uniquement l'image, dans un format carré
/// standard, aucun titre/description/like/commentaire/partage contrairement
/// aux autres cartes du fil. Un tap ouvre l'URL de la campagne et compte un
/// clic ; l'affichage de la carte compte une impression.
class AdvWidget extends StatefulWidget {
  final AdCampaign campaign;

  const AdvWidget({super.key, required this.campaign});

  @override
  State<AdvWidget> createState() => _AdvWidgetState();
}

class _AdvWidgetState extends State<AdvWidget> {
  final IAdCampaignRepository _adService = FirestoreAdCampaignRepository();

  @override
  void initState() {
    super.initState();
    // Une impression à chaque insertion réelle du widget dans l'arbre - donc
    // aussi à chaque fois qu'un scroll le fait sortir puis revenir dans la
    // fenêtre visible (ListView.separated recrée l'item), pas de déduplication
    // par utilisateur pour cette première version (décision produit).
    _adService.recordImpression(widget.campaign.id);
  }

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      child: InkWell(
        onTap: () {
          _adService.recordClick(widget.campaign.id);
          final targetUrl = widget.campaign.targetUrl;
          if (targetUrl != null && targetUrl.isNotEmpty) {
            ContactFeatures.openUrl(targetUrl);
          }
        },
        // LayoutBuilder plutôt que MediaQuery.size.width : la largeur de
        // l'écran ignore le padding horizontal du ListView (Homeview),
        // donnant un carré plus haut que large (largeur forcée par le
        // parent, hauteur non contrainte). constraints.maxWidth reflète la
        // largeur réellement disponible ici, quel que soit le padding.
        child: LayoutBuilder(
          builder: (context, constraints) {
            // .ceilToDouble() : constraints.maxWidth est une valeur
            // fractionnaire (ex: 373.714285714...px). Arrondie telle quelle,
            // le rendu peut laisser une ligne de quelques pixels non
            // couverte sur les bords de fin (droite/bas) entre l'image et
            // le fond blanc de la carte - un souci d'arrondi au pixel
            // physique déjà documenté sur Image + BoxFit.cover. Arrondir
            // au-dessus élimine cet écart (léger surplus invisible plutôt
            // qu'un manque visible).
            final side = constraints.maxWidth.ceilToDouble();
            return SizedBox(
              width: side,
              height: side,
              child: Image.network(
                widget.campaign.imageUrl,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    );
  }
}
