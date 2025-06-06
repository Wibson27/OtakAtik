class CommunityCategory {
  final String id;
  final String categoryName;
  final String? categoryDescription;
  final String? categoryColor;
  final int? displayOrder;
  final bool? isActive;
  final bool? moderatorRequired;
  final String? postGuidelines;
  final String? iconName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CommunityCategory({
    required this.id,
    required this.categoryName,
    this.categoryDescription,
    this.categoryColor,
    this.displayOrder,
    this.isActive,
    this.moderatorRequired,
    this.postGuidelines,
    this.iconName,
    this.createdAt,
    this.updatedAt,
  });

  factory CommunityCategory.fromJson(Map<String, dynamic> json) {
    return CommunityCategory(
      id: json['id'],
      categoryName: json['category_name'],
      categoryDescription: json['category_description'],
      categoryColor: json['category_color'],
      displayOrder: json['display_order'],
      isActive: json['is_active'],
      moderatorRequired: json['moderator_required'],
      postGuidelines: json['post_guidelines'],
      iconName: json['icon_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': categoryName,
      'category_description': categoryDescription,
      'category_color': categoryColor,
      'display_order': displayOrder,
      'is_active': isActive,
      'moderator_required': moderatorRequired,
      'post_guidelines': postGuidelines,
      'icon_name': iconName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}