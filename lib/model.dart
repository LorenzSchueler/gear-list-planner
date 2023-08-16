import 'package:json_annotation/json_annotation.dart';

part "model.g.dart";

abstract class Id {
  int get _id;

  static int _toJson(Id id) => id._id;
}

class GearListId implements Id {
  GearListId(this._id);

  @override
  final int _id;

  @override
  bool operator ==(other) => other is GearListId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

@JsonSerializable()
class GearList {
  GearList({required this.id, required this.name});

  factory GearList.fromJson(Map<String, dynamic> json) =>
      _$GearListFromJson(json);

  Map<String, dynamic> toJson() => _$GearListToJson(this);

  @JsonKey(fromJson: GearListId.new, toJson: Id._toJson)
  GearListId id;
  String name;
}

class GearListVersionId implements Id {
  GearListVersionId(this._id);
  @override
  final int _id;

  @override
  bool operator ==(other) => other is GearListVersionId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

@JsonSerializable()
class GearListVersion {
  GearListVersion({
    required this.id,
    required this.gearListId,
    required this.name,
    required this.readOnly,
  });

  factory GearListVersion.fromJson(Map<String, dynamic> json) =>
      _$GearListVersionFromJson(json);

  Map<String, dynamic> toJson() => _$GearListVersionToJson(this);

  @JsonKey(fromJson: GearListVersionId.new, toJson: Id._toJson)
  GearListVersionId id;
  @JsonKey(fromJson: GearListId.new, toJson: Id._toJson)
  GearListId gearListId;
  String name;
  bool readOnly;
}

class GearListItemId implements Id {
  GearListItemId(this._id);

  @override
  final int _id;

  @override
  bool operator ==(other) => other is GearListItemId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

@JsonSerializable()
class GearListItem {
  GearListItem({
    required this.id,
    required this.gearItemId,
    required this.gearListVersionId,
    required this.count,
    required this.packed,
  });

  factory GearListItem.fromJson(Map<String, dynamic> json) =>
      _$GearListItemFromJson(json);

  Map<String, dynamic> toJson() => _$GearListItemToJson(this);

  @JsonKey(fromJson: GearListItemId.new, toJson: Id._toJson)
  GearListItemId id;
  @JsonKey(fromJson: GearItemId.new, toJson: Id._toJson)
  GearItemId gearItemId;
  @JsonKey(fromJson: GearListVersionId.new, toJson: Id._toJson)
  GearListVersionId gearListVersionId;
  int count;
  bool packed;
}

class GearItemId implements Id {
  GearItemId(this._id);

  @override
  final int _id;

  @override
  bool operator ==(other) => other is GearItemId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

@JsonSerializable()
class GearItem implements Comparable<GearItem> {
  GearItem({
    required this.id,
    required this.gearCategoryId,
    required this.name,
    required this.weight,
    required this.index,
  });

  factory GearItem.fromJson(Map<String, dynamic> json) =>
      _$GearItemFromJson(json);

  Map<String, dynamic> toJson() => _$GearItemToJson(this);

  @JsonKey(fromJson: GearItemId.new, toJson: Id._toJson)
  GearItemId id;
  @JsonKey(fromJson: GearCategoryId.new, toJson: Id._toJson)
  GearCategoryId gearCategoryId;
  String name;
  double weight;
  int index;

  @override
  int compareTo(GearItem other) => index.compareTo(other.index);
}

class GearCategoryId implements Id {
  GearCategoryId(this._id);

  @override
  final int _id;

  @override
  bool operator ==(other) => other is GearCategoryId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

@JsonSerializable()
class GearCategory {
  GearCategory({required this.id, required this.name});

  factory GearCategory.fromJson(Map<String, dynamic> json) =>
      _$GearCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$GearCategoryToJson(this);

  @JsonKey(fromJson: GearCategoryId.new, toJson: Id._toJson)
  GearCategoryId id;
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
