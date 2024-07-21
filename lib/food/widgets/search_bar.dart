import 'package:flutter/material.dart';

class GenericSearchBar extends StatelessWidget {
  final Function(String) onSearchChanged;

  const GenericSearchBar({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true, // Add this line to autofocus the field
      onChanged: onSearchChanged,
      decoration: const InputDecoration(
        labelText: 'Zoeken',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
