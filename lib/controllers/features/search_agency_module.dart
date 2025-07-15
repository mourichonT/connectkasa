import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/vues/widget_view/components/agency_search_result_list.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';

Widget buildAgencySearchSection({
  required bool visible,
  required bool isSearching,
  required List<Agency> searchResults,
  required TextEditingController controller,
  required void Function(Agency agency) onSelect,
  required void Function(String val) onChanged,
}) {
  return Visibility(
    visible: visible,
    child: Column(
      children: [
        CustomTextFieldWidget(
          label: "Mail de l'agence",
          controller: controller,
          isEditable: true,
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        AgencySearchResultList(
          isSearching: isSearching,
          searchResults: searchResults,
          onSelect: onSelect,
        ),
      ],
    ),
  );
}
