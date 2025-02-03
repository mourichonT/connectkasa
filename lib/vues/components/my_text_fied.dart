import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool osbcureText;
  final TextEditingController controller;
  final double padding;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.osbcureText,
    required this.controller,
    required this.padding,
  });

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Demander l'ouverture du clavier immédiatement après l'initialisation
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
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
        focusNode: _focusNode, // Le FocusNode est attaché ici
        obscureText: widget.osbcureText, // Gère le masquage du texte
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
        ),
        controller: widget.controller,
      ),
    );
  }
}
