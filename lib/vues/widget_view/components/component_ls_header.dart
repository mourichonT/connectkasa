import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class ComponentLsHeader extends StatelessWidget{
  final String label;
  final String note;
  final Icon icon;

  const ComponentLsHeader({super.key, required this.label, required this.note, required this.icon});
  
  @override
  Widget build(BuildContext context) {
   return SizedBox(
    width: 120,
    height: 120,
     child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min,
 // Alignement pour éviter les erreurs de taille
              children:[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyTextStyle.lotDesc(label, SizeFont.para.size, FontStyle.normal, FontWeight.bold),
                    const SizedBox(height: 5,),
                    MyTextStyle.lotDesc(note, SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
                  ],
                ),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(vertical: 1), child:  icon)
              ]
            ),
   );
  }
  
}