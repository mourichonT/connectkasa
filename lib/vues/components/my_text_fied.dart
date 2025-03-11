import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool osbcureText;
  final TextEditingController controller;
  final double padding;
  final bool autofocus;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.osbcureText,
    required this.controller,
    required this.padding,
    required this.autofocus,
  });

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late FocusNode _focusNode;
  late bool _isObscure; // ✅ Ajout d'un état pour gérer la visibilité

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _isObscure = widget.osbcureText; // ✅ Initialisation de l'état

    if (widget.autofocus) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding),
      child: TextField(
        focusNode: _focusNode,
        obscureText: _isObscure, // ✅ Utilisation de _isObscure
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.black45),
          suffixIcon: widget.osbcureText // ✅ Affiche l'icône seulement si c'est un champ mot de passe
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility, // ✅ Change d'icône
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure; // ✅ Inverse la valeur
                    });
                  },
                )
              : null,
        ),
        controller: widget.controller,
      ),
    );
  }
}
