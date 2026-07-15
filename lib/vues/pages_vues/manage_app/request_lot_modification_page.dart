import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/handlers/send_modification_request_email.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FieldOption {
  final String key;
  final String label;
  final String oldValue;

  _FieldOption({required this.key, required this.label, required this.oldValue});
}

class _FieldChange {
  final String fieldKey;
  final String fieldLabel;
  final String oldValue;
  String newValue;

  _FieldChange({
    required this.fieldKey,
    required this.fieldLabel,
    required this.oldValue,
    this.newValue = '',
  });
}

class _PendingLotModification {
  final Lot lot;
  final String lotDisplayLabel;
  final List<_FieldChange> changes;

  _PendingLotModification({
    required this.lot,
    required this.lotDisplayLabel,
    required this.changes,
  });
}

enum _WizardStep { pickLot, pickFields, askMore }

/// Formulaire "Demander une modification" (bouton de ModifyPropDetails) :
/// n'écrit AUCUNE donnée Firestore - envoie uniquement un email récapitulatif
/// au contact de la résidence, à charge d'un CS member d'appliquer le
/// changement via manage_list_lot.dart (les champs descriptifs d'un lot ne
/// sont normalement pas modifiables par le propriétaire lui-même).
class RequestLotModificationPage extends ConsumerStatefulWidget {
  final String uid;
  final Lot mainLot;
  final List<Lot> childLots;

  const RequestLotModificationPage({
    super.key,
    required this.uid,
    required this.mainLot,
    required this.childLots,
  });

  @override
  ConsumerState<RequestLotModificationPage> createState() =>
      _RequestLotModificationPageState();
}

class _RequestLotModificationPageState
    extends ConsumerState<RequestLotModificationPage> {
  _WizardStep _step = _WizardStep.pickLot;

  final List<_PendingLotModification> _completed = [];
  final List<String> _treatedLotIds = [];

  Lot? _currentLot;
  List<_FieldOption> _currentFieldOptions = [];
  final Set<String> _selectedFieldKeys = {};
  final Map<String, TextEditingController> _newValueControllers = {};

  bool _isSubmitting = false;

  List<Lot> get _allLots => [widget.mainLot, ...widget.childLots];

  List<Lot> get _remainingLots =>
      _allLots.where((l) => !_treatedLotIds.contains(l.id)).toList();

  String _lotDisplayLabel(Lot lot) {
    if (lot.id == widget.mainLot.id) {
      return "Lot principal (${lot.residenceData['name'] ?? ''} ${lot.lot ?? ''})";
    }
    return "Lot rattaché (${lot.typeLot} ${lot.lot ?? ''})";
  }

  List<_FieldOption> _buildFieldOptions(Lot lot) {
    final isMain = lot.id == widget.mainLot.id;
    return [
      _FieldOption(key: 'typeLot', label: 'Type', oldValue: lot.typeLot),
      _FieldOption(key: 'refLot', label: 'Référence Lot', oldValue: lot.refLot),
      _FieldOption(key: 'batiment', label: 'Bâtiment', oldValue: lot.batiment ?? ''),
      _FieldOption(key: 'lot', label: 'Lot', oldValue: lot.lot ?? ''),
      if (isMain) ...[
        _FieldOption(
            key: 'street',
            label: 'Adresse',
            oldValue: lot.residenceAddress['street']?.toString() ?? ''),
        _FieldOption(
            key: 'zipCode',
            label: 'Code Postal',
            oldValue: lot.residenceAddress['zipCode']?.toString() ?? ''),
        _FieldOption(
            key: 'city',
            label: 'Ville',
            oldValue: lot.residenceAddress['city']?.toString() ?? ''),
      ],
    ];
  }

  void _pickLot(Lot lot) {
    for (final controller in _newValueControllers.values) {
      controller.dispose();
    }
    _newValueControllers.clear();
    _selectedFieldKeys.clear();

    final options = _buildFieldOptions(lot);
    for (final option in options) {
      _newValueControllers[option.key] = TextEditingController();
    }

    setState(() {
      _currentLot = lot;
      _currentFieldOptions = options;
      _step = _WizardStep.pickFields;
    });
  }

  bool get _canValidateFields =>
      _selectedFieldKeys.isNotEmpty &&
      _selectedFieldKeys
          .every((key) => _newValueControllers[key]!.text.trim().isNotEmpty);

  void _validateFields() {
    final lot = _currentLot!;
    final changes = _currentFieldOptions
        .where((option) => _selectedFieldKeys.contains(option.key))
        .map((option) => _FieldChange(
              fieldKey: option.key,
              fieldLabel: option.label,
              oldValue: option.oldValue,
              newValue: _newValueControllers[option.key]!.text.trim(),
            ))
        .toList();

    setState(() {
      _completed.add(_PendingLotModification(
        lot: lot,
        lotDisplayLabel: _lotDisplayLabel(lot),
        changes: changes,
      ));
      _treatedLotIds.add(lot.id!);
      _currentLot = null;
      _step = _WizardStep.askMore;
    });
  }

  List<Map<String, String>> _buildChangesPayload() {
    final multipleLots = _completed.length > 1;
    final rows = <Map<String, String>>[];
    for (final pending in _completed) {
      for (final change in pending.changes) {
        final key = multipleLots
            ? '${pending.lotDisplayLabel} - ${change.fieldLabel}'
            : change.fieldLabel;
        rows.add({
          'cle': key,
          'ancienne_valeur': change.oldValue,
          'nouvelle_valeur': change.newValue,
        });
      }
    }
    return rows;
  }

  String _buildLotsSummary() {
    if (_completed.length == 1) {
      return "1 lot concerné : ${_completed.first.lotDisplayLabel}";
    }
    return "${_completed.length} lots concernés : "
        "${_completed.map((p) => p.lotDisplayLabel).join(', ')}";
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await sendModificationRequestEmail(
        requesterUid: widget.uid,
        residenceMailContact:
            widget.mainLot.residenceData['mail_contact']?.toString(),
        residenceName: widget.mainLot.residenceData['name']?.toString() ?? '',
        lotsSummary: _buildLotsSummary(),
        changes: _buildChangesPayload(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Votre demande de modification a été envoyée."),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Erreur lors de l'envoi de la demande : $e"),
      ));
    }
  }

  @override
  void dispose() {
    for (final controller in _newValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Demander une modification", Colors.black87, SizeFont.h1.size),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: switch (_step) {
          _WizardStep.pickLot => _buildPickLotStep(),
          _WizardStep.pickFields => _buildPickFieldsStep(),
          _WizardStep.askMore => _buildAskMoreStep(),
        },
      ),
    );
  }

  Widget _buildPickLotStep() {
    final remaining = _remainingLots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextStyle.lotName(
            "Sur quel lot porte la modification ?", Colors.black54),
        const SizedBox(height: 20),
        for (final lot in remaining)
          Card(
            child: ListTile(
              title: Text(_lotDisplayLabel(lot)),
              onTap: () => _pickLot(lot),
            ),
          ),
      ],
    );
  }

  Widget _buildPickFieldsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextStyle.lotName(
            "Quels champs souhaitez-vous faire modifier ?", Colors.black54),
        const SizedBox(height: 10),
        for (final option in _currentFieldOptions) ...[
          CheckboxListTile(
            value: _selectedFieldKeys.contains(option.key),
            title: Text(option.label),
            subtitle: Text("Valeur actuelle : ${option.oldValue}"),
            onChanged: (checked) => setState(() {
              if (checked ?? false) {
                _selectedFieldKeys.add(option.key);
              } else {
                _selectedFieldKeys.remove(option.key);
              }
            }),
          ),
          if (_selectedFieldKeys.contains(option.key))
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: CustomTextFieldWidget(
                label: 'Nouvelle valeur',
                controller: _newValueControllers[option.key],
                isEditable: true,
                maxLines: 1,
                minLines: 1,
                onChanged: (_) => setState(() {}),
              ),
            ),
        ],
        const SizedBox(height: 20),
        ButtonAdd(
          function: _canValidateFields ? _validateFields : null,
          text: "Suivant",
          color: _canValidateFields
              ? Theme.of(context).primaryColor
              : Colors.black26,
          colorText: Colors.white,
          horizontal: 30,
          vertical: 10,
          size: SizeFont.h3.size,
        ),
      ],
    );
  }

  Widget _buildAskMoreStep() {
    final hasRemainingLots = _remainingLots.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextStyle.lotName("Récapitulatif de votre demande", Colors.black54),
        const SizedBox(height: 10),
        for (final pending in _completed)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pending.lotDisplayLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  for (final change in pending.changes)
                    Text(
                        "${change.fieldLabel} : ${change.oldValue} → ${change.newValue}"),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (hasRemainingLots)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ButtonAdd(
              function: () => setState(() => _step = _WizardStep.pickLot),
              text: "Ajouter une modification sur un autre lot",
              color: Colors.black26,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size,
            ),
          ),
        ButtonAdd(
          function: _isSubmitting ? null : _submit,
          text: _isSubmitting ? "Envoi en cours..." : "Terminé, envoyer la demande",
          color: Theme.of(context).primaryColor,
          colorText: Colors.white,
          horizontal: 30,
          vertical: 10,
          size: SizeFont.h3.size,
        ),
      ],
    );
  }
}
