import 'package:json_annotation/json_annotation.dart';

part "model.g.dart";

abstract class Id {
  int get id;

  static int _toJson(Id id) => id.id;
}

abstract class Entity<I extends Id> {
  I get id;

  Map<String, dynamic> toJson();
}

class GearListId implements Id {
  GearListId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearListId && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GearList extends Entity<GearListId> {
  GearList({required this.id, required this.name});

  factory GearList.fromJson(Map<String, dynamic> json) =>
      _$GearListFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearListToJson(this);

  @override
  @JsonKey(fromJson: GearListId.new, toJson: Id._toJson)
  GearListId id;
  String name;
}

class GearListVersionId implements Id {
  GearListVersionId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearListVersionId && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GearListVersion extends Entity<GearListVersionId> {
  GearListVersion({
    required this.id,
    required this.gearListId,
    required this.name,
    required this.readOnly,
  });

  factory GearListVersion.fromJson(Map<String, dynamic> json) =>
      _$GearListVersionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearListVersionToJson(this);

  @override
  @JsonKey(fromJson: GearListVersionId.new, toJson: Id._toJson)
  final GearListVersionId id;
  @JsonKey(fromJson: GearListId.new, toJson: Id._toJson)
  GearListId gearListId;
  String name;
  bool readOnly;
}

class GearListItemId implements Id {
  GearListItemId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearListItemId && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GearListItem extends Entity<GearListItemId> {
  GearListItem({
    required this.id,
    required this.gearItemId,
    required this.gearListVersionId,
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
  @JsonKey(fromJson: GearListVersionId.new, toJson: Id._toJson)
  GearListVersionId gearListVersionId;
  int count;
  bool packed;
}

class GearItemId implements Id {
  GearItemId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearItemId && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GearItem extends Entity<GearItemId> implements Comparable<GearItem> {
  GearItem({
    required this.id,
    required this.gearCategoryId,
    required this.name,
    required this.weight,
    required this.index,
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
  double weight;
  int index;

  @override
  int compareTo(GearItem other) => index.compareTo(other.index);
}

class GearCategoryId implements Id {
  GearCategoryId(this.id);

  @override
  final int id;

  @override
  bool operator ==(other) => other is GearCategoryId && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GearCategory extends Entity<GearCategoryId> {
  GearCategory({required this.id, required this.name});

  factory GearCategory.fromJson(Map<String, dynamic> json) =>
      _$GearCategoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GearCategoryToJson(this);

  @override
  @JsonKey(fromJson: GearCategoryId.new, toJson: Id._toJson)
  final GearCategoryId id;
  String name;
}

@JsonSerializable()
class GearModel {
  GearModel({
    required this.gearLists,
    required this.gearListVersions,
    required this.gearListItems,
    required this.gearItems,
    required this.gearCategories,
  });

  factory GearModel.fromJson(Map<String, dynamic> json) =>
      _$GearModelFromJson(json);

  Map<String, dynamic> toJson() => _$GearModelToJson(this);

  List<GearList> gearLists;
  List<GearListVersion> gearListVersions;
  List<GearListItem> gearListItems;
  List<GearItem> gearItems;
  List<GearCategory> gearCategories;
}
