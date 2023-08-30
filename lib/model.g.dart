// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GearList _$GearListFromJson(Map<String, dynamic> json) => GearList(
      id: GearListId(json['id'] as int),
      name: json['name'] as String,
    );

Map<String, dynamic> _$GearListToJson(GearList instance) => <String, dynamic>{
      'id': Id._toJson(instance.id),
      'name': instance.name,
    };

GearListVersion _$GearListVersionFromJson(Map<String, dynamic> json) =>
    GearListVersion(
      id: GearListVersionId(json['id'] as int),
      gearListId: GearListId(json['gear_list_id'] as int),
      name: json['name'] as String,
      notes: json['notes'] as String,
      readOnly: json['read_only'] as bool,
    );

Map<String, dynamic> _$GearListVersionToJson(GearListVersion instance) =>
    <String, dynamic>{
      'id': Id._toJson(instance.id),
      'gear_list_id': Id._toJson(instance.gearListId),
      'name': instance.name,
      'notes': instance.notes,
      'read_only': instance.readOnly,
    };

GearListItem _$GearListItemFromJson(Map<String, dynamic> json) => GearListItem(
      id: GearListItemId(json['id'] as int),
      gearItemId: GearItemId(json['gear_item_id'] as int),
      gearListVersionId: GearListVersionId(json['gear_list_version_id'] as int),
      count: json['count'] as int,
      packed: json['packed'] as bool,
    );

Map<String, dynamic> _$GearListItemToJson(GearListItem instance) =>
    <String, dynamic>{
      'id': Id._toJson(instance.id),
      'gear_item_id': Id._toJson(instance.gearItemId),
      'gear_list_version_id': Id._toJson(instance.gearListVersionId),
      'count': instance.count,
      'packed': instance.packed,
    };

GearItem _$GearItemFromJson(Map<String, dynamic> json) => GearItem(
      id: GearItemId(json['id'] as int),
      gearCategoryId: GearCategoryId(json['gear_category_id'] as int),
      name: json['name'] as String,
      type: json['type'] as String,
      weight: json['weight'] as int,
      sortIndex: json['sort_index'] as int,
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
      id: GearCategoryId(json['id'] as int),
      name: json['name'] as String,
    );

Map<String, dynamic> _$GearCategoryToJson(GearCategory instance) =>
    <String, dynamic>{
      'id': Id._toJson(instance.id),
      'name': instance.name,
    };

GearModel _$GearModelFromJson(Map<String, dynamic> json) => GearModel(
      gearLists: (json['gear_lists'] as List<dynamic>)
          .map((e) => GearList.fromJson(e as Map<String, dynamic>))
          .toList(),
      gearListVersions: (json['gear_list_versions'] as List<dynamic>)
          .map((e) => GearListVersion.fromJson(e as Map<String, dynamic>))
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
      'gear_list_versions': instance.gearListVersions,
      'gear_list_items': instance.gearListItems,
      'gear_items': instance.gearItems,
      'gear_categories': instance.gearCategories,
    };
