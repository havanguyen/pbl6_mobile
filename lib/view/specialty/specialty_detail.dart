import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/model/entities/info_section.dart';
import 'package:pbl6mobile/shared/widgets/widget/info_section_delete_confirm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
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

  void _showDeleteDialog(InfoSection infoSection) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteInfoSectionConfirmationDialog(
        infoSection: infoSection,
        specialtyId: widget.specialty['id'],
        onDeleteSuccess: () {},
        snackbarService: snackbarService,
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
      body: Consumer<SpecialtyVm>(
        builder: (context, provider, child) {
          if (provider.isInfoSectionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final infoSections =
          provider.getInfoSectionsFor(widget.specialty['id']);
          if (infoSections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: context.theme.mutedForeground,
                  ),
                  const SizedBox(height: 20),
                  const Text('Chưa có phần thông tin nào.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: infoSections.length,
            itemBuilder: (context, index) {
              final info = infoSections[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    info.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
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
                            provider.fetchInfoSections(widget.specialty['id'],
                                forceRefresh: true);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: context.theme.destructive),
                        onPressed: () => _showDeleteDialog(info),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Html(data: info.content),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            Routes.createInfoSection,
            arguments: widget.specialty['id'],
          );
          if (result == true && mounted) {
            context
                .read<SpecialtyVm>()
                .fetchInfoSections(widget.specialty['id'], forceRefresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}