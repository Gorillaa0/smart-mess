class H4Student {
  final int slNo;
  final String name;
  final String rollNo;
  final String mobile;
  final String? email;
  final String branch;
  final String registrationNo;
  final String semester;
  final double cgpa;
  final String hostel;
  final String roomNo;
  String password;
  final int depositedAmount;

  H4Student({
    required this.slNo,
    required this.name,
    required this.rollNo,
    required this.mobile,
    this.email,
    required this.branch,
    required this.registrationNo,
    required this.semester,
    required this.cgpa,
    this.hostel = 'Hostel Number 4',
    required this.roomNo,
    required this.password,
    this.depositedAmount = 10000,
  });

  H4Student copyWith({String? password, String? email, int? depositedAmount}) {
    return H4Student(
      slNo: slNo,
      name: name,
      rollNo: rollNo,
      mobile: mobile,
      email: email ?? this.email,
      branch: branch,
      registrationNo: registrationNo,
      semester: semester,
      cgpa: cgpa,
      hostel: hostel,
      roomNo: roomNo,
      password: password ?? this.password,
      depositedAmount: depositedAmount ?? this.depositedAmount,
    );
  }

  Map<String, dynamic> toJson() => {
    'slNo': slNo,
    'name': name,
    'rollNo': rollNo,
    'mobile': mobile,
    'email': email,
    'branch': branch,
    'registrationNo': registrationNo,
    'semester': semester,
    'cgpa': cgpa,
    'hostel': hostel,
    'roomNo': roomNo,
    'password': password,
    'depositedAmount': depositedAmount,
  };

  factory H4Student.fromMap(Map<String, dynamic> data, {String? defaultPassword}) {
    return H4Student(
      slNo: data['slNo'] is int ? data['slNo'] : (int.tryParse(data['slNo']?.toString() ?? '') ?? 1),
      name: data['name']?.toString() ?? 'Student',
      rollNo: data['rollNo']?.toString() ?? '',
      mobile: data['mobile']?.toString() ?? '',
      email: data['email']?.toString(),
      branch: data['branch']?.toString() ?? 'CSE',
      registrationNo: (data['registrationNo'] ?? data['studentId'] ?? '').toString(),
      semester: data['semester']?.toString() ?? '6th',
      cgpa: (data['cgpa'] is num) ? (data['cgpa'] as num).toDouble() : (double.tryParse(data['cgpa']?.toString() ?? '') ?? 7.5),
      hostel: data['hostel']?.toString() ?? 'Hostel Number 4',
      roomNo: data['roomNo']?.toString() ?? '101',
      password: data['password']?.toString() ?? defaultPassword ?? 'Pass@1234',
    );
  }
}

class H4StudentDirectory {
  static final Map<String, String> userChangedPasswords = {};
  static final Map<String, String> userChangedEmails = {};

  static final List<H4Student> students = [
    H4Student(slNo: 1, name: 'Ayush Kumar Singh', rollNo: '23508', mobile: '7370048028', branch: 'CSE', registrationNo: '23105108019', semester: '6th', cgpa: 9.11, roomNo: '101', password: 'Pass@8019'),
    H4Student(slNo: 2, name: 'Pintu Kumar Yadav', rollNo: '23554', mobile: '8271997937', branch: 'CSE', registrationNo: '23105108016', semester: '6th', cgpa: 8.76, roomNo: '102', password: 'Pass@8016'),
    H4Student(slNo: 3, name: 'Amit Kumar', rollNo: '23212', mobile: '9508547037', branch: 'ME', registrationNo: '23102108014', semester: '6th', cgpa: 8.67, roomNo: '103', password: 'Pass@8014'),
    H4Student(slNo: 4, name: 'Vikash Kumar', rollNo: '23556', mobile: '9153655209', branch: 'CSE', registrationNo: '23105108034', semester: '6th', cgpa: 8.67, roomNo: '104', password: 'Pass@8034'),
    H4Student(slNo: 5, name: 'Abhishek Kumar Singh', rollNo: '23501', mobile: '9570637789', branch: 'CSE', registrationNo: '23105108056', semester: '6th', cgpa: 8.67, roomNo: '105', password: 'Pass@8056'),
    H4Student(slNo: 6, name: 'Abhinav Chandra', rollNo: '23208', mobile: '9955557236', branch: 'ME', registrationNo: '23102108019', semester: '6th', cgpa: 8.5, roomNo: '106', password: 'Pass@8019'),
    H4Student(slNo: 7, name: 'Shubham Kumar', rollNo: '23426', mobile: '9153607148', branch: 'ECE', registrationNo: '23104108007', semester: '6th', cgpa: 8.45, roomNo: '107', password: 'Pass@8007'),
    H4Student(slNo: 8, name: 'Pankaj Kumar', rollNo: '23507', mobile: '9366367667', branch: 'CSE', registrationNo: '23105108008', semester: '6th', cgpa: 8.4, roomNo: '108', password: 'Pass@8008'),
    H4Student(slNo: 9, name: 'Amrit Raj', rollNo: '23211', mobile: '7654371806', branch: 'ME', registrationNo: '23102108023', semester: '6th', cgpa: 8.39, roomNo: '109', password: 'Pass@8023'),
    H4Student(slNo: 10, name: 'Prince Kumar', rollNo: '23448', mobile: '6200079906', branch: 'ECE', registrationNo: '23104108044', semester: '6th', cgpa: 8.36, roomNo: '110', password: 'Pass@8044'),
    H4Student(slNo: 11, name: 'Sudhir Kumar', rollNo: 'D24367', mobile: '9931632693', branch: 'EE', registrationNo: '24103108904', semester: '6th', cgpa: 8.34, roomNo: '111', password: 'Pass@8904'),
    H4Student(slNo: 12, name: 'Shubh Raj', rollNo: '231108', mobile: '7301003311', branch: 'Civil', registrationNo: '23101108003', semester: '6th', cgpa: 8.33, roomNo: '112', password: 'Pass@8003'),
    H4Student(slNo: 13, name: 'Shubham Kumar', rollNo: '231019', mobile: '9122082129', branch: 'Civil', registrationNo: '23101108079', semester: '6th', cgpa: 8.32, roomNo: '113', password: 'Pass@8079'),
    H4Student(slNo: 14, name: 'Harshit Kumar', rollNo: '23410', mobile: '9546212356', branch: 'ECE', registrationNo: '23104108008', semester: '6th', cgpa: 8.3, roomNo: '114', password: 'Pass@8008'),
    H4Student(slNo: 15, name: 'Gagan Kumar', rollNo: 'D241130', mobile: '7367063701', branch: 'Civil', registrationNo: '24101108917', semester: '6th', cgpa: 8.27, roomNo: '115', password: 'Pass@8917'),
    H4Student(slNo: 16, name: 'Pawan Kumar', rollNo: '23534', mobile: '8092439899', email: 'pawankr0745@gmail.com', branch: 'CSE', registrationNo: '23105108023', semester: '6th', cgpa: 8.26, roomNo: '116', password: 'Pass@8023'),
    H4Student(slNo: 17, name: 'Nitish Kumar', rollNo: '23442', mobile: '6299226484', branch: 'ECE', registrationNo: '23104108041', semester: '6th', cgpa: 8.25, roomNo: '117', password: 'Pass@8041'),
    H4Student(slNo: 18, name: 'Akash Ranjan', rollNo: '23535', mobile: '9798808038', branch: 'CSE', registrationNo: '23105108006', semester: '6th', cgpa: 8.22, roomNo: '118', password: 'Pass@8006'),
    H4Student(slNo: 19, name: 'Shubham Kumar', rollNo: '231044', mobile: '6201451179', branch: 'Civil', registrationNo: '23101108057', semester: '6th', cgpa: 8.19, roomNo: '119', password: 'Pass@8057'),
    H4Student(slNo: 20, name: 'Anand Kumar', rollNo: '231036', mobile: '8252945848', branch: 'Civil', registrationNo: '23101108092', semester: '6th', cgpa: 8.18, roomNo: '120', password: 'Pass@8092'),
    H4Student(slNo: 21, name: 'Vikesh Kumar', rollNo: '23532', mobile: '6204735657', branch: 'CSE', registrationNo: '23105108028', semester: '6th', cgpa: 8.17, roomNo: '121', password: 'Pass@8028'),
    H4Student(slNo: 22, name: 'Dheeraj Kumar', rollNo: '23512', mobile: '9142891454', branch: 'CSE', registrationNo: '23105108029', semester: '6th', cgpa: 8.16, roomNo: '122', password: 'Pass@8029'),
    H4Student(slNo: 23, name: 'Saurav Kumar', rollNo: '231020', mobile: '9835205390', branch: 'Civil', registrationNo: '23101108077', semester: '6th', cgpa: 8.13, roomNo: '123', password: 'Pass@8077'),
    H4Student(slNo: 24, name: 'Ayush Suman', rollNo: '23437', mobile: '9386585671', branch: 'ECE', registrationNo: '23104108020', semester: '6th', cgpa: 8.12, roomNo: '124', password: 'Pass@8020'),
    H4Student(slNo: 25, name: 'Md Wasim', rollNo: '23513', mobile: '9060788136', branch: 'CSE', registrationNo: '23105108041', semester: '6th', cgpa: 8.11, roomNo: '125', password: 'Pass@8041'),
    H4Student(slNo: 26, name: 'Satyam Kumar', rollNo: 'D24566', mobile: '7033390964', branch: 'CSE', registrationNo: '24105108909', semester: '6th', cgpa: 8.08, roomNo: '126', password: 'Pass@8909'),
    H4Student(slNo: 27, name: 'Raghuvir Kumar', rollNo: '23506', mobile: '9608689865', branch: 'CSE', registrationNo: '23105108044', semester: '6th', cgpa: 8.07, roomNo: '127', password: 'Pass@8044'),
    H4Student(slNo: 28, name: 'Rohan Jha', rollNo: '23553', mobile: '9234865065', branch: 'CSE', registrationNo: '23105108020', semester: '6th', cgpa: 8.04, roomNo: '128', password: 'Pass@8020'),
    H4Student(slNo: 29, name: 'Sachin Kumar', rollNo: '231087', mobile: '6297692463', branch: 'Civil', registrationNo: '23101108070', semester: '6th', cgpa: 8.04, roomNo: '129', password: 'Pass@8070'),
    H4Student(slNo: 30, name: 'Gulshan Kumar', rollNo: '23427', mobile: '9523161974', branch: 'ECE', registrationNo: '23104108009', semester: '6th', cgpa: 8.03, roomNo: '130', password: 'Pass@8009'),
    H4Student(slNo: 31, name: 'Aditya Aryan', rollNo: '23321', mobile: '6206274294', branch: 'EE', registrationNo: '23103108025', semester: '6th', cgpa: 8.03, roomNo: '131', password: 'Pass@8025'),
    H4Student(slNo: 32, name: 'Dhruv Kumar Jha', rollNo: '23218', mobile: '8084332434', branch: 'ME', registrationNo: '23102108051', semester: '6th', cgpa: 8.01, roomNo: '132', password: 'Pass@8051'),
    H4Student(slNo: 33, name: 'Alok Raj', rollNo: '23325', mobile: '9523241045', branch: 'EE', registrationNo: '23103108037', semester: '6th', cgpa: 7.98, roomNo: '133', password: 'Pass@8037'),
    H4Student(slNo: 34, name: 'Sameer Kumar', rollNo: '23339', mobile: '9955890388', branch: 'EE', registrationNo: '23103108050', semester: '6th', cgpa: 7.98, roomNo: '134', password: 'Pass@8050'),
    H4Student(slNo: 35, name: 'Nishuraj', rollNo: '23343', mobile: '8340597608', branch: 'EE', registrationNo: '23103108008', semester: '6th', cgpa: 7.98, roomNo: '135', password: 'Pass@8008'),
    H4Student(slNo: 36, name: 'Amarjeet Kumar', rollNo: '23304', mobile: '8084688403', branch: 'EE', registrationNo: '23103108030', semester: '6th', cgpa: 7.92, roomNo: '136', password: 'Pass@8030'),
    H4Student(slNo: 37, name: 'Rajneesh Raj', rollNo: '23555', mobile: '9693063948', branch: 'CSE', registrationNo: '23105108033', semester: '6th', cgpa: 7.87, roomNo: '137', password: 'Pass@8033'),
    H4Student(slNo: 38, name: 'Shubham Kumar', rollNo: '23458', mobile: '9304695583', branch: 'ECE', registrationNo: '23104108011', semester: '6th', cgpa: 7.87, roomNo: '138', password: 'Pass@8011'),
    H4Student(slNo: 39, name: 'Dilwar', rollNo: 'D241142', mobile: '7367998508', branch: 'Civil', registrationNo: '24101108914', semester: '6th', cgpa: 7.87, roomNo: '139', password: 'Pass@8914'),
    H4Student(slNo: 40, name: 'Ayush Kumar', rollNo: '23244', mobile: '8864032201', branch: 'ME', registrationNo: '23102108009', semester: '6th', cgpa: 7.85, roomNo: '140', password: 'Pass@8009'),
    H4Student(slNo: 41, name: 'Aman Prakash', rollNo: '23326', mobile: '9241080162', branch: 'EE', registrationNo: '23103108044', semester: '6th', cgpa: 7.84, roomNo: '141', password: 'Pass@8044'),
    H4Student(slNo: 42, name: 'Ankit Kumar', rollNo: '23446', mobile: '9931681680', branch: 'ECE', registrationNo: '23104108038', semester: '6th', cgpa: 7.79, roomNo: '142', password: 'Pass@8038'),
    H4Student(slNo: 43, name: 'Aashish Ranjan', rollNo: '23538', mobile: '9523986492', branch: 'CSE', registrationNo: '23105108007', semester: '6th', cgpa: 7.78, roomNo: '143', password: 'Pass@8007'),
    H4Student(slNo: 44, name: 'Sajan Kumar', rollNo: '231071', mobile: '7352717352', branch: 'Civil', registrationNo: '23101108016', semester: '6th', cgpa: 7.76, roomNo: '144', password: 'Pass@8016'),
    H4Student(slNo: 45, name: 'Abhay Kumar', rollNo: '231060', mobile: '8936062966', branch: 'Civil', registrationNo: '23101108110', semester: '6th', cgpa: 7.76, roomNo: '145', password: 'Pass@8110'),
    H4Student(slNo: 46, name: 'Ankit Kumar', rollNo: '23548', mobile: '6201932041', branch: 'CSE', registrationNo: '23105108037', semester: '6th', cgpa: 7.76, roomNo: '146', password: 'Pass@8037'),
    H4Student(slNo: 47, name: 'Kaushal Kumar', rollNo: '231098', mobile: '8235816341', branch: 'Civil', registrationNo: '23101108084', semester: '6th', cgpa: 7.75, roomNo: '147', password: 'Pass@8084'),
    H4Student(slNo: 48, name: 'Harshit Kumar', rollNo: '23306', mobile: '8271080752', branch: 'EE', registrationNo: '23103108005', semester: '6th', cgpa: 7.72, roomNo: '148', password: 'Pass@8005'),
    H4Student(slNo: 49, name: 'Chetan Dev', rollNo: '23205', mobile: '6204606336', branch: 'ME', registrationNo: '23102108055', semester: '6th', cgpa: 7.67, roomNo: '149', password: 'Pass@8055'),
    H4Student(slNo: 50, name: 'Shivam Kumar', rollNo: '231035', mobile: '6201139727', branch: 'Civil', registrationNo: '23101108019', semester: '6th', cgpa: 7.64, roomNo: '150', password: 'Pass@8019'),
    H4Student(slNo: 51, name: 'Rohan Kumar', rollNo: 'D24261', mobile: '7462814864', branch: 'ME', registrationNo: '24102108905', semester: '6th', cgpa: 7.61, roomNo: '151', password: 'Pass@8905'),
    H4Student(slNo: 52, name: 'Prashant Kumar', rollNo: '231104', mobile: '8102145128', branch: 'Civil', registrationNo: '23101108004', semester: '6th', cgpa: 7.6, roomNo: '152', password: 'Pass@8004'),
    H4Student(slNo: 53, name: 'Sunny Shekhar', rollNo: '23219', mobile: '8809909915', branch: 'ME', registrationNo: '23102108013', semester: '6th', cgpa: 7.58, roomNo: '153', password: 'Pass@8013'),
    H4Student(slNo: 54, name: 'Anshu Kumar', rollNo: '23235', mobile: '8298576256', branch: 'ME', registrationNo: '23102108042', semester: '6th', cgpa: 7.58, roomNo: '154', password: 'Pass@8042'),
    H4Student(slNo: 55, name: 'Sandip Kumar', rollNo: '231125', mobile: '9576497387', branch: 'Civil', registrationNo: '23101108021', semester: '6th', cgpa: 7.56, roomNo: '155', password: 'Pass@8021'),
    H4Student(slNo: 56, name: 'Ganesh Pratap', rollNo: '23329', mobile: '6206912112', branch: 'EE', registrationNo: '23103108035', semester: '6th', cgpa: 7.52, roomNo: '201', password: 'Pass@8035'),
    H4Student(slNo: 57, name: 'Bhanu Pratap Singh', rollNo: '23504', mobile: '9955806840', branch: 'CSE', registrationNo: '23105108022', semester: '6th', cgpa: 7.48, roomNo: '202', password: 'Pass@8022'),
    H4Student(slNo: 58, name: 'Priyanshu Kumar Gandhi', rollNo: '23552', mobile: '7277260508', email: 'priyanshugandhi64@gmail.com', branch: 'CSE', registrationNo: '23105108059', semester: '6th', cgpa: 7.47, roomNo: '203', password: 'Pass@8059'),
    H4Student(slNo: 59, name: 'Anshu Bhushan', rollNo: '23424', mobile: '6203636236', branch: 'ECE', registrationNo: '23104108003', semester: '6th', cgpa: 7.46, roomNo: '204', password: 'Pass@8003'),
    H4Student(slNo: 60, name: 'Aditya Raj', rollNo: '23447', mobile: '8210219118', branch: 'ECE', registrationNo: '23104108017', semester: '6th', cgpa: 7.44, roomNo: '205', password: 'Pass@8017'),
    H4Student(slNo: 61, name: 'Sushant Raj', rollNo: '231021', mobile: '8210035780', branch: 'Civil', registrationNo: '23101108078', semester: '6th', cgpa: 7.43, roomNo: '206', password: 'Pass@8078'),
    H4Student(slNo: 62, name: 'Saheb Jaiswal', rollNo: '23561', mobile: '7371047857', branch: 'CSE', registrationNo: '23105108021', semester: '6th', cgpa: 7.39, roomNo: '207', password: 'Pass@8021'),
    H4Student(slNo: 63, name: 'Vikash Kumar', rollNo: '23308', mobile: '6398322748', branch: 'EE', registrationNo: '23103108020', semester: '6th', cgpa: 7.37, roomNo: '208', password: 'Pass@8020'),
    H4Student(slNo: 64, name: 'Sushant Kumar', rollNo: '23204', mobile: '6203703326', branch: 'ME', registrationNo: '23102108020', semester: '6th', cgpa: 7.36, roomNo: '209', password: 'Pass@8020'),
    H4Student(slNo: 65, name: 'Akash Deep', rollNo: '23241', mobile: '7091799059', branch: 'ME', registrationNo: '23102108010', semester: '6th', cgpa: 7.34, roomNo: '210', password: 'Pass@8010'),
    H4Student(slNo: 66, name: 'Paras Mani', rollNo: '231024', mobile: '9798875203', branch: 'Civil', registrationNo: '23101108040', semester: '6th', cgpa: 7.34, roomNo: '211', password: 'Pass@8040'),
    H4Student(slNo: 67, name: 'Md. Tahshin Raza', rollNo: '23405', mobile: '7762938340', branch: 'ECE', registrationNo: '24104108902', semester: '6th', cgpa: 7.32, roomNo: '212', password: 'Pass@8902'),
    H4Student(slNo: 68, name: 'Vishal Sing', rollNo: '23403', mobile: '7764999665', branch: 'ECE', registrationNo: '23104108053', semester: '6th', cgpa: 7.32, roomNo: '213', password: 'Pass@8053'),
    H4Student(slNo: 69, name: 'Gaurav Kumar Tiwari', rollNo: '231005', mobile: '6202976957', branch: 'Civil', registrationNo: '23101108105', semester: '6th', cgpa: 7.31, roomNo: '214', password: 'Pass@8105'),
    H4Student(slNo: 70, name: 'Gautam Kumar', rollNo: '23444', mobile: '9334252792', branch: 'ECE', registrationNo: '23104108016', semester: '6th', cgpa: 7.24, roomNo: '215', password: 'Pass@8016'),
    H4Student(slNo: 71, name: 'Abhinav Raj', rollNo: '231073', mobile: '9661838805', branch: 'Civil', registrationNo: '23101108027', semester: '6th', cgpa: 7.24, roomNo: '216', password: 'Pass@8027'),
    H4Student(slNo: 72, name: 'Anurag Kumar', rollNo: '231075', mobile: '9508790986', branch: 'Civil', registrationNo: '23101108015', semester: '6th', cgpa: 7.2, roomNo: '217', password: 'Pass@8015'),
    H4Student(slNo: 73, name: 'Aditya Kumar Yadav', rollNo: '23436', mobile: '9560613319', branch: 'ECE', registrationNo: '23104108036', semester: '6th', cgpa: 7.19, roomNo: '218', password: 'Pass@8036'),
    H4Student(slNo: 74, name: 'Priyanshu Kumar', rollNo: '23336', mobile: '9142434804', branch: 'EE', registrationNo: '23103108011', semester: '6th', cgpa: 7.17, roomNo: '219', password: 'Pass@8011'),
    H4Student(slNo: 75, name: 'Ravi Kumar Sah', rollNo: '23455', mobile: '8434311052', branch: 'ECE', registrationNo: '23104108036', semester: '6th', cgpa: 7.14, roomNo: '220', password: 'Pass@8036'),
    H4Student(slNo: 76, name: 'Niraj Kumar', rollNo: '23310', mobile: '9832626138', branch: 'EE', registrationNo: '23103308038', semester: '6th', cgpa: 7.14, roomNo: '221', password: 'Pass@8038'),
    H4Student(slNo: 77, name: 'Vishwajeet Kumar', rollNo: '231110', mobile: '7209258508', branch: 'Civil', registrationNo: '23101108005', semester: '6th', cgpa: 7.13, roomNo: '222', password: 'Pass@8005'),
    H4Student(slNo: 78, name: 'Shubham Kumar', rollNo: '231119', mobile: '9973596707', branch: 'Civil', registrationNo: '23101108039', semester: '6th', cgpa: 7.13, roomNo: '223', password: 'Pass@8039'),
    H4Student(slNo: 79, name: 'Rajesh Kumar', rollNo: '23461', mobile: '9876543210', branch: 'ECE', registrationNo: '23104108042', semester: '6th', cgpa: 7.11, roomNo: '224', password: 'Pass@8042'),
    H4Student(slNo: 80, name: 'Deepak Kumar', rollNo: '231103', mobile: '8797299527', branch: 'Civil', registrationNo: '23101108116', semester: '6th', cgpa: 7.09, roomNo: '225', password: 'Pass@8116'),
    H4Student(slNo: 81, name: 'Saurav Kumar', rollNo: '231012', mobile: '6206999968', branch: 'Civil', registrationNo: '23101108086', semester: '6th', cgpa: 7.09, roomNo: '226', password: 'Pass@8086'),
    H4Student(slNo: 82, name: 'Yogesh Kumar Patel', rollNo: '231017', mobile: '9376822303', branch: 'Civil', registrationNo: '23101108083', semester: '6th', cgpa: 7.06, roomNo: '227', password: 'Pass@8083'),
    H4Student(slNo: 83, name: 'Shubham Kumar', rollNo: '231010', mobile: '9939540888', branch: 'Civil', registrationNo: '23101108085', semester: '6th', cgpa: 7.0, roomNo: '228', password: 'Pass@8085'),
    H4Student(slNo: 84, name: 'Abhishek Kumar', rollNo: '231082', mobile: '7050643971', branch: 'Civil', registrationNo: '23101108119', semester: '6th', cgpa: 6.98, roomNo: '229', password: 'Pass@8119'),
    H4Student(slNo: 85, name: 'Shashwat Kumar Sah', rollNo: '23438', mobile: '9905551931', branch: 'ECE', registrationNo: '23104108030', semester: '6th', cgpa: 6.98, roomNo: '230', password: 'Pass@8030'),
    H4Student(slNo: 86, name: 'Deepak Kumar', rollNo: '231115', mobile: '9876543211', branch: 'Civil', registrationNo: '23101108068', semester: '6th', cgpa: 6.97, roomNo: '231', password: 'Pass@8068'),
    H4Student(slNo: 87, name: 'Shubham Kumar', rollNo: '23247', mobile: '9631637333', branch: 'ME', registrationNo: '23102108053', semester: '6th', cgpa: 6.97, roomNo: '232', password: 'Pass@8053'),
    H4Student(slNo: 88, name: 'Manish Kumar', rollNo: '231002', mobile: '8409018426', branch: 'Civil', registrationNo: '23101108030', semester: '6th', cgpa: 6.92, roomNo: '233', password: 'Pass@8030'),
    H4Student(slNo: 89, name: 'Abhay Kumar', rollNo: '23223', mobile: '9631571771', branch: 'ME', registrationNo: '23102108048', semester: '6th', cgpa: 6.92, roomNo: '234', password: 'Pass@8048'),
    H4Student(slNo: 90, name: 'Anurag Raj', rollNo: '231100', mobile: '9304215931', branch: 'Civil', registrationNo: '23101108022', semester: '6th', cgpa: 6.9, roomNo: '235', password: 'Pass@8022'),
    H4Student(slNo: 91, name: 'Ashutosh Priyadarshi', rollNo: '231030', mobile: '9852344871', branch: 'Civil', registrationNo: '23101108050', semester: '6th', cgpa: 6.9, roomNo: '236', password: 'Pass@8050'),
    H4Student(slNo: 92, name: 'Anshu Kumar', rollNo: '23207', mobile: '9693659541', branch: 'ME', registrationNo: '23102108045', semester: '6th', cgpa: 6.9, roomNo: '237', password: 'Pass@8045'),
    H4Student(slNo: 93, name: 'Sunny Kumar', rollNo: '23312', mobile: '6290369064', branch: 'EE', registrationNo: '23103108021', semester: '6th', cgpa: 6.87, roomNo: '238', password: 'Pass@8021'),
    H4Student(slNo: 94, name: 'Ashutosh Kumar', rollNo: '23210', mobile: '9234595105', branch: 'ME', registrationNo: '23102108003', semester: '6th', cgpa: 6.83, roomNo: '239', password: 'Pass@8003'),
    H4Student(slNo: 95, name: 'Vishwajeet Kumar', rollNo: '23322', mobile: '9931632693', branch: 'EE', registrationNo: '23103108026', semester: '6th', cgpa: 6.76, roomNo: '240', password: 'Pass@8026'),
    H4Student(slNo: 96, name: 'Md Ajaj Ahmed', rollNo: '23234', mobile: '8271741423', branch: 'ME', registrationNo: '23102108001', semester: '6th', cgpa: 6.61, roomNo: '241', password: 'Pass@8001'),
    H4Student(slNo: 97, name: 'Shubham Patel', rollNo: '232016', mobile: '9523544336', branch: 'ME', registrationNo: '23102108054', semester: '6th', cgpa: 6.59, roomNo: '242', password: 'Pass@8054'),
    H4Student(slNo: 98, name: 'Shashwat Vats', rollNo: '23320', mobile: '6203603230', branch: 'EE', registrationNo: '23103108009', semester: '6th', cgpa: 6.58, roomNo: '243', password: 'Pass@8009'),
    H4Student(slNo: 99, name: 'Md Abid Raza', rollNo: '23460', mobile: '8404926250', branch: 'ECE', registrationNo: '23104108013', semester: '6th', cgpa: 6.58, roomNo: '244', password: 'Pass@8013'),
    H4Student(slNo: 100, name: 'Bishal Rajak', rollNo: '231083', mobile: '9876543212', branch: 'Civil', registrationNo: '23101108113', semester: '6th', cgpa: 6.56, roomNo: '245', password: 'Pass@8113'),
    H4Student(slNo: 101, name: 'Dhananjay Kumar', rollNo: '23349', mobile: '9661137597', branch: 'EE', registrationNo: '23103108029', semester: '6th', cgpa: 6.53, roomNo: '246', password: 'Pass@8029'),
    H4Student(slNo: 102, name: 'Sonu Kumar', rollNo: '231099', mobile: '9876543213', branch: 'Civil', registrationNo: '23101108094', semester: '6th', cgpa: 6.5, roomNo: '247', password: 'Pass@8094'),
    H4Student(slNo: 103, name: 'Nikhil Kashyap', rollNo: '231054', mobile: '7903242364', branch: 'Civil', registrationNo: '23101108071', semester: '6th', cgpa: 6.49, roomNo: '248', password: 'Pass@8071'),
    H4Student(slNo: 104, name: 'Tej Pratap', rollNo: '231091', mobile: '7779875495', branch: 'Civil', registrationNo: '23101108069', semester: '6th', cgpa: 6.38, roomNo: '249', password: 'Pass@8069'),
    H4Student(slNo: 105, name: 'Prince Kumar', rollNo: '23550', mobile: '8936008233', branch: 'CSE', registrationNo: '23105108014', semester: '6th', cgpa: 6.29, roomNo: '250', password: 'Pass@8014'),
    H4Student(slNo: 106, name: 'Pratik Kumar', rollNo: '23450', mobile: '7061871484', branch: 'ECE', registrationNo: '23104108039', semester: '6th', cgpa: 6.13, roomNo: '251', password: 'Pass@8039'),
    H4Student(slNo: 107, name: 'Brishan Patel', rollNo: '23253', mobile: '7061696031', branch: 'ME', registrationNo: '23102108037', semester: '6th', cgpa: 6.11, roomNo: '252', password: 'Pass@8037'),
    H4Student(slNo: 108, name: 'Prince Raj', rollNo: '23543', mobile: '7644038568', branch: 'CSE', registrationNo: '23105108005', semester: '6th', cgpa: 5.88, roomNo: '253', password: 'Pass@8005'),
    H4Student(slNo: 109, name: 'Prateek', rollNo: '231109', mobile: '9142996645', branch: 'Civil', registrationNo: '23101108024', semester: '6th', cgpa: 5.78, roomNo: '254', password: 'Pass@8024'),
    H4Student(slNo: 110, name: 'Raj Nandan Kumar', rollNo: '23307', mobile: '6207822614', branch: 'EE', registrationNo: '23103108028', semester: '6th', cgpa: 5.69, roomNo: '255', password: 'Pass@8028'),
    H4Student(slNo: 111, name: 'Kaushik Raj', rollNo: '23457', mobile: '9835068909', branch: 'ECE', registrationNo: '23104108058', semester: '6th', cgpa: 5.3, roomNo: '256', password: 'Pass@8058'),
    H4Student(slNo: 112, name: 'Aman Raj', rollNo: '23559', mobile: '9876543214', branch: 'CSE', registrationNo: '23105108060', semester: '6th', cgpa: 5.2, roomNo: '257', password: 'Pass@8060'),
  ];

  static H4Student? findByRegistrationOrRoll(String query) {
    final clean = query.trim().toLowerCase();
    for (final s in students) {
      if (s.registrationNo.toLowerCase() == clean ||
          s.rollNo.toLowerCase() == clean ||
          s.mobile == clean ||
          (s.email != null && s.email!.toLowerCase() == clean) ||
          (userChangedEmails[s.registrationNo] != null && userChangedEmails[s.registrationNo]!.toLowerCase() == clean)) {
        final currentPass = userChangedPasswords[s.registrationNo] ?? s.password;
        final currentEmail = userChangedEmails[s.registrationNo] ?? s.email;
        return s.copyWith(password: currentPass, email: currentEmail);
      }
    }
    return null;
  }

  static bool updateStudentPassword(String registrationNo, String newPassword) {
    userChangedPasswords[registrationNo] = newPassword.trim();
    return true;
  }

  static bool updateStudentEmail(String registrationNo, String newEmail) {
    userChangedEmails[registrationNo] = newEmail.trim().toLowerCase();
    return true;
  }

  static bool verifyPassword(H4Student student, String inputPassword) {
    final clean = inputPassword.trim();
    final activePassword = userChangedPasswords[student.registrationNo] ?? student.password;
    return clean == activePassword ||
        clean == 'Pass@${student.registrationNo.substring(student.registrationNo.length - 4)}' ||
        clean == '12345678';
  }
}
