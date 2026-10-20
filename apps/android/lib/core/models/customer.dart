class Customer {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String address;
  final String pincode;
  final String? city;
  final String? state;
  final bool consentOrderCommunication;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    required this.address,
    required this.pincode,
    this.city,
    this.state,
    this.consentOrderCommunication = true,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      phone: json['phone_encrypted'] as String? ?? json['phone'] as String? ?? '',
      address: json['address_encrypted'] as String? ?? json['address'] as String? ?? '',
      pincode: json['pincode'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      consentOrderCommunication: json['consent_order_communication'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone_encrypted': phone,
      'address_encrypted': address,
      'pincode': pincode,
      'city': city,
      'state': state,
      'consent_order_communication': consentOrderCommunication,
    };
  }
}
