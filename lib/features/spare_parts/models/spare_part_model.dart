class SparePartModel {
  final int id;
  final String sparepartsname;
  final String partnumber;
  final int spquantity;
  final String date;
  final String spnotes;

  const SparePartModel({
    required this.id,
    required this.sparepartsname,
    this.partnumber = '',
    required this.spquantity,
    required this.date,
    this.spnotes = '',
  });

  factory SparePartModel.fromJson(Map<String, dynamic> json) {
    return SparePartModel(
      id: (json['id'] as num).toInt(),
      sparepartsname: json['sparepartsname'] as String? ?? '',
      partnumber: json['partnumber'] as String? ?? '',
      spquantity: (json['spquantity'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '',
      spnotes: json['spnotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toPayload() => {
        'sparepartsname': sparepartsname,
        'partnumber': partnumber,
        'spquantity': spquantity,
        'date': date,
        'spnotes': spnotes,
      };

  SparePartModel copyWith({
    int? id,
    String? sparepartsname,
    String? partnumber,
    int? spquantity,
    String? date,
    String? spnotes,
  }) {
    return SparePartModel(
      id: id ?? this.id,
      sparepartsname: sparepartsname ?? this.sparepartsname,
      partnumber: partnumber ?? this.partnumber,
      spquantity: spquantity ?? this.spquantity,
      date: date ?? this.date,
      spnotes: spnotes ?? this.spnotes,
    );
  }
}
