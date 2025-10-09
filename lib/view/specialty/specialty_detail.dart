import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';

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
      context
          .read<SpecialtyVm>()
          .fetchInfoSections(widget.specialty['id'], forceRefresh: true);
    });
  }

  void _showDeleteDialog(String infoSectionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phần thông tin này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<SpecialtyVm>()
                  .deleteInfoSection(infoSectionId, widget.specialty['id']);
            },
            child: Text('Xóa',
                style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.specialty['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<SpecialtyVm>()
                .fetchInfoSections(widget.specialty['id'], forceRefresh: true),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                    context, Routes.createInfoSection,
                    arguments: widget.specialty['id']);
                if (result == true) {
                  context.read<SpecialtyVm>().fetchInfoSections(
                      widget.specialty['id'],
                      forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Thêm phần thông tin'),
            ),
          ),
          Expanded(
            child: Consumer<SpecialtyVm>(
              builder: (context, provider, child) {
                if (provider.isInfoSectionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final infoSections =
                provider.getInfoSectionsFor(widget.specialty['id']);
                if (infoSections.isEmpty) {
                  return const Center(
                      child: Text('Không có phần thông tin nào.'));
                }
                return ListView.builder(
                  itemCount: infoSections.length,
                  itemBuilder: (context, index) {
                    final info = infoSections[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ExpansionTile(
                        title: Text(info.name),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Html(data: info.content),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: context.theme.primary),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    Routes.updateInfoSection,
                                    arguments: {
                                      'infoSection': info.toJson(),
                                      'specialtyId': widget.specialty['id']
                                    },
                                  );
                                  if (result == true) {
                                    provider.fetchInfoSections(
                                        widget.specialty['id'],
                                        forceRefresh: true);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: context.theme.destructive),
                                onPressed: () => _showDeleteDialog(info.id),
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