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
        Text(label,
            style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
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
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
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
        Text(label,
            style: TextStyle(
                color: Colors.black45,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            value ?? '',
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
