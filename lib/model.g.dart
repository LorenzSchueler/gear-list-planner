// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GearList _$GearListFromJson(Map<String, dynamic> json) => GearList(
  id: GearListId((json['id'] as num).toInt()),
  name: json['name'] as String,
  notes: json['notes'] as String,
  readOnly: json['read_only'] as bool,
);

Map<String, dynamic> _$GearListToJson(GearList instance) => <String, dynamic>{
  'id': Id._toJson(instance.id),
  'name': instance.name,
  'notes': instance.notes,
  'read_only': instance.readOnly,
};

GearListItem _$GearListItemFromJson(Map<String, dynamic> json) => GearListItem(
  id: GearListItemId((json['id'] as num).toInt()),
  gearItemId: GearItemId((json['gear_item_id'] as num).toInt()),
  gearListId: GearListId((json['gear_list_id'] as num).toInt()),
  count: (json['count'] as num).toInt(),
  packed: json['packed'] as bool,
);

Map<String, dynamic> _$GearListItemToJson(GearListItem instance) =>
    <String, dynamic>{
      'id': Id._toJson(instance.id),
      'gear_item_id': Id._toJson(instance.gearItemId),
      'gear_list_id': Id._toJson(instance.gearListId),
      'count': instance.count,
      'packed': instance.packed,
    };

GearItem _$GearItemFromJson(Map<String, dynamic> json) => GearItem(
  id: GearItemId((json['id'] as num).toInt()),
  gearCategoryId: GearCategoryId((json['gear_category_id'] as num).toInt()),
  name: json['name'] as String,
  type: json['type'] as String,
  weight: (json['weight'] as num).toInt(),
  sortIndex: (json['sort_index'] as num).toInt(),
);

Map<String, dynamic> _$GearItemToJson(GearItem instance) => <String, dynamic>{
  'id': Id._toJson(instance.id),
  'gear_category_id': Id._toJson(instance.gearCategoryId),
  'name': instance.name,
  'type': instance.type,
  'weight': instance.weight,
  'sort_index': instance.sortIndex,
};

GearCategory _$GearCategoryFromJson(Map<String, dynamic> json) => GearCategory(
  id: GearCategoryId((json['id'] as num).toInt()),
  name: json['name'] as String,
  sortIndex: (json['sort_index'] as num).toInt(),
);

Map<String, dynamic> _$GearCategoryToJson(GearCategory instance) =>
    <String, dynamic>{
      'id': Id._toJson(instance.id),
      'name': instance.name,
      'sort_index': instance.sortIndex,
    };

GearModel _$GearModelFromJson(Map<String, dynamic> json) => GearModel(
  gearLists: (json['gear_lists'] as List<dynamic>)
      .map((e) => GearList.fromJson(e as Map<String, dynamic>))
      .toList(),
  gearListItems: (json['gear_list_items'] as List<dynamic>)
      .map((e) => GearListItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  gearItems: (json['gear_items'] as List<dynamic>)
      .map((e) => GearItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  gearCategories: (json['gear_categories'] as List<dynamic>)
      .map((e) => GearCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GearModelToJson(GearModel instance) => <String, dynamic>{
  'gear_lists': instance.gearLists,
  'gear_list_items': instance.gearListItems,
  'gear_items': instance.gearItems,
  'gear_categories': instance.gearCategories,
};
