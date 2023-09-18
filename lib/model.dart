import 'package:json_annotation/json_annotation.dart';

part "model.g.dart";

abstract class Id {
  int get id;

  static int _toJson(Id id) => id.id;
}

abstract class Entity<I extends Id> {
  I get id;

  Map<String, dynamic> toJson();

  @override
  bool operator ==(other) =>
      other is Entity && other.runtimeType == runtimeType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class GearListId implements Id {
  GearListId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearListId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id.toString();
}

@JsonSerializable()
class GearList extends Entity<GearListId> {
  GearList({
    required this.id,
    required this.name,
    required this.notes,
    required this.readOnly,
  });

  factory GearList.fromJson(Map<String, dynamic> json) =>
      _$GearListFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearListToJson(this);

  @override
  @JsonKey(fromJson: GearListId.new, toJson: Id._toJson)
  final GearListId id;
  String name;
  String notes;
  bool readOnly;

  @override
  String toString() => id.toString();
}

class GearListItemId implements Id {
  GearListItemId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearListItemId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id.toString();
}

@JsonSerializable()
class GearListItem extends Entity<GearListItemId> {
  GearListItem({
    required this.id,
    required this.gearItemId,
    required this.gearListId,
    required this.count,
    required this.packed,
  });

  factory GearListItem.fromJson(Map<String, dynamic> json) =>
      _$GearListItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearListItemToJson(this);

  @override
  @JsonKey(fromJson: GearListItemId.new, toJson: Id._toJson)
  final GearListItemId id;
  @JsonKey(fromJson: GearItemId.new, toJson: Id._toJson)
  GearItemId gearItemId;
  @JsonKey(fromJson: GearListId.new, toJson: Id._toJson)
  GearListId gearListId;
  int count;
  bool packed;

  @override
  String toString() => id.toString();
}

class GearItemId implements Id {
  GearItemId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearItemId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id.toString();
}

@JsonSerializable()
class GearItem extends Entity<GearItemId> implements Comparable<GearItem> {
  GearItem({
    required this.id,
    required this.gearCategoryId,
    required this.name,
    required this.type,
    required this.weight,
    required this.sortIndex,
  });

  factory GearItem.fromJson(Map<String, dynamic> json) =>
      _$GearItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearItemToJson(this);

  @override
  @JsonKey(fromJson: GearItemId.new, toJson: Id._toJson)
  final GearItemId id;
  @JsonKey(fromJson: GearCategoryId.new, toJson: Id._toJson)
  GearCategoryId gearCategoryId;
  String name;
  String type;
  int weight;
  int sortIndex;

  @override
  int compareTo(GearItem other) => sortIndex.compareTo(other.sortIndex);

  @override
  String toString() => id.toString();
}

class GearCategoryId implements Id {
  GearCategoryId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearCategoryId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id.toString();
}

@JsonSerializable()
class GearCategory extends Entity<GearCategoryId> {
  GearCategory({required this.id, required this.name, required this.sortIndex});

  factory GearCategory.fromJson(Map<String, dynamic> json) =>
      _$GearCategoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearCategoryToJson(this);

  @override
  @JsonKey(fromJson: GearCategoryId.new, toJson: Id._toJson)
  final GearCategoryId id;
  String name;
  int sortIndex;

  @override
  String toString() => id.toString();
}

@JsonSerializable()
class GearModel {
  GearModel({
    required this.gearLists,
    required this.gearListItems,
    required this.gearItems,
    required this.gearCategories,
  });

  factory GearModel.fromJson(Map<String, dynamic> json) =>
      _$GearModelFromJson(json);

  Map<String, dynamic> toJson() => _$GearModelToJson(this);

  List<GearList> gearLists;
  List<GearListItem> gearListItems;
  List<GearItem> gearItems;
  List<GearCategory> gearCategories;
}
