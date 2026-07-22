import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFieldWidget extends StatelessWidget {
  final String? label;
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
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFieldWidget({
    super.key,
    this.text,
    this.label,
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
    this.suffixText,
    this.inputFormatters,
  });

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
        if (label != null && label!.isNotEmpty)
          MyTextStyle.lotName(label!, Colors.black54),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: keyboardType ?? TextInputType.text,
                controller: controller,
                focusNode: focusNode,
                inputFormatters: inputFormatters,
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
                  // suffixIcon (plutôt que suffixText) : reste ancré au bord
                  // droit du champ quel que soit le nombre de caractères
                  // saisis, contrairement à suffixText qui suit le texte.
                  suffixIcon: suffixText != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            widthFactor: 1,
                            child: Text(
                              suffixText!,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: SizeFont.h3.size,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        )
                      : (isReadOnlyTapField
                          ? const Icon(Icons.arrow_drop_down, size: 23)
                          : null),
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
                  if (field != null &&
                      onSubmit != null &&
                      controller != null) {
                    onSubmit!(field!, label!, controller!.text);
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
        if (label != null && label!.isNotEmpty)
          MyTextStyle.lotName(label!, Colors.black45),
        Padding(
          padding: const EdgeInsets.only(left: 0.0, top: 10, bottom: 10),
          child: Text(
            value ?? '',
            style: TextStyle(
                color: Colors.black45,
                fontSize: SizeFont.h3.size,
                fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
