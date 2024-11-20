import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TenantDetail extends StatefulWidget{

final UserInfo tenant;

  const TenantDetail({super.key, required this.tenant});

  @override
  State<StatefulWidget> createState() => TenantDetailState();
  
}


class TenantDetailState extends State<TenantDetail> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar( title: MyTextStyle.lotName("", Colors.black87, SizeFont.h1.size)),
      body: SingleChildScrollView(child: Column(
        children: [
          Card(
            elevation: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width/5, vertical: 40),
                  child: Column(
                    children: [
                      ProfilTile(widget.tenant.uid, 40, 36, 40, false),
                      SizedBox(height: 15,),
                      Row(children: [
                        MyTextStyle.lotName(widget.tenant.name, Colors.black87, SizeFont.h1.size),
                        SizedBox(width: 5,),
                        MyTextStyle.lotName(widget.tenant.surname, Colors.black87, SizeFont.h1.size),  
                      ],),
                      
                        MyTextStyle.lotDesc(widget.tenant.pseudo??"", SizeFont.h3.size, FontStyle.italic),

                      
                      ],
                      ),
                ),
                Container(
                  padding: EdgeInsets.only(right: 30),
                  child: Column(
                 
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      child: Column(
                         mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyTextStyle.lotName("7", Colors.black87, SizeFont.h1.size),
                          MyTextStyle.lotDesc("Evaluations", SizeFont.h3.size, FontStyle.normal),
                        ],
                      ),
                    ),
                    Container(
                       padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      child: Column(
                         mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [MyTextStyle.lotName("4,5", Colors.black87, SizeFont.h1.size), Icon(Icons.star_rate_rounded),],) ,
                          MyTextStyle.lotDesc("LocaScore", SizeFont.h3.size, FontStyle.normal),
                        ],
                      ),
                    ),
                ],),)
                    ],
                  ),
                ),

                SizedBox(height: 20,),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal:30),
                  child: 
                    Column(
                      children: [ 
                      
                        Padding(
                          padding: const EdgeInsets.symmetric( vertical: 20),
                          child: Row(
                            children: [
                              MyTextStyle.lotName("Informations personnelles", Colors.black87, SizeFont.h2.size),
                            ],
                          ),
                        ),
                       
                        Row(children: [
                          Icon(Icons.numbers),
                          SizedBox(width: 10,),
                          MyTextStyle.lotDesc("Reférence Utilisateur", SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
                          Spacer(),
                          MyTextStyle.annonceDesc(widget.tenant.uid,SizeFont.h3.size,1),
                        ],),
                        SizedBox(height: 10,),
                        Row(children: [
                          Icon(Icons.cake),
                          SizedBox(width: 10,),
                          MyTextStyle.lotDesc("Date de naissance", SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
                          Spacer(),
                          MyTextStyle.annonceDesc(DateFormat('dd/MM/yyyy').format(widget.tenant.birthday.toDate()),SizeFont.h3.size,1),
                        ],),
                        SizedBox(height: 10,),
                         Row(children: [
                          Icon(Icons.flag),
                          SizedBox(width: 10,),
                          MyTextStyle.lotDesc("Nationnalité", SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
                          Spacer(),
                          MyTextStyle.annonceDesc(widget.tenant.nationality,SizeFont.h3.size,1),
                        ],),
                        SizedBox(height: 10,),
                         Row(children: [
                          Icon(Icons.diamond),
                          SizedBox(width: 10,),
                          MyTextStyle.lotDesc("Situation", SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
                          Spacer(),
                          MyTextStyle.annonceDesc(widget.tenant.familySituation,SizeFont.h3.size,1),
                        ],),

                        Divider(),
                          Padding(
                          padding: const EdgeInsets.symmetric( vertical: 20),
                          child: Row(
                            children: [
                              MyTextStyle.lotName("Profil locataire", Colors.black87, SizeFont.h2.size),
                            ],
                          ),
                        ),
                         Row(children: [
                          Icon(Icons.diamond),
                          SizedBox(width: 10,),
                          MyTextStyle.lotDesc("Profession", SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
                          Spacer(),
                          MyTextStyle.annonceDesc(widget.tenant.profession??"",SizeFont.h3.size,1),
                        ],),

                      ],
                    ),
                    
                    
                )
            ],
      ),),
    );
  }
  
}