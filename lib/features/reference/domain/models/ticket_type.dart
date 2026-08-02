class TicketType {
  final String typeId;
  final String name;
  final String category; // 'single', 'pass', 'return', 'concession'
  final double defaultFare;
  final bool isPass;

  const TicketType({
    required this.typeId,
    required this.name,
    required this.category,
    required this.defaultFare,
    required this.isPass,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      typeId: json['type_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'single',
      defaultFare: (json['default_fare'] as num? ?? 0).toDouble(),
      isPass: json['is_pass'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_id': typeId,
      'name': name,
      'category': category,
      'default_fare': defaultFare,
      'is_pass': isPass,
    };
  }
}
