import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/themes/cubit/language_cubit.dart';
import 'package:pbl6mobile/shared/themes/cubit/language_state.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool isCompact;

  const LanguageSwitcher({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        final isVi = state.locale.languageCode == 'vi';

        if (isCompact) {
          return InkWell(
            onTap: () {
              final newLocale = isVi ? const Locale('en') : const Locale('vi');
              context.read<LanguageCubit>().changeLanguage(newLocale);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.theme.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.theme.blue.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 18, color: context.theme.blue),
                  const SizedBox(width: 8),
                  Text(
                    isVi ? 'VN' : 'EN',
                    style: TextStyle(
                      color: context.theme.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: context.theme.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOption(context, 'Tiếng Việt', 'vi', isVi),
              _buildOption(context, 'English', 'en', !isVi),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    String code,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<LanguageCubit>().changeLanguage(Locale(code));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.theme.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.theme.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
