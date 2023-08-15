class GearListId {
  GearListId(this._id);
  final int _id;

  @override
  bool operator ==(other) => other is GearListId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

class GearList {
  GearList({required this.id, required this.name});

  GearListId id;
  String name;
}

class GearListVersionId {
  GearListVersionId(this._id);
  final int _id;

  @override
  bool operator ==(other) => other is GearListVersionId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

class GearListVersion {
  GearListVersion({
    required this.id,
    required this.gearListId,
    required this.name,
    required this.readOnly,
  });

  GearListVersionId id;
  GearListId gearListId;
  String name;
  bool readOnly;
}

class GearListItemId {
  GearListItemId(this._id);
  final int _id;

  @override
  bool operator ==(other) => other is GearListItemId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

class GearListItem {
  GearListItem({
    required this.id,
    required this.gearItemId,
    required this.gearListVersionId,
    required this.count,
    required this.packed,
  });

  GearListItemId id;
  GearItemId gearItemId;
  GearListVersionId gearListVersionId;
  int count;
  bool packed;
}

class GearItemId {
  GearItemId(this._id);
  final int _id;

  @override
  bool operator ==(other) => other is GearItemId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

class GearItem implements Comparable<GearItem> {
  GearItem({
    required this.id,
    required this.gearCategoryId,
    required this.name,
    required this.weight,
    required this.index,
  });

  GearItemId id;
  GearCategoryId gearCategoryId;
  String name;
  double weight;
  int index;

  @override
  int compareTo(GearItem other) => index.compareTo(other.index);
}

class GearCategoryId {
  GearCategoryId(this._id);
  final int _id;

  @override
  bool operator ==(other) => other is GearCategoryId && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}

class GearCategory {
  GearCategory({required this.id, required this.name});

  GearCategoryId id;
  String name;
}
