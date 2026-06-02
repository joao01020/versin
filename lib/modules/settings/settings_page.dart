import 'package:flutter/material.dart';
import 'package:versin/app/routes/app_routes.dart';

class SettingsPage
    extends
        StatefulWidget {
  static const String routeName = AppRoutes.settings;

  const SettingsPage({
    super.key,
  });

  @override
  State<
    SettingsPage
  >
  createState() => _SettingsPageState();
}

class _SettingsPageState
    extends
        State<
          SettingsPage
        > {
  final Color primaryPurple = const Color(
    0xFF6A1B9A,
  );
  final Color accentNeon = const Color(
    0xFFE040FB,
  );
  final Color deepBg = const Color(
    0xFF0D0B1F,
  );

  bool _syncCloud = true;
  bool _autoSave = true;

  bool _isApiExpanded = false;
  bool _obscureApiKey = true;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),

            _buildSectionTitle(
              "Perfil do Produtor",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryPurple.withValues(
                        alpha: 0.3,
                      ),
                      child: Icon(
                        Icons.person,
                        color: accentNeon,
                      ),
                    ),
                    title: const Text(
                      "Informações da Conta",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      "Editar e-mail, nome de usuário e avatar",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 16,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "Preferências do Sistema",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: "Sincronização",
                    subtitle: "Manter banco de dados local e nuvem em tempo real",
                    value: _syncCloud,
                    onChanged:
                        (
                          val,
                        ) => setState(
                          () => _syncCloud = val,
                        ),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: "Auto-Salvar Rascunhos",
                    subtitle: "Salvar rimas e composições automaticamente ao digitar",
                    value: _autoSave,
                    onChanged:
                        (
                          val,
                        ) => setState(
                          () => _autoSave = val,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "Integrações & Hardware",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.settings_input_component,
                      color: accentNeon,
                      size: 22,
                    ),
                    title: const Text(
                      "Versin Hub Config",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      "Gerenciar conexões de hardware externo",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 16,
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),

                  Theme(
                    data:
                        Theme.of(
                          context,
                        ).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                    child: ExpansionTile(
                      onExpansionChanged:
                          (
                            expanded,
                          ) {
                            setState(
                              () => _isApiExpanded = expanded,
                            );
                          },
                      leading: Icon(
                        Icons.vpn_key_outlined,
                        color: accentNeon,
                        size: 22,
                      ),
                      title: const Text(
                        "Configurar API Privada",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      subtitle: const Text(
                        "Gerenciar credenciais e chaves externas de IA/Serviços",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        _isApiExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white24,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 20,
                            top: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: 0.02,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Esta opção opcional concede autonomia para vincular sua própria chave de API ao ecossistema Versin. "
                                  "Recomendado para contornar limitações padrão de cota de requisições ou para aplicar modelos neurais customizados dedicados.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              TextField(
                                controller: _apiKeyController,
                                obscureText: _obscureApiKey,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Insira sua API Key privada",
                                  hintStyle: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.02,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide(
                                      color: accentNeon.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureApiKey
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white30,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _obscureApiKey = !_obscureApiKey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              "Segurança & Criptografia",
            ),
            _buildSettingsContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.vpn_key,
                      color: Colors.white60,
                      size: 22,
                    ),
                    title: const Text(
                      "Gerenciar Par de Chaves",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      "Backup e rotação das chaves públicas e privadas da rede",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 16,
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    title: const Text(
                      "Sair da Conta",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            Center(
              child: Text(
                "Versin Genesis v0.0.1",
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.2,
                  ),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: accentNeon.withValues(
            alpha: 0.8,
          ),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.04,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<
      bool
    >
    onChanged,
  }) {
    return SwitchListTile(
      activeColor: accentNeon,
      activeTrackColor: primaryPurple.withValues(
        alpha: 0.4,
      ),
      inactiveThumbColor: Colors.white54,
      inactiveTrackColor: Colors.white12,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(
        alpha: 0.05,
      ),
      indent: 16,
      endIndent: 16,
    );
  }
}
