import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
// import 'package:connect_kasa/models/pages_models/user_info.dart';

class DemandeLoc {
  final Timestamp? timestamp;
  final String? tenantId;
  final List<String>? garantId;
  // final UserInfo? tenant;
  //final List<GuarantorInfo?>? garant;

  DemandeLoc({
    this.timestamp,
    this.tenantId,
    this.garantId,
  });

  factory DemandeLoc.fromJson(Map<String, dynamic> json) {
    return DemandeLoc(
      timestamp: json['timestamp'] ?? Timestamp.now(),
      tenantId: json['tenantId'] ?? "",
      //garantId: json['garantId'] ?? [],
      // tenant: UserInfo.fromMap(json['tenant']),
      garantId: (json['garantId'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'tenantId': tenantId,
      'garantId': garantId,
      // 'tenant': tenant!.toMap(),
      // 'garant': garant!.map((e) => e!.toMap()).toList(),
    };
  }
}
