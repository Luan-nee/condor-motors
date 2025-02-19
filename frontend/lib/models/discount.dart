class DiscountRule {
  final int quantity;
  final int discountPercentage;
  final int? daysWithoutSale; // Días sin venta para aplicar descuento
  final double? timeDiscount; // Porcentaje de descuento por tiempo

  DiscountRule({
    required this.quantity,
    required this.discountPercentage,
    this.daysWithoutSale,
    this.timeDiscount,
  });

  factory DiscountRule.fromJson(Map<String, dynamic> json) {
    return DiscountRule(
      quantity: json['quantity'] as int,
      discountPercentage: json['discountPercentage'] as int,
      daysWithoutSale: json['daysWithoutSale'] as int?,
      timeDiscount: json['timeDiscount'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'discountPercentage': discountPercentage,
      'daysWithoutSale': daysWithoutSale,
      'timeDiscount': timeDiscount,
    };
  }
} 