import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
// import 'package:connect_kasa/models/pages_models/user_info.dart';

class DemandeLoc {
  final String? id;
  final Timestamp? timestamp;
  final String? tenantId;
  final List<String>? garantId;
  final bool open;
  // final UserInfo? tenant;
  //final List<GuarantorInfo?>? garant;

  DemandeLoc({
    this.id,
    this.timestamp,
    this.tenantId,
    this.garantId,
    this.open = false,
  });

  factory DemandeLoc.fromJson(Map<String, dynamic> json, {String? id}) {
    return DemandeLoc(
      id: id,
      timestamp: json['timestamp'] ?? Timestamp.now(),
      tenantId: json['tenantId'] ?? "",
      garantId: (json['garantId'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      open: json['open'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'tenantId': tenantId,
      'garantId': garantId,
      'open': open,
      // 'tenant': tenant!.toMap(),
      // 'garant': garant!.map((e) => e!.toMap()).toList(),
    };
  }
}
