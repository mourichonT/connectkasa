import 'dart:async';
import 'package:konodal/controllers/features/address_search.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/pages_models/ban_address_suggestion.dart';
import 'package:flutter/material.dart';

/// Champ "Adresse" (numéro + voie, ex: "14 Rue de la Paix") avec
/// autocomplétion via l'API Adresse (data.gouv.fr/IGN, gratuite, sans clé).
/// La sélection d'une suggestion remplit le champ avec la ligne complète et
/// renvoie code postal/ville via [onSelected] pour préremplir ces champs
/// tout en les laissant modifiables. [onManualEdit] est appelé dès que
/// l'utilisateur tape sans (encore) sélectionner de suggestion, pour que
/// l'appelant puisse marquer l'adresse comme non validée (codeQualite "60")
/// tant qu'une suggestion n'a pas été choisie (codeQualite "00").
class AddressSearchField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final void Function(BanAddressSuggestion suggestion) onSelected;
  final VoidCallback? onManualEdit;

  const AddressSearchField({
    super.key,
    this.label = "Adresse",
    required this.controller,
    required this.onSelected,
    this.onManualEdit,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  Timer? _debounce;
  List<BanAddressSuggestion> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    widget.onManualEdit?.call();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      final results = await AddressSearch.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  void _selectSuggestion(BanAddressSuggestion suggestion) {
    widget.controller.text =
        "${suggestion.housenumber} ${suggestion.street}".trim();
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
    widget.onSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.label.isNotEmpty)
                  MyTextStyle.lotName(widget.label, Colors.black54),
                TextField(
                  controller: widget.controller,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFF5F6F9), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((suggestion) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(suggestion.label),
                  onTap: () => _selectSuggestion(suggestion),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
