import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';

class DemandeLoc {
  final Timestamp? timestamp;
  final UserInfo? tenant;
  final List<GuarantorInfo?>? garant;

  DemandeLoc({
    this.timestamp,
    this.tenant,
    this.garant,
  });

  factory DemandeLoc.fromJson(Map<String, dynamic> json) {
    return DemandeLoc(
      timestamp: json['timestamp'] ?? Timestamp.now(),
      tenant: UserInfo.fromMap(json['tenant']),
      garant: (json['garant'] as List<dynamic>)
          .map((e) => GuarantorInfo.fromMap(
              Map<String, dynamic>.from(e), '')) // ID vide par défaut
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'tenant': tenant!.toMap(),
      'garant': garant!.map((e) => e!.toMap()).toList(),
    };
  }
}
