class ReglaDescuento {
  final int quantity;
  final double discountPercentage;
  final int? daysWithoutSale;
  final double? timeDiscount;

  ReglaDescuento({
    required this.quantity,
    required this.discountPercentage,
    this.daysWithoutSale,
    this.timeDiscount,
  });

  factory ReglaDescuento.fromJson(Map<String, dynamic> json) {
    return ReglaDescuento(
      quantity: json['quantity'] as int? ?? 0,
      discountPercentage: (json['discount_percentage'] ?? 0.0) as double,
      daysWithoutSale: json['days_without_sale'] as int?,
      timeDiscount: json['time_discount'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'discount_percentage': discountPercentage,
      'days_without_sale': daysWithoutSale,
      'time_discount': timeDiscount,
    };
  }
} 