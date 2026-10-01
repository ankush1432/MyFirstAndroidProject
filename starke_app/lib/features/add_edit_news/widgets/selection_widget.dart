import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';

class SelectionField extends StatelessWidget {
  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final bool visible, isDate;

  /// Gap above the field — see [AppTextField.topMargin].
  final double topMargin;

  const SelectionField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.visible = true,
    this.isDate = false,
    this.topMargin = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: topMargin),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? placeholder : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: value.isEmpty
                            ? colorScheme.primaryContainer.withOpacity(.7)
                            : colorScheme.primaryContainer,
                      ),
                ),
              ),
              SvgPictureWidget(
                  assetName: (isDate) ? 'calendar' : 'dropdownIcon',
                  height: 18,
                  width: 18,
                  assetColor: ColorFilter.mode(
                      colorScheme.primaryContainer, BlendMode.srcIn)),
            ],
          ),
        ),
      ),
    );
  }
}
