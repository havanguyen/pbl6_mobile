import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

import '../../../model/services/remote/address_service.dart';

class LocationForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final Future<bool> Function({
  required String name,
  required String address,
  required String phone,
  required String timezone,
  String? id,
  }) onSubmit;

  const LocationForm({
    super.key,
    required this.isUpdate,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _detailAddressController;

  String? _selectedTimezone;
  String? _selectedProvinceId;
  String? _selectedDistrictId;
  String? _selectedWardId;

  bool _isLoading = false;
  bool _dataLoaded = false;

  late List<String> _timezones;

  Map<String, String> _provinces = {};
  Map<String, String> _districts = {};
  Map<String, String> _wards = {};

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialData?['name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.initialData?['phone'] ?? '');
    _detailAddressController = TextEditingController();

    _selectedTimezone = widget.initialData?['timezone'] ?? 'Asia/Ho_Chi_Minh';

    tzData.initializeTimeZones();
    _timezones = tz.timeZoneDatabase.locations.keys.toList();

    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchProvinces();
    if (widget.isUpdate && widget.initialData?['address'] != null) {
      await _parseAndSetAddress(widget.initialData!['address']);
    }
  }

  Future<void> _parseAndSetAddress(String address) async {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 4) {
      final detail = parts[0];
      final wardName = parts[1];
      final districtName = parts[2];
      final provinceName = parts[3];

      String? provinceId;
      for (var entry in _provinces.entries) {
        if (entry.value == provinceName) {
          provinceId = entry.key;
          break;
        }
      }

      if (provinceId != null) {
        setState(() {
          _selectedProvinceId = provinceId;
        });
        await _fetchDistricts(provinceId);

        String? districtId;
        for (var entry in _districts.entries) {
          if (entry.value == districtName) {
            districtId = entry.key;
            break;
          }
        }

        if (districtId != null) {
          setState(() {
            _selectedDistrictId = districtId;
          });
          await _fetchWards(districtId);

          String? wardId;
          for (var entry in _wards.entries) {
            if (entry.value == wardName) {
              wardId = entry.key;
              break;
            }
          }

          if (wardId != null) {
            setState(() {
              _selectedWardId = wardId;
            });
          }
        }
      }

      setState(() {
        _detailAddressController.text = detail;
      });
    }
  }

  Future<void> _fetchProvinces() async {
    try {
      final result = await AddressService.getProvinces();
      if (result['success']) {
        setState(() {
          _provinces = {
            for (var item in result['data']) item['id'].toString(): item['full_name']
          };
          _dataLoaded = true;
        });
      } else {
        _showErrorDialog(result['message'] ?? 'Lỗi khi tải danh sách tỉnh/thành phố');
      }
    } catch (e) {
      _showErrorDialog('Lỗi: $e');
    }
  }

  Future<void> _fetchDistricts(String provinceId) async {
    try {
      final result = await AddressService.getDistricts(provinceId);
      if (result['success']) {
        setState(() {
          _districts = {
            for (var item in result['data']) item['id'].toString(): item['full_name']
          };
        });
      } else {
        _showErrorDialog(result['message'] ?? 'Lỗi khi tải danh sách quận/huyện');
      }
    } catch (e) {
      _showErrorDialog('Lỗi: $e');
    }
  }

  Future<void> _fetchWards(String districtId) async {
    try {
      final result = await AddressService.getWards(districtId);
      if (result['success']) {
        setState(() {
          _wards = {
            for (var item in result['data']) item['id'].toString(): item['full_name']
          };
        });
      } else {
        _showErrorDialog(result['message'] ?? 'Lỗi khi tải danh sách phường/xã');
      }
    } catch (e) {
      _showErrorDialog('Lỗi: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final address =
          '${_detailAddressController.text}, ${_wards[_selectedWardId] ?? ''}, ${_districts[_selectedDistrictId] ?? ''}, ${_provinces[_selectedProvinceId] ?? ''}';

      setState(() => _isLoading = true);
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        address: address,
        phone: _phoneController.text,
        timezone: _selectedTimezone!,
      );
      setState(() => _isLoading = false);

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(
            '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Thành công',
            style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(
            '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm thành công!',
            style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK', style: TextStyle(color: context.theme.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Lỗi', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(message,
            style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Tên địa điểm',
                prefixIcon: Icon(Icons.location_on, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên địa điểm';
                }
                if (value.length < 10 || value.length > 200) {
                  return 'Tên phải từ 10 đến 200 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Province
            DropdownButtonFormField2<String>(
              value: _selectedProvinceId,
              isExpanded: true,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Tỉnh/Thành phố',
                prefixIcon: Icon(Icons.map, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              items: _provinces.entries
                  .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedProvinceId = value;
                  _selectedDistrictId = null;
                  _selectedWardId = null;
                  _districts.clear();
                  _wards.clear();
                });
                if (value != null) {
                  await _fetchDistricts(value);
                }
              },
              validator: (value) =>
              value == null ? 'Vui lòng chọn tỉnh/thành phố' : null,
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 300, // 👈 Giới hạn chiều cao dropdown
              ),
            ),
            const SizedBox(height: 16),

            // District
            DropdownButtonFormField2<String>(
              value: _selectedDistrictId,
              isExpanded: true,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Quận/Huyện',
                prefixIcon: Icon(Icons.map, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              items: _districts.entries
                  .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedDistrictId = value;
                  _selectedWardId = null;
                  _wards.clear();
                });
                if (value != null) {
                  await _fetchWards(value);
                }
              },
              validator: (value) =>
              value == null ? 'Vui lòng chọn quận/huyện' : null,
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 300,
              ),
            ),
            const SizedBox(height: 16),

            // Ward
            DropdownButtonFormField2<String>(
              value: _selectedWardId,
              isExpanded: true,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Phường/Xã',
                prefixIcon: Icon(Icons.map, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              items: _wards.entries
                  .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWardId = value;
                });
              },
              validator: (value) =>
              value == null ? 'Vui lòng chọn phường/xã' : null,
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 300,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _detailAddressController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Địa chỉ chi tiết',
                prefixIcon: Icon(Icons.map, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập địa chỉ chi tiết';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (!RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Timezone
            DropdownButtonFormField2<String>(
              value: _selectedTimezone,
              isExpanded: true,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Múi giờ',
                prefixIcon: Icon(Icons.access_time, color: context.theme.primary),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              items: _timezones
                  .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimezone = value;
                });
              },
              validator: (value) =>
              value == null ? 'Vui lòng chọn múi giờ' : null,
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 300,
              ),
            ),
            const SizedBox(height: 32),

            CustomButtonBlue(
              onTap: _submitForm,
              text: _isLoading
                  ? 'Đang ${widget.isUpdate ? 'cập nhật' : 'tạo'}...'
                  : '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm',
            ),
          ],
        ),
      ),
    );
  }
}
