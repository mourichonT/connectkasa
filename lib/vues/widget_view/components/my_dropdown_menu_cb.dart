import 'package:flutter/material.dart';

class MyMultiSelectDropdownInline extends StatefulWidget {
  final double width;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onSelectionChanged;
  final String hintText;

  const MyMultiSelectDropdownInline({
    Key? key,
    required this.width,
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    this.hintText = 'Sélectionner...',
  }) : super(key: key);

  @override
  State<MyMultiSelectDropdownInline> createState() =>
      _PersistentMultiSelectDropdownState();
}

class _PersistentMultiSelectDropdownState
    extends State<MyMultiSelectDropdownInline> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.selectedItems];
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: widget.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 5),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                children: widget.items.map((item) {
                  final isChecked = _selected.contains(item);
                  return CheckboxListTile(
                    value: isChecked,
                    title: Text(item),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          if (!_selected.contains(item)) {
                            _selected.add(item);
                          }
                        } else {
                          _selected.remove(item);
                        }
                        widget.onSelectionChanged(_selected);

                        // 👇 Recréer l'overlay pour refléter les changements visuels
                        _overlayEntry?.remove();
                        _overlayEntry = _createOverlayEntry();
                        Overlay.of(context).insert(_overlayEntry!);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
        _selected.isEmpty ? widget.hintText : _selected.join(', ');

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
