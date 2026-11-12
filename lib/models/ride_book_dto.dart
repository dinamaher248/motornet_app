class RideBookDto {
  final int id;
  final String customerName;
  final String customerPhone;
  final int seatCount;
  final int amount;
  final String msg;
  final String pickLoc;
  final String targetLoc;
  final String status;
  final String createdAt;

  RideBookDto({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.seatCount,
    required this.amount,
    required this.msg,
    required this.pickLoc,
    required this.targetLoc,
    required this.status,
    required this.createdAt,
  });

  factory RideBookDto.fromJson(Map<String, dynamic> json) {
    return RideBookDto(
      id: json['id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      seatCount: json['seat_count'],
      amount: json['amount'],
      msg: json['msg'],
      pickLoc: json['pick_loc'],
      targetLoc: json['target_loc'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
