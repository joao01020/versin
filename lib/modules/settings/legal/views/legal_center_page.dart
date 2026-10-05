import 'package:flutter/material.dart';

import 'package:versin/modules/settings/legal/content/legal_content.dart';
import 'package:versin/modules/settings/legal/views/app_version_page.dart';
import 'package:versin/modules/settings/legal/views/legal_document_page.dart';
import 'package:versin/modules/settings/views/account_privacy_page.dart';

class LegalCenterPage
    extends
        StatelessWidget {
  const LegalCenterPage({
    super.key,
  });

  static const Color _background = Color(
    0xFF0D0B1F,
  );
  static const Color _surface = Color(
    0xFF17132D,
  );
  static const Color _accent = Color(
    0xFFE040FB,
  );
  static const Color _purple = Color(
    0xFF6A1B9A,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Sobre & Legal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 820,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(
                    height: 28,
                  ),
                  _sectionTitle(
                    'Documentos',
                  ),
                  _card(
                    children: [
                      _tile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Política de Privacidade',
                        subtitle: 'Como o Versin trata dados, privacidade e retenção.',
                        onTap: () => _openDocument(
                          context,
                          title: 'Política de Privacidade',
                          content: VersinLegalContent.privacyPolicy,
                        ),
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.gavel_outlined,
                        title: 'Termos de Uso',
                        subtitle: 'Regras para uso da conta, conteúdos e recursos.',
                        onTap: () => _openDocument(
                          context,
                          title: 'Termos de Uso',
                          content: VersinLegalContent.termsOfUse,
                        ),
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.code_rounded,
                        title: 'Licenças de código aberto',
                        subtitle: 'Licenças dos pacotes e bibliotecas utilizados.',
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'Versin',
                            applicationLegalese: 'Versin Genesis',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  _sectionTitle(
                    'Versin',
                  ),
                  _card(
                    children: [
                      _tile(
                        icon: Icons.info_outline_rounded,
                        title: 'Sobre o Versin',
                        subtitle: 'Conceito, propósito e ecossistema Genesis.',
                        onTap: () => _openDocument(
                          context,
                          title: 'Sobre o Versin',
                          content: VersinLegalContent.aboutVersin,
                        ),
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.new_releases_outlined,
                        title: 'Versão do aplicativo',
                        subtitle: 'Versão, build e identificação do pacote.',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute<
                              void
                            >(
                              builder:
                                  (
                                    _,
                                  ) => const AppVersionPage(),
                            ),
                          );
                        },
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.security_outlined,
                        title: 'Segurança e privacidade',
                        subtitle: 'Como a arquitetura protege conta, dados e operações.',
                        onTap: () => _openDocument(
                          context,
                          title: 'Segurança e privacidade',
                          content: VersinLegalContent.securityAndPrivacy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  _sectionTitle(
                    'Conta',
                  ),
                  _card(
                    children: [
                      _tile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Exclusão de conta e dados',
                        subtitle: 'Abrir controles de dados pessoais e exclusão da conta.',
                        danger: true,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(
                            MaterialPageRoute<
                              void
                            >(
                              builder:
                                  (
                                    _,
                                  ) => const AccountPrivacyPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  _sectionTitle(
                    'Créditos',
                  ),
                  _card(
                    children: [
                      _tile(
                        icon: Icons.favorite_border_rounded,
                        title: 'Créditos',
                        subtitle: 'Tecnologias, software livre e agradecimentos.',
                        onTap: () => _openDocument(
                          context,
                          title: 'Créditos',
                          content: VersinLegalContent.credits,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withValues(
              alpha: 0.38,
            ),
            _surface,
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: _accent.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _accent.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                17,
              ),
              border: Border.all(
                color: _accent.withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                9,
              ),
              child: Image.asset(
                'assets/logo/logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VERSIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'Informações, privacidade e documentos do aplicativo.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        value.toUpperCase(),
        style: const TextStyle(
          color: _accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _card({
    required List<
      Widget
    >
    children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: _surface.withValues(
          alpha: 0.76,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: danger
              ? Colors.redAccent.withValues(
                  alpha: 0.08,
                )
              : _accent.withValues(
                  alpha: 0.08,
                ),
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: Icon(
          icon,
          color: danger
              ? Colors.redAccent
              : _accent,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger
              ? Colors.redAccent
              : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(
          top: 3,
        ),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
      ),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.white.withValues(
        alpha: 0.055,
      ),
      height: 1,
    );
  }

  void _openDocument(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              _,
            ) => LegalDocumentPage(
              title: title,
              markdown: content,
            ),
      ),
    );
  }
}
