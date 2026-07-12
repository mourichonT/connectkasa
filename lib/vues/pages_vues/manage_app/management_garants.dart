import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/garant_providers.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/manage_app/my_info_garant.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class ManagementGarants extends ConsumerStatefulWidget {
  final Color color;
  final String uid;

  const ManagementGarants({
    super.key,
    required this.color,
    required this.uid,
  });

  @override
  ConsumerState<ManagementGarants> createState() => ManagementGarantsState();
}

class ManagementGarantsState extends ConsumerState<ManagementGarants> {
  @override
  Widget build(BuildContext context) {
    final garantsAsync = ref.watch(garantsByUserProvider(widget.uid));

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          'Gestion des garants',
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: garantsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) =>
            Center(child: Text('Erreur: $error')),
        data: (garants) {
          if (garants.isEmpty) {
            return const Center(child: Text('Aucun garant trouvé.'));
          }
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
                  ref.invalidate(garantsByUserProvider(widget.uid));
                },
              );
            },
          );
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
                ref.invalidate(garantsByUserProvider(widget.uid));
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
