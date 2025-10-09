// import 'package:flutter/material.dart';
// import 'package:pbl6mobile/model/services/remote/staff_service.dart';
// import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
// import 'package:pbl6mobile/shared/routes/routes.dart';
// import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
//
// class DoctorListPage extends StatefulWidget {
//   const DoctorListPage({super.key});
//
//   @override
//   State<DoctorListPage> createState() => _DoctorListPageState();
// }
//
// class _DoctorListPageState extends State<DoctorListPage> {
//   List<dynamic> _doctors = [];
//   bool _isLoading = true;
//   bool _isEmpty = false;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchDoctors();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//       });
//       _fetchDoctors();
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchDoctors() async {
//     setState(() => _isLoading = true);
//     final result ;//= await StaffService.getDoctors(search: _searchQuery);
//     if (mounted) {
//       setState(() {
//         _doctors = result['data'] ?? [];
//         _isEmpty = _doctors.isEmpty;
//         _isLoading = false;
//       });
//     }
//   }
//
//
//   void _showDeleteDialog(dynamic doctor) {
//     final TextEditingController passwordController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: context.theme.popover,
//         title: Text('Xác nhận xóa', style: TextStyle(color: context.theme.popoverForeground)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Bạn có chắc chắn muốn xóa tài khoản: ${doctor['fullName']}?',
//               style: TextStyle(color: context.theme.popoverForeground),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: passwordController,
//               obscureText: true,
//               style: TextStyle(color: context.theme.input),
//               decoration: InputDecoration(
//                 labelText: 'Nhập mật khẩu của bạn',
//                 labelStyle: TextStyle(color: context.theme.mutedForeground),
//                 border: OutlineInputBorder(
//                   borderSide: BorderSide(color: context.theme.border),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: context.theme.ring),
//                 ),
//                 filled: true,
//                 fillColor: context.theme.input,
//               ),
//               onSubmitted: (_) => _confirmDelete(doctor, passwordController.text),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
//           ),
//           TextButton(
//             onPressed: () => _confirmDelete(doctor, passwordController.text),
//             child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _confirmDelete(dynamic doctor, String password) async {
//     final success = await StaffService.deleteStaff(doctor['id'], password: password);
//     Navigator.pop(context);
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Xóa tài khoản thành công!', style: TextStyle(color: context.theme.primaryForeground)),
//           backgroundColor: context.theme.green,
//         ),
//       );
//       _fetchDoctors();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.',
//             style: TextStyle(color: context.theme.destructiveForeground),
//           ),
//           backgroundColor: context.theme.destructive,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: context.theme.blue,
//         title: Text(
//           'Quản lý tài khoản bác sĩ',
//           style: TextStyle(color: context.theme.primaryForeground),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
//             onPressed: _fetchDoctors,
//           ),
//         ],
//       ),
//       backgroundColor: context.theme.bg,
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _searchController,
//                   style: TextStyle(color: context.theme.textColor),
//                   decoration: InputDecoration(
//                     labelText: 'Tìm kiếm theo tên hoặc email',
//                     labelStyle: TextStyle(color: context.theme.mutedForeground),
//                     prefixIcon: Icon(Icons.search, color: context.theme.primary),
//                     border: OutlineInputBorder(
//                       borderSide: BorderSide(color: context.theme.border),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: context.theme.ring),
//                     ),
//                     filled: true,
//                     fillColor: context.theme.input,
//                     suffixIcon: _searchQuery.isNotEmpty
//                         ? IconButton(
//                       icon: Icon(Icons.clear, color: context.theme.primary),
//                       onPressed: () {
//                         _searchController.clear();
//                         setState(() => _searchQuery = '');
//                         _fetchDoctors();
//                       },
//                     )
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 CustomButtonBlue(
//                   onTap: () => Navigator.pushNamed(context, Routes.createDoctor),
//                   text: 'Tạo tài khoản bác sĩ',
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator(color: context.theme.primary))
//                 : _isEmpty
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.admin_panel_settings_outlined, size: 64, color: context.theme.muted),
//                   const SizedBox(height: 16),
//                   Text(
//                     _searchQuery.isNotEmpty
//                         ? 'Không tìm thấy tài khoản bác sĩ phù hợp'
//                         : 'Danh sách tài khoản bác sĩ trống',
//                     style: TextStyle(fontSize: 18, color: context.theme.mutedForeground),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             )
//                 : ListView.builder(
//               itemCount: _doctors.length,
//               itemBuilder: (context, index) {
//                 final doctor = _doctors[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                   color: context.theme.card,
//                   child: ListTile(
//                     textColor: context.theme.cardForeground,
//                     leading: CircleAvatar(
//                       backgroundColor: context.theme.primary,
//                       child: Text(
//                         doctor['fullName']?[0].toUpperCase() ?? 'A',
//                         style: TextStyle(color: context.theme.primaryForeground),
//                       ),
//                     ),
//                     title: Text(
//                       doctor['fullName'] ?? 'N/A',
//                       style: TextStyle(color: context.theme.cardForeground),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(doctor['email'] ?? 'N/A', style: TextStyle(color: context.theme.mutedForeground)),
//                         Text('Vai trò: ${doctor['role'] ?? 'DOCTOR'}', style: TextStyle(color: context.theme.mutedForeground)),
//                         if (doctor['phone'] != null) Text('SĐT: ${doctor['phone']}', style: TextStyle(color: context.theme.mutedForeground)),
//                       ],
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.edit, color: context.theme.primary),
//                           onPressed: () => Navigator.pushNamed(
//                             context,
//                             Routes.updateDoctor,
//                             arguments: doctor,
//                           ),
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.delete, color: context.theme.destructive),
//                           onPressed: () => _showDeleteDialog(doctor),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }