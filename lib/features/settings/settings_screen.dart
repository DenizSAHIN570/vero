import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vero/core/ai/provider_registry.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _storage = FlutterSecureStorage();

  String _selectedProvider = VeroConstants.kProviderClaude;

  // Text controllers for each provider's credentials
  final _claudeKeyCtrl = TextEditingController();
  final _openaiKeyCtrl = TextEditingController();
  final _geminiKeyCtrl = TextEditingController();
  final _ollamaUrlCtrl = TextEditingController();
  final _ollamaModelCtrl = TextEditingController();

  bool _obscureKeys = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _claudeKeyCtrl.dispose();
    _openaiKeyCtrl.dispose();
    _geminiKeyCtrl.dispose();
    _ollamaUrlCtrl.dispose();
    _ollamaModelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final provider =
        await _storage.read(key: VeroConstants.kProviderKey) ??
            VeroConstants.kProviderClaude;
    final claudeKey =
        await _storage.read(key: VeroConstants.kClaudeApiKey) ?? '';
    final openaiKey =
        await _storage.read(key: VeroConstants.kOpenAiApiKey) ?? '';
    final geminiKey =
        await _storage.read(key: VeroConstants.kGeminiApiKey) ?? '';
    final ollamaUrl =
        await _storage.read(key: VeroConstants.kOllamaBaseUrl) ??
            VeroConstants.kDefaultOllamaUrl;
    final ollamaModel =
        await _storage.read(key: VeroConstants.kOllamaModel) ??
            VeroConstants.kDefaultOllamaModel;

    if (!mounted) return;
    setState(() {
      _selectedProvider = provider;
      _claudeKeyCtrl.text = claudeKey;
      _openaiKeyCtrl.text = openaiKey;
      _geminiKeyCtrl.text = geminiKey;
      _ollamaUrlCtrl.text = ollamaUrl;
      _ollamaModelCtrl.text = ollamaModel;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await _storage.write(
        key: VeroConstants.kProviderKey, value: _selectedProvider);
    await _storage.write(
        key: VeroConstants.kClaudeApiKey, value: _claudeKeyCtrl.text.trim());
    await _storage.write(
        key: VeroConstants.kOpenAiApiKey, value: _openaiKeyCtrl.text.trim());
    await _storage.write(
        key: VeroConstants.kGeminiApiKey, value: _geminiKeyCtrl.text.trim());
    await _storage.write(
        key: VeroConstants.kOllamaBaseUrl, value: _ollamaUrlCtrl.text.trim());
    await _storage.write(
        key: VeroConstants.kOllamaModel, value: _ollamaModelCtrl.text.trim());

    setState(() => _saving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VeroColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                        color: colors.accent, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, 'AI Provider'),
          _providerSelector(context),
          const SizedBox(height: 24),
          _sectionHeader(context, 'API Keys'),
          _credentialsSection(context),
          const SizedBox(height: 24),
          _sectionHeader(context, 'Privacy'),
          _privacyNote(context),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final colors = Theme.of(context).extension<VeroColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _providerSelector(BuildContext context) {
    return Card(
      child: Column(
        children: ProviderRegistry.providerDisplayNames.entries.map((entry) {
          return RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: _selectedProvider,
            onChanged: (val) => setState(() => _selectedProvider = val!),
            activeColor: Theme.of(context).colorScheme.primary,
          );
        }).toList(),
      ),
    );
  }

  Widget _credentialsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle obscure
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Show keys',
                    style: TextStyle(
                        color: Theme.of(context)
                            .extension<VeroColors>()!
                            .textSecondary,
                        fontSize: 13)),
                Switch(
                  value: !_obscureKeys,
                  onChanged: (val) =>
                      setState(() => _obscureKeys = !val),
                ),
              ],
            ),
            _apiKeyField(
              label: 'Claude API Key',
              controller: _claudeKeyCtrl,
              hint: 'sk-ant-...',
              visible: _selectedProvider == VeroConstants.kProviderClaude,
            ),
            _apiKeyField(
              label: 'OpenAI API Key',
              controller: _openaiKeyCtrl,
              hint: 'sk-...',
              visible: _selectedProvider == VeroConstants.kProviderOpenAi,
            ),
            _apiKeyField(
              label: 'Gemini API Key',
              controller: _geminiKeyCtrl,
              hint: 'AIza...',
              visible: _selectedProvider == VeroConstants.kProviderGemini,
            ),
            if (_selectedProvider == VeroConstants.kProviderOllama) ...[
              _labeledField(
                  label: 'Ollama Base URL',
                  controller: _ollamaUrlCtrl,
                  hint: 'http://localhost:11434'),
              const SizedBox(height: 12),
              _labeledField(
                  label: 'Model name',
                  controller: _ollamaModelCtrl,
                  hint: 'llama3'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _apiKeyField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: _obscureKeys,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _labelText(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).extension<VeroColors>()!.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _privacyNote(BuildContext context) {
    final colors = Theme.of(context).extension<VeroColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: colors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'API keys are stored locally using Android Keystore encryption. They are never sent to anyone except the AI provider you select.',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
