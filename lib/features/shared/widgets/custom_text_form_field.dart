import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    super.key, 
    this.label, 
    this.hint, 
    this.errorMessage, 
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged, 
    this.validator, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            // Personalización del estilo cuando hay error
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
              borderRadius: BorderRadius.circular(8),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                const SizedBox(width: 4),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
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
