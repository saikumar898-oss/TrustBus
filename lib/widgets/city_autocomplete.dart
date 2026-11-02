import 'package:flutter/material.dart';
import '../data/cities.dart';

class CityAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CityAutocomplete({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }

        return cities.where((city) =>
            city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (value) {
        controller.text = value;
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        textController.text = controller.text;

        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.white.withOpacity(.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}
