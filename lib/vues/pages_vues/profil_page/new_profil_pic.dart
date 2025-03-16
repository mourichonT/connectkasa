import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfilePic extends StatelessWidget {
  final String uid;
  final Color color;
  final String refLot;

  const ProfilePic({
    Key? key,
    required this.uid,
    required this.color,
    required this.refLot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ProfilTile(uid, 70, 75, 0, false),
          Positioned(
            right: 0,
            bottom: -10,
            child: SizedBox(
              height: 50,
              width: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80),
                    side: const BorderSide(color: Colors.white, width: 5),
                  ),
                  backgroundColor: const Color(0xFFF5F6F9),
                ),
                onPressed: () {},
                child: Icon(Icons.photo_camera_outlined,
                    color: Colors.black45, size: 22),
              ),
            ),
          )
        ],
      ),
    );
  }
}
