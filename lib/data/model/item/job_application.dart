class JobApplication {
  late int id;
  int? itemId;
  int? userId;
  String? fullName;
  String? email;
  String? mobile;
  String? resume;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? recruiterId;
  Item? item;
  Recruiter? recruiter;

  JobApplication(
      {required this.id,
        this.itemId,
        this.userId,
        this.fullName,
        this.email,
        this.mobile,
        this.resume,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.recruiterId,
        this.item,
        this.recruiter});

  JobApplication.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemId = json['item_id'];
    userId = json['user_id'];
    fullName = json['full_name'];
    email = json['email'];
    mobile = json['mobile'];
    resume = json['resume'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    recruiterId = json['recruiter_id'];
    item = json['item'] != null ? new Item.fromJson(json['item']) : null;
    recruiter = json['recruiter'] != null
        ? new Recruiter.fromJson(json['recruiter'])
        : null;
  }
}

class Item {
  int? id;
  String? name;
  int? userId;

  Item({this.id, this.name, this.userId});

  Item.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['user_id'] = this.userId;
    return data;
  }
}

class Recruiter {
  int? id;
  String? name;
  String? email;

  Recruiter({this.id, this.name, this.email});

  Recruiter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
  }
}
