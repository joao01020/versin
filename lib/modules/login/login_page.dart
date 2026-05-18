import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // CORES DO ECOSSISTEMA VERSIN
  final Color deepBg = const Color(0xFF0D0B1F);
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentNeon = const Color(0xFFE040FB);
  final Color textMuted = Colors.white30;

  // CONTROLES DE INPUT
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();

  // CONTROLE DE EXPANSÃO DA IDENTIDADE LOCAL
  bool _isLocalFieldsExpanded = false;

  // CONTROLE DE VALIDAÇÃO E CONFIRMAÇÃO DO PSEUDÔNIMO
  bool _isUsernameAvailable = false;
  bool _isNameRepresented = false;

  @override
  void initState() {
    super.initState();
    // Inicializa a wallet totalmente vazia conforme solicitado
    _walletController.text = "";

    // Listener para sugerir automaticamente o endereço da wallet baseado no username
    _userController.addListener(() {
      final text = _userController.text.trim().toLowerCase();
      setState(() {
        if (text.isNotEmpty) {
          _walletController.text = "wallet@$text";
          _isUsernameAvailable = true; // Ativa o ícone de verificado dourado
        } else {
          _walletController.text = "";
          _isUsernameAvailable = false;
          _isNameRepresented = false; // Reseta o checkbox se o campo for limpo
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  // MÉTODOS DE AUTENTICAÇÃO (MOCKS PARA SUA INTEGRAÇÃO FUTURA)
  void _loginWithGoogle() {
    print("Iniciando fluxo Supabase/Firebase Google Auth...");
  }

  void _loginWithGitHub() {
    print("Iniciando fluxo Supabase/Firebase GitHub Auth...");
  }

  void _registerCustomProfile() {
    if (_formKey.currentState!.validate() && _isNameRepresented) {
      print("Registrando Chassi de Usuário:");
      print("Nome: ${_nameController.text}");
      print("User: ${_userController.text}");
      print("Wallet Nv: ${_walletController.text}");
      
      // Navegação limpa para o dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A0B2E), deepBg, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HEADER LOGO VERSIN
                  Hero(
                    tag: 'versin_logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentNeon.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: accentNeon.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(Icons.all_inclusive_rounded, color: accentNeon, size: 42),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "VERSIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                    ),
                  ),
                  // TRADUÇÃO APLICADA DIRETAMENTE NO CHASSI
                  const Text(
                    "Ecossistema Descentralizado",
                    style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),

                  // BOTÕES DE LOGIN SOCIAL (GOOGLE / GITHUB COM ÍCONES REAIS)
                  _buildSocialButton(
                    label: "Entrar com o Google",
                    isGoogle: true,
                    onTap: _loginWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    label: "Conectar via GitHub",
                    isGoogle: false,
                    onTap: _loginWithGitHub,
                  ),

                  const SizedBox(height: 32),

                  // DIVISOR INTERATIVO / BOTÃO PARA EXPANDIR
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLocalFieldsExpanded = !_isLocalFieldsExpanded;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                "OU CRIE IDENTIDADE LOCAL",
                                style: TextStyle(
                                  color: _isLocalFieldsExpanded ? accentNeon : accentNeon.withOpacity(0.5),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isLocalFieldsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: accentNeon.withOpacity(0.5),
                                size: 12,
                              )
                            ],
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
                      ],
                    ),
                  ),

                  // ANIMAÇÃO SUAVE DE EXPANSÃO NA PRÓPRIA PÁGINA
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    firstChild: const SizedBox(width: double.infinity, height: 16),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // CAMPO: NOME COMPLETO
                            _buildInputField(
                              controller: _nameController,
                              hint: "Seu nome ou pseudônimo",
                              label: "NOME",
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v!.isEmpty ? "Insira seu nome" : null,
                            ),
                            const SizedBox(height: 16),

                            // CAMPO: USERNAME (CORREÇÃO: EXIBE ÍCONE VERIFICADO DOURADO QUANDO DISPONÍVEL)
                            _buildInputField(
                              controller: _userController,
                              hint: "ex: astryvo",
                              label: "USERNAME",
                              icon: Icons.alternate_email_rounded,
                              suffixIcon: _isUsernameAvailable 
                                  ? const Icon(Icons.verified, color: Color(0xFFFFD700), size: 18)
                                  : null,
                              validator: (v) => v!.isEmpty ? "Defina um username único" : null,
                            ),
                            const SizedBox(height: 16),

                            // CAMPO: CARTEIRA CRIPTOGRÁFICA (CORREÇÃO: SEM OS "...")
                            _buildInputField(
                              controller: _walletController,
                              hint: "",
                              label: "ENDEREÇO DA WALLET",
                              icon: Icons.account_balance_wallet_outlined,
                              isReadOnly: true,
                              customTextColor: accentNeon,
                              validator: (v) => v!.isEmpty ? "Aguardando username..." : null,
                            ),
                            
                            // SEÇÃO DE CONFIRMAÇÃO CONDICIONAL (SÓ REVELA QUANDO COMEÇA A PREENCHER O USER)
                            if (_isUsernameAvailable) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryPurple.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isNameRepresented ? accentNeon.withOpacity(0.3) : Colors.white.withOpacity(0.05)
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Theme(
                                      data: ThemeData(unselectedWidgetColor: Colors.white24),
                                      child: Checkbox(
                                        value: _isNameRepresented,
                                        activeColor: accentNeon,
                                        checkColor: Colors.black,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _isNameRepresented = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                          children: [
                                            const TextSpan(text: "Seu pseudônimo vai ser "),
                                            TextSpan(
                                              text: _walletController.text,
                                              style: TextStyle(color: accentNeon, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                            ),
                                            const TextSpan(text: " , esse nome te representa?"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // BOTÃO CONFIGURAR CHASSI E ENTRAR (CORREÇÃO: SEMPRE VISÍVEL NA ÁRVORE, SÓ BLOQUEIA O PRESS)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isNameRepresented 
                                      ? primaryPurple.withOpacity(0.3) 
                                      : primaryPurple.withOpacity(0.05),
                                  foregroundColor: _isNameRepresented ? Colors.white : Colors.white30,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: _isNameRepresented ? accentNeon.withOpacity(0.6) : Colors.white.withOpacity(0.05), 
                                    width: 1.5
                                  ),
                                  shadowColor: accentNeon.withOpacity(0.2),
                                ),
                                onPressed: _isNameRepresented ? _registerCustomProfile : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fingerprint, size: 18, color: _isNameRepresented ? accentNeon : Colors.white30),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "INICIALIZAR CHASSI",
                                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    crossFadeState: _isLocalFieldsExpanded 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    "Ao inicializar, você concorda com os protocolos criptográficos do ecossistema.",
                    style: TextStyle(color: Colors.white12, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: BOTÃO DE REDE SOCIAL COM ÍCONES VETORIAIS OFICIAIS
  Widget _buildSocialButton({
    required String label,
    required bool isGoogle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(
                painter: isGoogle ? _GoogleIconPainter() : _GitHubIconPainter(),
              ),
            ),
            const Expanded(child: SizedBox()),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Expanded(child: SizedBox()),
            const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: CAMPOS DE TEXTO ESTILIZADOS CYBERPUNK (CORREÇÃO: ADICIONADO PARAMETRO SUFFIXICON)
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    bool isReadOnly = false,
    Color? customTextColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          validator: validator,
          style: TextStyle(
            color: customTextColor ?? Colors.white, 
            fontSize: 14, 
            fontFamily: isReadOnly ? 'monospace' : null,
            fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isReadOnly ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.02),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12, fontSize: 13),
            prefixIcon: Icon(icon, color: isReadOnly ? accentNeon.withOpacity(0.5) : Colors.white30, size: 18),
            suffixIcon: suffixIcon, // Vincula dinamicamente o verificado dourado
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isReadOnly ? accentNeon.withOpacity(0.15) : Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentNeon.withOpacity(0.4)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// PAINTER 1: ÍCONE VETORIAL DO GOOGLE (G MULTICOLORIDO OFICIAL)
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Vermelho (Top)
    paint.color = const Color(0xFFEA4335);
    final Path pTop = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.5, 0)
      ..cubicTo(w * 0.28, 0, w * 0.1, h * 0.15, w * 0.03, h * 0.35)
      ..lineTo(w * 0.21, h * 0.49)
      ..cubicTo(w * 0.26, h * 0.38, w * 0.37, h * 0.3, w * 0.5, h * 0.45);
    canvas.drawPath(pTop, paint);

    // Azul (Direita)
    paint.color = const Color(0xFF4285F4);
    final Path pRight = Path()
      ..moveTo(w, h * 0.5)
      ..cubicTo(w, h * 0.35, w * 0.94, h * 0.21, w * 0.84, h * 0.11)
      ..lineTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.82, h * 0.55)
      ..cubicTo(w * 0.8, h * 0.65, w * 0.72, h * 0.73, w * 0.62, h * 0.78)
      ..lineTo(w * 0.8, h * 0.92)
      ..cubicTo(w * 0.92, h * 0.82, w, h * 0.67, w, h * 0.5);
    canvas.drawPath(pRight, paint);

    // Amarelo (Esquerda)
    paint.color = const Color(0xFFFBBC05);
    final Path pLeft = Path()
      ..moveTo(w * 0.03, h * 0.35)
      ..cubicTo(0, h * 0.44, 0, h * 0.56, w * 0.03, h * 0.65)
      ..lineTo(w * 0.21, h * 0.51)
      ..cubicTo(w * 0.2, h * 0.47, w * 0.2, h * 0.43, w * 0.21, h * 0.49)
      ..lineTo(w * 0.03, h * 0.35);
    canvas.drawPath(pLeft, paint);

    // Verde (Bottom)
    paint.color = const Color(0xFF34A853);
    final Path pBottom = Path()
      ..moveTo(w * 0.03, h * 0.65)
      ..lineTo(w * 0.21, h * 0.51)
      ..cubicTo(w * 0.26, h * 0.62, w * 0.37, h * 0.7, w * 0.5, h * 0.7)
      ..cubicTo(w * 0.55, h * 0.7, w * 0.59, h * 0.69, w * 0.62, h * 0.67)
      ..lineTo(w * 0.8, h * 0.92)
      ..cubicTo(w * 0.72, h * 0.97, w * 0.61, h, w * 0.5, h)
      ..cubicTo(w * 0.3, h, w * 0.12, h * 0.86, w * 0.03, h * 0.65);
    canvas.drawPath(pBottom, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// PAINTER 2: ÍCONE VETORIAL DO GITHUB (SILHUETA OFICIAL SILK WHITE)
class _GitHubIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.22, 0, 0, h * 0.22, 0, h * 0.5)
      ..cubicTo(0, h * 0.72, w * 0.14, h * 0.91, w * 0.34, h * 0.98)
      ..cubicTo(w * 0.37, h * 0.98, w * 0.38, h * 0.97, w * 0.38, h * 0.95)
      ..lineTo(w * 0.38, h * 0.88)
      ..cubicTo(w * 0.24, h * 0.91, w * 0.21, h * 0.81, w * 0.21, h * 0.81)
      ..cubicTo(w * 0.19, h * 0.76, w * 0.15, h * 0.74, w * 0.15, h * 0.74)
      ..cubicTo(w * 0.11, h * 0.71, w * 0.15, h * 0.71, w * 0.15, h * 0.71)
      ..cubicTo(w * 0.2, h * 0.72, w * 0.22, h * 0.76, w * 0.22, h * 0.76)
      ..cubicTo(w * 0.26, h * 0.82, w * 0.32, h * 0.8, w * 0.34, h * 0.79)
      ..cubicTo(w * 0.34, h * 0.75, w * 0.36, h * 0.73, w * 0.38, h * 0.71)
      ..cubicTo(w * 0.27, h * 0.7, w * 0.15, h * 0.65, w * 0.15, h * 0.46)
      ..cubicTo(w * 0.15, h * 0.4, w * 0.17, h * 0.36, w * 0.21, h * 0.32)
      ..cubicTo(w * 0.2, h * 0.3, w * 0.18, h * 0.24, w * 0.21, h * 0.17)
      ..cubicTo(w * 0.21, h * 0.17, w * 0.25, h * 0.15, w * 0.34, h * 0.22)
      ..cubicTo(w * 0.38, h * 0.21, w * 0.42, h * 0.2, w * 0.5, h * 0.2)
      ..cubicTo(w * 0.58, h * 0.2, w * 0.62, h * 0.21, w * 0.66, h * 0.22)
      ..cubicTo(w * 0.75, h * 0.15, w * 0.79, h * 0.17, w * 0.79, h * 0.17)
      ..cubicTo(w * 0.82, h * 0.24, w * 0.8, h * 0.3, w * 0.79, h * 0.32)
      ..cubicTo(w * 0.83, h * 0.36, w * 0.85, h * 0.4, w * 0.85, h * 0.46)
      ..cubicTo(w * 0.85, h * 0.65, w * 0.73, h * 0.7, w * 0.62, h * 0.71)
      ..cubicTo(w * 0.64, h * 0.73, w * 0.66, h * 0.76, w * 0.66, h * 0.8)
      ..lineTo(w * 0.66, h * 0.95)
      ..cubicTo(w * 0.66, h * 0.97, w * 0.67, h * 0.98, w * 0.7, h * 0.98)
      ..cubicTo(w * 0.86, h * 0.91, w, h * 0.72, w, h * 0.5)
      ..cubicTo(w, h * 0.22, w * 0.78, 0, w * 0.5, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}