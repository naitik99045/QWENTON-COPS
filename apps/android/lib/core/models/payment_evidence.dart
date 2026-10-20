enum EvidenceType { utr, screenshot, providerCallback }

enum ReviewStatus { needsReview, verifiedBySeller, rejected }

class PaymentEvidence {
  final String id;
  final String orderId;
  final EvidenceType type;
  final String? reference; // 12-digit UTR or txn ID
  final String? storagePath;
  final ReviewStatus reviewStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? notes;
  final DateTime createdAt;

  const PaymentEvidence({
    required this.id,
    required this.orderId,
    required this.type,
    this.reference,
    this.storagePath,
    this.reviewStatus = ReviewStatus.needsReview,
    this.reviewedBy,
    this.reviewedAt,
    this.notes,
    required this.createdAt,
  });

  bool get isNeedsReview => reviewStatus == ReviewStatus.needsReview;
  bool get isVerified => reviewStatus == ReviewStatus.verifiedBySeller;
  bool get isRejected => reviewStatus == ReviewStatus.rejected;

  factory PaymentEvidence.fromJson(Map<String, dynamic> json) {
    return PaymentEvidence(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      type: _parseType(json['type'] as String),
      reference: json['reference'] as String?,
      storagePath: json['storage_path'] as String?,
      reviewStatus: _parseStatus(json['review_status'] as String? ?? 'needs_review'),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static EvidenceType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'screenshot':
        return EvidenceType.screenshot;
      case 'provider_callback':
        return EvidenceType.providerCallback;
      case 'utr':
      default:
        return EvidenceType.utr;
    }
  }

  static ReviewStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'verified_by_seller':
        return ReviewStatus.verifiedBySeller;
      case 'rejected':
        return ReviewStatus.rejected;
      case 'needs_review':
      default:
        return ReviewStatus.needsReview;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'type': type.name,
      'reference': reference,
      'storage_path': storagePath,
      'review_status': reviewStatus == ReviewStatus.needsReview
          ? 'needs_review'
          : reviewStatus == ReviewStatus.verifiedBySeller
              ? 'verified_by_seller'
              : 'rejected',
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}
