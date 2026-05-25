import "package:flutter/material.dart";

import "package:smart_expense/features/transactions/data/voice_transaction_demo_api_client.dart";

class AiVoiceConfig {
  const AiVoiceConfig({required this.endpoint, required this.demoToken});

  final String endpoint;
  final String? demoToken;
}

Future<AiVoiceConfig?> showAiVoiceConfigDialog(
  BuildContext context, {
  String? initialEndpoint,
  String? initialDemoToken,
}) {
  return showDialog<AiVoiceConfig>(
    context: context,
    builder: (_) => _AiVoiceConfigDialog(
      initialEndpoint: initialEndpoint ?? kDefaultVoiceTransactionDemoEndpoint,
      initialDemoToken: initialDemoToken,
    ),
  );
}

class _AiVoiceConfigDialog extends StatefulWidget {
  const _AiVoiceConfigDialog({
    required this.initialEndpoint,
    required this.initialDemoToken,
  });

  final String initialEndpoint;
  final String? initialDemoToken;

  @override
  State<_AiVoiceConfigDialog> createState() => _AiVoiceConfigDialogState();
}

class _AiVoiceConfigDialogState extends State<_AiVoiceConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _tokenCtrl;
  var _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: widget.initialEndpoint);
    _tokenCtrl = TextEditingController(text: widget.initialDemoToken ?? "");
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final endpoint = VoiceTransactionDemoEndpoint.normalize(_endpointCtrl.text);
    final token = _tokenCtrl.text.trim();
    Navigator.of(context).pop(
      AiVoiceConfig(
        endpoint: endpoint,
        demoToken: token.isEmpty ? null : token,
      ),
    );
  }

  String? _validateEndpoint(String? value) {
    final raw = value?.trim() ?? "";
    if (raw.isEmpty) return "Endpoint không được rỗng.";
    if (!VoiceTransactionDemoEndpoint.isValidBase(raw)) {
      return "Endpoint phải bắt đầu bằng http:// hoặc https://.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cấu hình AI nhận diện giọng nói"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _endpointCtrl,
              decoration: const InputDecoration(
                labelText: "Endpoint API",
                hintText: kDefaultVoiceTransactionDemoEndpoint,
              ),
              keyboardType: TextInputType.url,
              validator: _validateEndpoint,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tokenCtrl,
              decoration: InputDecoration(
                labelText: "Demo token",
                suffixIcon: IconButton(
                  tooltip: _obscureToken ? "Hiện token" : "Ẩn token",
                  onPressed: () {
                    setState(() => _obscureToken = !_obscureToken);
                  },
                  icon: Icon(
                    _obscureToken
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: _obscureToken,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Huỷ"),
        ),
        FilledButton(onPressed: _save, child: const Text("Lưu và bật")),
      ],
    );
  }
}
