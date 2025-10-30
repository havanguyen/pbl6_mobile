import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/review.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/review/review_vm.dart';

class DoctorReviewPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorReviewPage(
      {super.key, required this.doctorId, required this.doctorName});

  @override
  State<DoctorReviewPage> createState() => _DoctorReviewPageState();
}

class _DoctorReviewPageState extends State<DoctorReviewPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final reviewVm = Provider.of<ReviewVm>(context, listen: false);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        reviewVm.loadMoreReviews();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewVm = context.watch<ReviewVm>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.primary,
        iconTheme: IconThemeData(color: context.theme.primaryForeground),
        title: Text(
          'Đánh giá cho ${widget.doctorName}',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: Builder(
        builder: (context) {
          if (reviewVm.isLoading && reviewVm.reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (reviewVm.error != null && reviewVm.reviews.isEmpty) {
            return Center(child: Text(reviewVm.error!));
          }
          if (reviewVm.reviews.isEmpty) {
            return const Center(child: Text('Bác sĩ này chưa có đánh giá.'));
          }

          return RefreshIndicator(
            onRefresh: () => reviewVm.fetchReviews(forceRefresh: true),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount:
              reviewVm.reviews.length + (reviewVm.hasNext ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == reviewVm.reviews.length) {
                  return reviewVm.isLoadingMore
                      ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ))
                      : const SizedBox.shrink();
                }
                final review = reviewVm.reviews[index];
                return _buildReviewCard(context, review, reviewVm);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(
      BuildContext context, Review review, ReviewVm reviewVm) {
    return Card(
      key: ValueKey(review.id),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.theme.border),
      ),
      color: context.theme.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StarRating(
                          rating: review.rating, color: context.theme.yellow),
                      const SizedBox(height: 8),
                      Text(
                        review.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: context.theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _DeleteReviewButton(
                  review: review,
                  onDelete: () async {
                    return await reviewVm.deleteReview(review.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.body,
              style: TextStyle(
                  color: context.theme.mutedForeground, fontSize: 14),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.authorName,
                    style: TextStyle(
                        color: context.theme.mutedForeground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal()),
                  style: TextStyle(
                      color: context.theme.mutedForeground, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteReviewButton extends StatefulWidget {
  final Review review;
  final Future<bool> Function() onDelete;

  const _DeleteReviewButton({required this.review, required this.onDelete});

  @override
  State<_DeleteReviewButton> createState() => _DeleteReviewButtonState();
}

class _DeleteReviewButtonState extends State<_DeleteReviewButton> {
  bool _isDeleting = false;

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Xác nhận xóa',
            style: TextStyle(color: context.theme.popoverForeground)),
        content: Text('Bạn có chắc chắn muốn xóa đánh giá này?',
            style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: TextStyle(color: context.theme.mutedForeground)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _handleDelete();
            },
            child:
            Text('Xóa', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  void _handleDelete() async {
    setState(() => _isDeleting = true);
    final success = await widget.onDelete();

    if (!mounted) return;

    if (!success) {
      setState(() => _isDeleting = false);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Xóa đánh giá thành công' : 'Xóa thất bại'),
        backgroundColor:
        success ? context.theme.green : context.theme.destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isDeleting
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.theme.destructive,
      ),
    )
        : IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      icon: Icon(Icons.delete_outline,
          color: context.theme.destructive, size: 22),
      onPressed: _showDeleteConfirmDialog,
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final Color color;
  final double size;

  const _StarRating({
    required this.rating,
    this.color = Colors.amber,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: color,
          size: size,
        );
      }),
    );
  }
}