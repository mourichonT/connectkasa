import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class CustomTextFieldWidget extends StatelessWidget {
  final String label;
  final String? value;
  final String? text;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? field;
  final Function(String field, String label, String value)? onSubmit;
  final VoidCallback? refresh;
  final VoidCallback? pickDate; // Ajout dans la classe
  final bool isEditable;
  final int maxLines;
  final int minLines;
  final Function(String value)? onChanged;
  final TextInputType? keyboardType;

  const CustomTextFieldWidget({
    Key? key,
    this.text,
    required this.label,
    this.value,
    this.controller,
    this.focusNode,
    this.field,
    this.onSubmit,
    this.refresh,
    this.isEditable = false,
    this.maxLines = 5,
    this.minLines = 1,
    this.pickDate,
    this.onChanged,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: isEditable
            ? _buildModifyTextField(context)
            : _buildReadOnlyTextField(),
      ),
    );
  }

  Widget _buildModifyTextField(BuildContext context) {
    final isReadOnlyTapField = pickDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextStyle.lotName(label, Colors.black54),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: keyboardType ?? TextInputType.text,
                controller: controller,
                focusNode: focusNode,
                readOnly: isReadOnlyTapField,
                onTap: pickDate,
                textAlign:
                    isReadOnlyTapField ? TextAlign.center : TextAlign.start,
                maxLines: isReadOnlyTapField ? 1 : maxLines,
                minLines: isReadOnlyTapField ? 1 : minLines,
                decoration: InputDecoration(
                  hintText: text,
                  border: InputBorder.none, // ✅ plus de contour
                  enabledBorder:
                      InputBorder.none, // ✅ supprime contour en mode actif
                  focusedBorder:
                      InputBorder.none, // ✅ supprime contour en mode focus
                  prefixIcon: isReadOnlyTapField
                      ? const Icon(Icons.calendar_today, size: 14)
                      : null,
                  suffixIcon: isReadOnlyTapField
                      ? const Icon(Icons.arrow_drop_down, size: 23)
                      : null,
                  // ❌ PAS DE label NI hint pour les champs date
                ),
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: SizeFont.h3.size,
                  fontWeight: FontWeight.w400,
                ),
                onChanged: isReadOnlyTapField
                    ? null
                    : (val) {
                        onChanged?.call(val);
                        refresh?.call();
                      },
              ),
            ),
            if (!isReadOnlyTapField && (focusNode?.hasFocus ?? false))
              IconButton(
                onPressed: () {
                  if (field != null && onSubmit != null && controller != null) {
                    onSubmit!(field!, label, controller!.text);
                  }
                  focusNode?.unfocus();
                  refresh?.call();
                },
                icon: const Icon(Icons.check),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextStyle.lotName(label, Colors.black54),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            value ?? '',
            style: TextStyle(
                color: Colors.black54,
                fontSize: SizeFont.h3.size,
                fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
