import 'package:flutter/material.dart';

import 'package:page_transition/page_transition.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/view/appointment/list_appointment_page.dart';
import 'package:pbl6mobile/view/change_password/change_password.dart';
import 'package:pbl6mobile/view/doctor_management/doctor_detail_page.dart';
import 'package:pbl6mobile/view/doctor_management/edit_doctor_profile_page.dart';
import 'package:pbl6mobile/view/main_page/doctor/main_page_doctor.dart';
import 'package:pbl6mobile/view/main_page/super_admin/main_page_super_admin.dart';
import 'package:pbl6mobile/view/patient_management/create_patient_page.dart';
import 'package:pbl6mobile/view/patient_management/list_patient_page.dart';
import 'package:pbl6mobile/view/patient_management/update_patient_page.dart';
import 'package:pbl6mobile/view/setting/doctor/account_doctor_page.dart';
import 'package:pbl6mobile/view/setting/doctor/edit_account_doctor_page.dart';
import 'package:pbl6mobile/view/setting/doctor/profile_doctor_page.dart';
import 'package:pbl6mobile/view/setting/super_admin/setting_supperadmin_page.dart';
import 'package:pbl6mobile/view/blog/create_blog_page.dart';
import 'package:pbl6mobile/view/blog/list_blog_page.dart';
import 'package:pbl6mobile/view/blog/update_blog_page.dart';
import 'package:provider/provider.dart';

import '../../model/entities/work_location.dart';
import '../../view/admin_management/create_admin_page.dart';
import '../../view/admin_management/list_admin_page.dart';
import '../../view/admin_management/update_admin_page.dart';
import '../../view/auth/login_page.dart';
import '../../view/blog/manage_categories_page.dart';
import '../../view/doctor_management/create_doctor_page.dart';
import '../../view/doctor_management/doctor_review_page.dart';
import '../../view/doctor_management/list_doctor_page.dart';
import '../../view/doctor_management/update_doctor_page.dart';
import '../../view/location_work_management/create_location_work.dart';
import '../../view/location_work_management/list_location_work.dart';
import '../../view/location_work_management/update_location_work.dart';
import '../../view/main_page/admin/main_page_admin.dart';
import '../../view/question_management/list_question_page.dart';
import '../../view/question_management/question_detail_page.dart';
import '../../view/setting/admin/setting_admin_page.dart';
import '../../view/setting/doctor/setting_doctor_page.dart';
import '../../view/specialty/create_info_section.dart';
import '../../view/specialty/create_specialty.dart';
import '../../view/specialty/list_specialty.dart';
import '../../view/specialty/specialty_detail.dart';
import '../../view/specialty/update_info_section.dart';
import '../../view/specialty/update_specialty.dart';
import '../../view_model/review/review_vm.dart';
import '../widgets/widget/edit_profile_page.dart';

import 'package:pbl6mobile/view/setting/super_admin/permission/permission_groups_page.dart';
import 'package:pbl6mobile/view/setting/super_admin/permission/permission_group_detail_page.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';

class Routes {
  static const login = '/login';
  static const mainPageDoctor = '/mainPageDoctor';
  static const changePassword = '/changePassword';
  static const mainPageSuperAdmin = '/mainPageSuperAdmin';
  static const mainPageAdmin = '/mainPageAdmin';
  static const settingSuperAdmin = '/settingSuperAdmin';
  static const createAdmin = '/createAdmin';
  static const listAdmin = '/listAdmin';
  static const updateAdmin = '/updateAdmin';
  static const updateDoctor = '/updateDoctor';
  static const listDoctor = '/listDoctor';
  static const createDoctor = '/createDoctor';
  static const settingAdmin = '/settingAdmin';
  static const settingDoctor = '/settingDoctor';
  static const listLocationWork = '/listLocationWork';
  static const createLocationWork = '/createLocationWork';
  static const updateLocationWork = '/updateLocationWork';
  static const listSpecialty = '/listSpecialty';
  static const createSpecialty = '/createSpecialty';
  static const updateSpecialty = '/updateSpecialty';
  static const specialtyDetail = '/specialtyDetail';
  static const createInfoSection = '/createInfoSection';
  static const updateInfoSection = '/updateInfoSection';
  static const doctorDetail = '/doctorDetail';
  static const editDoctorProfile = '/editDoctorProfile';
  static const editProfile = '/editProfile';
  static const profileDoctor = '/profileDoctor';
  static const accountDoctor = '/accountDoctor';
  static const editAccountDoctor = '/editAccountDoctor';
  static const listBlog = '/listBlog';
  static const createBlog = '/createBlog';
  static const updateBlog = '/updateBlog';
  static const String manageBlogCategories = '/manage-blog-categories';
  static const String listQuestion = '/listQuestion';
  static const String questionDetail = '/questionDetail';
  static const String doctorReviewPage = '/doctor-review-page';
  static const String listPatient = '/listPatient';
  static const String createPatient = '/createPatient';
  static const String updatePatient = '/updatePatient';
  static const String listAppointment = '/listAppointment';
  static const String permissionGroups = '/permissionGroups';
  static const String permissionGroupDetail = '/permissionGroupDetail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case profileDoctor:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const ProfileDoctorPage(),
        );
      case accountDoctor:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const AccountDoctorPage(),
        );
      case editAccountDoctor:
        final profile = settings.arguments as Profile;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: EditAccountDoctorPage(profile: profile),
        );
      case manageBlogCategories:
        return MaterialPageRoute(builder: (_) => const ManageCategoriesPage());
      case editProfile:
        final profile = settings.arguments as Profile;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: EditProfilePage(profile: profile),
        );
      case login:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const LoginPage(),
        );
      case mainPageDoctor:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const MainPageDoctor(),
        );
      case listSpecialty:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ListSpecialtyPage(),
        );
      case createSpecialty:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreateSpecialtyPage(),
        );
      case updateInfoSection:
        final arg = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdateInfoSectionPage(args: arg!),
        );
      case createInfoSection:
        final specialtyId = settings.arguments as String?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: CreateInfoSectionPage(specialtyId: specialtyId!),
        );
      case updateSpecialty:
        final specialty = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdateSpecialtyPage(
            specialty: specialty!,
          ),
        );
      case specialtyDetail:
        final specialty = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: SpecialtyDetailPage(
            specialty: specialty!,
          ),
        );
      case listLocationWork:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const LocationWorkListPage(),
        );
      case createLocationWork:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreateLocationWorkPage(),
        );
      case updateLocationWork:
        final location = settings.arguments as WorkLocation;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdateLocationWorkPage(
            location: location,
          ),
        );
      case settingDoctor:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const SettingDoctorPage(),
        );
      case settingAdmin:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const SettingAdminPage(),
        );
      case mainPageAdmin:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const MainPageAdmin(),
        );
      case createDoctor:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreateDoctorPage(),
        );
      case listDoctor:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const DoctorListPage(),
        );
      case updateDoctor:
        final doctor = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdateDoctorPage(
            doctor: doctor!,
          ),
        );
      case doctorDetail:
        final doctorId = settings.arguments as String;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: DoctorDetailPage(doctorId: doctorId),
        );
      case editDoctorProfile:
        final args = settings.arguments as Map<String, dynamic>;
        final doctorDetail = args['doctorDetail'] as DoctorDetail;
        final isSelfEdit = args['isSelfEdit'] as bool? ?? false;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: EditDoctorProfilePage(
            doctorDetail: doctorDetail,
            isSelfEdit: isSelfEdit,
          ),
        );
      case createAdmin:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreateAdminPage(),
        );
      case listAdmin:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const AdminListPage(),
        );
      case changePassword:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ChangePasswordPage(),
        );
      case settingSuperAdmin:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const SettingSupperAdminPage(),
        );
      case mainPageSuperAdmin:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const MainPageSuperAdmin(),
        );
      case doctorReviewPage:
        final args = settings.arguments as Map<String, dynamic>;
        final doctorId = args['doctorId'] as String;
        final doctorName = args['doctorName'] as String;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: ChangeNotifierProvider(
            create: (_) => ReviewVm(doctorId: doctorId),
            child: DoctorReviewPage(
              doctorId: doctorId,
              doctorName: doctorName,
            ),
          ),
        );
      case updateAdmin:
        final admin = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdateAdminPage(
            admin: admin!,
          ),
        );
      case listBlog:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ListBlogPage(),
        );
      case createBlog:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreateBlogPage(),
        );
      case updateBlog:
        final blogId = settings.arguments as String;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdateBlogPage(blogId: blogId),
        );
      case listQuestion:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ListQuestionPage(),
        );
      case questionDetail:
        final questionId = settings.arguments as String;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: QuestionDetailPage(questionId: questionId),
        );
      case listPatient:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const PatientListPage(),
        );
      case createPatient:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreatePatientPage(),
        );
      case updatePatient:
        final patient = settings.arguments as Patient;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: UpdatePatientPage(
            patient: patient,
          ),
        );
      case listAppointment:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ListAppointmentPage(),
        );
      case permissionGroups:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const PermissionGroupsPage(),
        );
      case permissionGroupDetail:
        final group = settings.arguments as PermissionGroup;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: PermissionGroupDetailPage(group: group),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('No page route provided')),
          ),
        );
    }
  }
}