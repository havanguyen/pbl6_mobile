import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class SpecialtyDetailPage extends StatefulWidget {
  final Map<String, dynamic> specialty;

  const SpecialtyDetailPage({super.key, required this.specialty});

  @override
  State<SpecialtyDetailPage> createState() => _SpecialtyDetailPageState();
}

class _SpecialtyDetailPageState extends State<SpecialtyDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpecialtyVm>(context, listen: false).fetchInfoSections(widget.specialty['id']);
    });
  }

  void _showDeleteDialog(dynamic infoSection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Xác nhận xóa', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(
          'Bạn có chắc chắn muốn xóa phần thông tin: ${infoSection['name']}?',
          style: TextStyle(color: context.theme.popoverForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
          ),
          TextButton(
            onPressed: () => _confirmDelete(infoSection['id']),
            child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    Navigator.pop(context);
    final provider = Provider.of<SpecialtyVm>(context, listen: false);
    final success = await provider.deleteInfoSection(id, widget.specialty['id']);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa phần thông tin thành công!', style: TextStyle(color: context.theme.primaryForeground)),
          backgroundColor: context.theme.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa thất bại. Thử lại.', style: TextStyle(color: context.theme.destructiveForeground)),
          backgroundColor: context.theme.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          widget.specialty['name'],
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
            onPressed: () => Provider.of<SpecialtyVm>(context, listen: false).fetchInfoSections(widget.specialty['id']),
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButtonBlue(
              onTap: () => Navigator.pushNamed(
                context,
                Routes.createInfoSection,
                arguments: widget.specialty['id'],
              ),
              text: 'Thêm phần thông tin',
            ),
          ),
          Expanded(
            child: Consumer<SpecialtyVm>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: context.theme.primary));
                }
                final infoSections = provider.getInfoSectionsFor(widget.specialty['id']);
                if (infoSections.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: context.theme.muted),
                        const SizedBox(height: 16),
                        Text(
                          'Danh sách phần thông tin trống',
                          style: TextStyle(fontSize: 18, color: context.theme.mutedForeground),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: infoSections.length,
                  itemBuilder: (context, index) {
                    final info = infoSections[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: context.theme.card,
                      child: ExpansionTile(
                        title: Text(info['name'] ?? 'N/A', style: TextStyle(color: context.theme.cardForeground)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Html(data: info['content'] ?? ''),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: context.theme.primary),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  Routes.updateInfoSection,
                                  arguments: {'infoSection': info, 'specialtyId': widget.specialty['id']},
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: context.theme.destructive),
                                onPressed: () => _showDeleteDialog(info),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}