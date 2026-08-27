class ComplaintModel {
  final String id;
  final String title;
  final String studentId;
  final String studentName;
  final String hostelId;
  final String roomNumber;
  final String category;
  final String description;
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final DateTime createdAt;
  final String? response;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.studentId,
    required this.studentName,
    required this.hostelId,
    required this.roomNumber,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.response,
    this.resolvedAt,
  });

  Map<String, dynamic> toFirestoreFields() {
    return {
      'id': {'stringValue': id},
      'title': {'stringValue': title},
      'studentId': {'stringValue': studentId},
      'studentName': {'stringValue': studentName},
      'hostelId': {'stringValue': hostelId},
      'roomNumber': {'stringValue': roomNumber},
      'category': {'stringValue': category},
      'description': {'stringValue': description},
      'status': {'stringValue': status},
      'createdAt': {'stringValue': createdAt.toIso8601String()},
      if (response != null && response!.isNotEmpty)
        'response': {'stringValue': response!},
      if (resolvedAt != null)
        'resolvedAt': {'stringValue': resolvedAt!.toIso8601String()},
    };
  }

  factory ComplaintModel.fromFirestoreJson(String id, Map<String, dynamic> fields) {
    final title = fields['title']?['stringValue'] ?? fields['category']?['stringValue'] ?? 'Complaint';
    final studentId = fields['studentId']?['stringValue'] ?? '21BCSE042';
    final studentName = fields['studentName']?['stringValue'] ?? 'Student';
    final hostelId = fields['hostelId']?['stringValue'] ?? 'Hostel H4';
    final roomNumber = fields['roomNumber']?['stringValue'] ?? '204';
    final category = fields['category']?['stringValue'] ?? 'Food Quality';
    final description = fields['description']?['stringValue'] ?? '';
    final status = fields['status']?['stringValue'] ?? 'Pending';
    final createdAtStr = fields['createdAt']?['stringValue'] ?? '';
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final response = fields['response']?['stringValue'] ?? fields['managerResponse']?['stringValue'];
    final resolvedAtStr = fields['resolvedAt']?['stringValue'];
    final resolvedAt = resolvedAtStr != null ? DateTime.tryParse(resolvedAtStr) : null;

    return ComplaintModel(
      id: id,
      title: title,
      studentId: studentId,
      studentName: studentName,
      hostelId: hostelId,
      roomNumber: roomNumber,
      category: category,
      description: description,
      status: status,
      createdAt: createdAt,
      response: response,
      resolvedAt: resolvedAt,
    );
  }
}
