

import 'package:SombaTeka/utils/api.dart';

class Type {
  String? id;
  String? type;

  Type({this.id, this.type});

  Type.fromJson(Map<String, dynamic> json) {
    id = json[Api.id].toString();
    type = json[Api.type];
  }
}

class CategoryModel {
  final int? id;
  final String? name;
  final String? url;
  final List<CategoryModel>? children;
  final String? description;
  final int? subcategoriesCount;
  final int? isJobCategory;
  final int? priceOptional; // New field added

  CategoryModel({
    this.id,
    this.name,
    this.url,
    this.description,
    this.children,
    this.subcategoriesCount,
    this.isJobCategory,
    this.priceOptional, // Added to constructor
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> childData = json['subcategories'] ?? [];
      List<CategoryModel> children =
      childData.map((child) => CategoryModel.fromJson(child)).toList();

      return CategoryModel(
        id: json['id'],
        name: json['translated_name'],
        url: json['image'],
        subcategoriesCount: json['subcategories_count'] ?? 0,
        children: children,
        isJobCategory: json['is_job_category'] ?? 0,
        description: json['description'] ?? "",
        priceOptional: json['price_optional'], // Parse here
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'translated_name': name,
      'image': url,
      'subcategories_count': subcategoriesCount,
      'description': description,
      'subcategories': children?.map((child) => child.toJson()).toList(),
      'is_job_category': isJobCategory,
      'price_optional': priceOptional, // Include in JSON
    };
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, translated_name: $name, url: $url, description: $description, children: $children, subcategories_count: $subcategoriesCount, is_job_category: $isJobCategory, price_optional: $priceOptional)';
  }
}

