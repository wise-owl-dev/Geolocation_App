import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final int? maxLines;

  const CustomTextFormField({
    super.key, 
    this.label, 
    this.hint, 
    this.errorMessage, 
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged, 
    this.validator,
    this.enabled = true,
    this.controller,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF191970)), // Azul Marino
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF191970), width: 2), // Azul Marino
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFC71585), width: 1.5), // Rojo/Magenta
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFC71585), width: 2.0), // Rojo/Magenta
              borderRadius: BorderRadius.circular(8),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFC71585), // Rojo/Magenta
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            fillColor: enabled ? null : Colors.grey.shade100,
            filled: !enabled,
            suffixIcon: suffixIcon,
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Color(0xFFC71585)), // Rojo/Magenta
                const SizedBox(width: 4),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFC71585), // Rojo/Magenta
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}