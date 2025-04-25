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
  final bool isEditable;
  final int maxLines;
  final int minLines;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextStyle.lotName(label, Colors.black54),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: maxLines,
                minLines: minLines,
                decoration:
                    InputDecoration(hintText: text, border: InputBorder.none),
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: SizeFont.h3.size,
                    fontWeight: FontWeight.w400),
                onChanged: (value) => refresh?.call(),
              ),
            ),
            if (focusNode?.hasFocus ?? false)
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
