class CategoryModel {
  final String id;
  final String nameRu;
  final String nameKk;
  final String icon;

  CategoryModel({
    required this.id,
    required this.nameRu,
    required this.nameKk,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {'nameRu': nameRu, 'nameKk': nameKk, 'icon': icon};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      nameRu: map['nameRu'] ?? '',
      nameKk: map['nameKk'] ?? '',
      icon: map['icon'] ?? '📦',
    );
  }
}
