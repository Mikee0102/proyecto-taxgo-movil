import 'package:flutter/material.dart';

class TermsDialog extends StatefulWidget {
  const TermsDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const TermsDialog(),
    );
    return accepted ?? false;
  }

  @override
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.gavel_outlined, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Términos y Condiciones',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Antes de continuar con Tlax.Go, revisa y acepta las reglas de uso.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 14),
              const Text(
                '1. Uso responsable\nUtiliza la aplicación de manera lícita y respeta a otros usuarios.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                '2. Privacidad\nTus datos se utilizan para gestionar tu cuenta y personalizar tu experiencia.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                '3. Contenido y seguridad\nNo publiques información falsa, ofensiva o que pueda poner en riesgo a terceros.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 10),
              const Text(
                '4. Disponibilidad\nLas rutas e información pueden cambiar sin previo aviso.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
                value: _accepted,
                title: const Text(
                  'He leído y acepto los Términos y Condiciones.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onChanged: (value) {
                  setState(() => _accepted = value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _accepted ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Aceptar y continuar'),
        ),
      ],
    );
  }
}
