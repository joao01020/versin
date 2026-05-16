// Biblioteca nativa para efeitos visuais de renderização de imagem e desfoque
import 'dart:ui';
// Pacote base do Flutter para componentes visuais (Material Design)
import 'package:flutter/material.dart';
// Cliente oficial do Supabase para escuta de dados em tempo real e Queries
import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTAÇÕES DAS PÁGINAS DOS MÓDULOS DO SEU ECOSSISTEMA
import 'package:versin/features/rhymes/presentation/pages/chat_page.dart';
import 'package:versin/modules/hub/hub_page.dart';
import 'package:versin/modules/match/match_page.dart';
import 'package:versin/modules/wallet/wallet_page.dart';
import 'package:versin/modules/market/market_page.dart'; 
import 'package:versin/modules/showcase/showcase_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart'; 
import 'package:versin/modules/settings/settings_page.dart'; 

// Declaração do Widget Stateful da Dashboard (necessário pois há estados de navegação e calendário)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// Classe de estado correspondente à DashboardPage
class _DashboardPageState extends State<DashboardPage> {
  // Controlador para gerenciar a transição de páginas e animações do PageView
  late final PageController _pageController;
  
  // Variável inteira que guarda o índice da página activa no painel do Dashboard
  int _currentIndex = 0;

  // CORES COERENTES COM O TEMA CYBERPUNK/DARK DO PROJETO
  final Color primaryPurple = const Color(0xFF6A1B9A); // Roxo principal
  final Color deepBg = const Color(0xFF0D0B1F);        // Fundo escuro azulado
  final Color accentNeon = const Color(0xFFE040FB);     // Rosa/Roxo Neon de destaque
  final Color hackerGreen = const Color(0xFF00FF66);    // Verde Hacker Neon para status Online
  
  // CORES EXCLUSIVAS DO CALENDÁRIO SINCRO COM A SUA REFERÊNCIA ESCURA
  final Color calendarBg = const Color(0xFF1E1E1E);
  final Color calendarPurpleAccent = const Color(0xFF9C27B0);

  // String opcional para rastrear o caminho da imagem de perfil local do usuário
  String? _profileImagePath;

  // ESTADOS DE CONTROLE DO CALENDÁRIO INTERATIVO
  bool _isCalendarExpanded = false;          // Controla se a grade de dias está aberta (true) ou colapsada (false)
  DateTime _focusedDay = DateTime.now();     // Objeto que monitora qual mês e ano estão atualmente visíveis no topo
  int _selectedDay = DateTime.now().day;     // Mantém em memória qual dia do mês foi clicado para filtrar compromissos

  // ESTADO DE EXPANSÃO DO CARD DE PERFIL (VERSIN ECOSYSTEM RECENT ACTIVITIES)
  bool _isProfileCardExpanded = true;

  // Lista dinâmica simulando banco em memória (Mock) para agendamentos do Beatmaker
  final List<Map<String, dynamic>> _appointments = [
    {"day": DateTime.now().day, "month": DateTime.now().month, "year": DateTime.now().year, "time": "14:00", "title": "Sessão de Mixagem - Trap Beat"},
    {"day": DateTime.now().day, "month": DateTime.now().month, "year": DateTime.now().year, "time": "18:30", "title": "Sync do banco com Supabase V2"},
    {"day": 20, "month": 5, "year": 2026, "time": "10:00", "title": "Recuperar batidas antigas"},
  ];

  @override
  void initState() {
    super.initState();
    // Inicializa o PageController apontando nativamente para a primeira tela indexada (0)
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    // Desaloca o PageController da memória do aparelho assim que a página for destruída
    _pageController.dispose();
    super.dispose();
  }

  // Método simulado disparado ao clicar no avatar do usuário
  void _pickProfileImage() {
    print("Abrir seletor de galeria");
  }

  // Callback acionado sempre que o usuário faz o gesto de arrastar o PageView
  void _onPageChanged(int index) {
    // Atualiza o estado interno alterando o índice ativo para redesenhar a UI
    setState(() => _currentIndex = index);
  }

  // Trata o clique nos menus, disparando uma animação suave até a página desejada
  void _navigationTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Duração de 300 milissegundos
      curve: Curves.easeInOut,                     // Curva de velocidade de entrada e saída suave
    );
  }

  // Retorna o texto exato do cabeçalho baseado no índice do módulo ativo
  String _getModuleTitle() {
    switch (_currentIndex) {
      case 0: return "Lab Module";
      case 1: return "Match";
      case 2: return "Market";
      case 3: return "Wallet";
      case 4: return "Studio Chat";
      case 5: return "Showcase";
      case 6: return "Hardware Hub";
      case 7: return "VNode Network";
      case 8: return "Settings";
      default: return "Dashboard";
    }
  }

  // Retorna o nome abreviado do mês passado por parâmetro inteiro
  String _getShortMonthName(int month) {
    const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
    return months[month - 1]; // Subtrai 1 pois a lista começa em índice zero
  }

  // Constrói e exibe a folha inferior (Modal Bottom Sheet) para criação de novas tarefas
  void _showAddAppointmentSheet({String? fixedTime}) {
    final TextEditingController titleController = TextEditingController();
    final now = DateTime.now();
    
    // Configura o horário padrão formatado (HH:MM) se nenhum valor fixo for enviado
    final String defaultTime = fixedTime ?? "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final TextEditingController timeController = TextEditingController(text: defaultTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que a modal suba acima do teclado virtual do aparelho
      backgroundColor: const Color(0xFF15122C), // Cor escura personalizada para a modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Arredonda as bordas superiores
      ),
      builder: (context) {
        return Padding(
          // Ajusta o padding dinamicamente com base na altura ocupada pelo teclado na tela
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Força a coluna a ocupar apenas o espaço necessário do conteúdo
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "NOVO COMPROMISSO - DIA $_selectedDay/${_focusedDay.month}",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context), // Fecha a tela modal
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Campo de texto para a descrição da tarefa
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  hintText: "Descrição do compromisso (ex: Gravar Vocais)",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              // Campo de texto para definir o horário da tarefa
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  hintText: "Horário (HH:MM)",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  prefixIcon: const Icon(Icons.access_time, color: Colors.white38, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              // Botão de confirmação de agendamento
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Executa a adição do mapa na lista apenas se ambos os campos contiverem texto válido
                    if (titleController.text.isNotEmpty && timeController.text.isNotEmpty) {
                      setState(() {
                        _appointments.add({
                          "day": _selectedDay,
                          "month": _focusedDay.month,
                          "year": _focusedDay.year,
                          "time": timeController.text,
                          "title": titleController.text,
                        });
                      });
                      Navigator.pop(context); // Fecha a modal após salvar os dados
                    }
                  },
                  child: const Text("AGENDAR NO CHASSI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder captura a largura máxima disponível para decidir a responsividade em tempo de execução
    return LayoutBuilder(builder: (context, constraints) {
      // Define como mobile se a largura da tela for inferior a 800 pixels lógicos
      bool isMobile = constraints.maxWidth < 800;

      return Scaffold(
        backgroundColor: Colors.black, 
        // Exibe a BottomNavigationBar apenas se for dispositivo mobile
        bottomNavigationBar: isMobile 
          ? Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.black), // Força o fundo da barra em preto
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _navigationTap, // Vincula o método de transição suave de página ao clique do ícone
                selectedItemColor: accentNeon,
                unselectedItemColor: Colors.white24,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed, // Trava o tamanho dos ícones na barra de menus inferior
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Dash"),
                  BottomNavigationBarItem(icon: Icon(Icons.share_outlined), label: "Match"),
                  BottomNavigationBarItem(icon: Icon(Icons.local_mall_outlined), label: "Market"), 
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: "Wallet"),
                  BottomNavigationBarItem(icon: Icon(Icons.mic_external_on_outlined), label: "Studio"),
                  BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: "Showcase"),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_input_component), label: "Hub"), 
                  BottomNavigationBarItem(icon: Icon(Icons.lan_outlined), label: "VNode"), 
                  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"), 
                ],
              ),
            ) 
          : null, // Caso seja Desktop/Tablet grande, desativa a barra de navegação inferior
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF2E1A47), deepBg, Colors.black], // Gradiente de fundo escuro do ecossistema
            ),
          ),
          child: Row(
            children: [
              // Se não for dispositivo mobile, injeta o menu lateral estruturado (SideRail)
              if (!isMobile) _buildSideRail(),
              Expanded(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(), // Renderiza a barra superior com o nome dinâmico da tela ativa
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: _onPageChanged, // Registra o callback para sincronizar gestos com o estado do menu
                          children: [
                            _buildLabModule(isMobile), // Página principal (Dashboard de métricas e hardware)
                            const MatchPage(),         
                            const MarketPage(),        
                            const WalletPage(),        
                            const ChatPage(),          
                            const ShowcasePage(),      
                            const HubPage(),           
                            const VNodePage(),         
                            const SettingsPage(),      
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Constrói a coluna de navegação lateral para layouts expandidos (Desktops e Tablets)
  Widget _buildSideRail() {
    return Container(
      width: 70,
      color: Colors.black.withOpacity(0.4),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _railItem(Icons.dashboard_outlined, 0),
            _railItem(Icons.share_outlined, 1),
            _railItem(Icons.local_mall_outlined, 2), 
            _railItem(Icons.account_balance_wallet_outlined, 3),
            _railItem(Icons.mic_external_on_outlined, 4),
            _railItem(Icons.storefront_outlined, 5),
            _railItem(Icons.settings_input_component, 6), 
            _railItem(Icons.lan_outlined, 7), 
            _railItem(Icons.settings_outlined, 8), 
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Componente individual de item de menu do SideRail lateral
  Widget _railItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index; // Verifica se este botão específico corresponde à aba ativa
    return GestureDetector(
      onTap: () => _navigationTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // Cria uma pequena barra neon vertical no lado esquerdo se o item estiver selecionado
          border: isSelected ? Border(left: BorderSide(color: accentNeon, width: 3)) : null,
        ),
        child: Icon(icon, color: isSelected ? accentNeon : Colors.white24, size: 28),
      ),
    );
  }

  // Componente visual do topo da página com título em caixa alta estilizado
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getModuleTitle().toUpperCase(), // Converte dinamicamente o título do módulo ativo para caixa alta
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Container(height: 3, width: 30, color: accentNeon), // Pequeno traço decorativo neon abaixo do título
        ],
      ),
    );
  }

  // Agrupa os componentes internos que formam o Lab Module (Painel principal de controle)
  Widget _buildLabModule(bool isMobile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Efeito elástico ao rolar em dispositivos móveis
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Se for mobile, empilha o card de perfil e o do Hub verticalmente; se for desktop, coloca lado a lado em Row
          isMobile 
          ? Column(
              children: [
                _buildAccountActivitiesCard(),
                const SizedBox(height: 16),
                _buildHubStatusCard(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAccountActivitiesCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildHubStatusCard()),
              ],
            ),
          const SizedBox(height: 20),
          _buildMainChartCard(), // Renderiza o gráfico de estatísticas das batidas do Versin
          const SizedBox(height: 20),
          _buildCalendarCard(),   // Renderiza a estrutura escura interativa do calendário de agendamentos
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Constrói o card de perfil do usuário contendo suas atividades recentes cadastradas
  Widget _buildAccountActivitiesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1A3A), Color(0xFF0D0B1F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1F1A3A).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  // Inverte o estado de expansão do card visual de atividades ao receber o toque do usuário
                  setState(() {
                    _isProfileCardExpanded = !_isProfileCardExpanded;
                  });
                },
                child: Icon(
                  _isProfileCardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 22,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFFFCC80), 
              backgroundImage: _profileImagePath != null ? NetworkImage(_profileImagePath!) : null,
              child: _profileImagePath == null 
                  ? const Icon(Icons.person, color: Color(0xFF2E1A47), size: 40) 
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Astryvo",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            "Beatmaker",
            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircularActionIcon(Icons.description_outlined),
              const SizedBox(width: 16),
              _buildCircularActionIcon(Icons.calendar_today_outlined),
              const SizedBox(width: 16),
              _buildCircularActionIcon(Icons.notifications_none_outlined, hasNotification: true),
            ],
          ),
          // Bloco condicional injetado apenas se a propriedade de expansão for verdadeira (true)
          if (_isProfileCardExpanded) ...[
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Atividades Recentes",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${DateTime.now().day.toString().padLeft(2, '0')} ${_getShortMonthName(_focusedDay.month)} ${_focusedDay.year}",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_toggle_off, color: Colors.white24, size: 28),
                  SizedBox(height: 8),
                  Text(
                    "Nenhuma atividade recente por aqui.",
                    style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Componente auxiliar para renderizar botões de ação circulares e indicadores de notificação
  Widget _buildCircularActionIcon(IconData icon, {bool hasNotification = false}) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        // Pequena marcação redonda laranja inserida de forma absoluta caso haja notificação pendente
        if (hasNotification)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // CARD DO STATUS DO HUB (CORRIGIDO PROBLEMA DE TIMEZONE)
  // ==========================================================
  Widget _buildHubStatusCard() {
    // Declaração do fluxo contínuo do stream escutando alterações na tabela do Supabase em tempo real
    final supabaseStream = Supabase.instance.client
        .from('status_hardware')
        .stream(primaryKey: ['id'])
        .eq('id', 1); // Filtra rigorosamente pelo registro onde o ID é idêntico a 1

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabaseStream,
      builder: (context, snapshot) {
        // Inicializações padrões das variáveis de status da interface física do hub
        String statusReal = "offline";
        bool estaOnlineDeVerdade = false;
        String mensagemStatus = "Hardware desconectado";
        Color statusColor = Colors.redAccent;

        // Bloco executado apenas se o snapshot de dados do stream contiver uma lista populada e válida
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final dadosHardware = snapshot.data!.first; // Extrai o mapa do primeiro registro da consulta
          statusReal = dadosHardware['status'] ?? 'offline'; // Recupera o campo status de texto do banco

          // Executa tratamento temporal do hardware apenas se o campo timestamp não for nulo
          if (dadosHardware['updated_at'] != null) {
            // Conversão da data em String pura para tratamento manual de fuso horário
            String dateStr = dadosHardware['updated_at'].toString();
            
            // BLINDAGEM DE TIMEZONE: Se a string não contiver o marcador Z ou offset (+/-), forçamos o caractere Z
            if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
              dateStr += 'Z'; // Isso força o interpretador do Dart a processar a data como fuso UTC puro
            }

            // Realiza o parse transformando a String sanitizada em objeto DateTime em fuso UTC absoluto
            final DateTime updatedAt = DateTime.parse(dateStr).toUtc();
            // Captura o momento exato do relógio atual do dispositivo convertido para fuso UTC absoluto
            final DateTime agoraUtc = DateTime.now().toUtc();
            // Mede a diferença aritmética em segundos absolutos entre a hora atual e o último registro do banco
            final int diferencaSegundos = agoraUtc.difference(updatedAt).inSeconds.abs();

            // Validação de segurança: Status precisa marcar 'online' e o sinal ter sido enviado há menos de 10 minutos (600s)
            if (statusReal == 'online' && diferencaSegundos < 600) {
              estaOnlineDeVerdade = true;
              mensagemStatus = "Hub conectado via Apolo-system";
              statusColor = hackerGreen; // Altera a cor do circuito visual para verde neon ativo
            } else {
              // Caso o hardware estoure a janela de tempo de batimento, calcula a ociosidade do hardware
              mensagemStatus = "Último sinal há $diferencaSegundos segundos";
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A148C), Color(0xFF2E1A47)], // Gradiente de tons roxo escuro
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withOpacity(0.3), 
                blurRadius: 10, 
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("VERSIN HUB", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Icon(
                    estaOnlineDeVerdade ? Icons.sensors : Icons.sensors_off, 
                    color: Colors.white30, 
                    size: 18,
                  ),
                ],
              ),
              Row(
                children: [
                  // Círculo indicador luminoso de status com efeito de brilho (Neon Glow)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: statusColor, blurRadius: 8, spreadRadius: 2), // Aplica efeito difuso brilhante
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    estaOnlineDeVerdade ? "Online" : "Offline", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(mensagemStatus, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  // Desenha o gráfico fictício de barras representando as métricas das batidas na Dashboard
  Widget _buildMainChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Estatísticas Versin", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                // Equação puramente matemática simples para simular as alturas variáveis das barras do gráfico
                double barHeight = (20 + (index * 12)) % 100 + 40;
                return Container(
                  width: 15,
                  height: barHeight,
                  decoration: BoxDecoration(
                    // Destaca em rosa neon apenas a última barra do gráfico, suavizando as anteriores
                    color: index == 11 ? accentNeon : primaryPurple.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPONENTE DO CALENDÁRIO ATUALIZADO E COMPLETO
  // ==========================================================
  Widget _buildCalendarCard() {
    // Filtra em tempo real a lista de compromissos batendo estritamente com o dia, mês e ano selecionados na UI
    final List<Map<String, dynamic>> filteredAppointments = _appointments.where((element) {
      return element['day'] == _selectedDay && 
             element['month'] == _focusedDay.month && 
             element['year'] == _focusedDay.year;
    }).toList();

    // Calcula dinamicamente o número exato de dias contidos no mês ativo em visualização
    final int daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    // Calcula o deslocamento do dia da semana (offset) correspondente ao primeiro dia do mês ativo
    final int firstDayOffset = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday % 7;

    // Vetor contendo a listagem nominal dos meses traduzidos em português
    final List<String> monthsNames = [
      "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
      "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14), 
      decoration: BoxDecoration(
        color: calendarBg, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  // Alterna o estado de expansão da grade inteira de dias ao aplicar toque duplo
                  onDoubleTap: () {
                    setState(() => _isCalendarExpanded = !_isCalendarExpanded);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: calendarPurpleAccent, size: 16),
                      const SizedBox(width: 8),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: calendarBg), // Altera cor interna do menu suspenso
                        child: DropdownButtonHideUnderline(
                          child: SizedBox(
                            height: 24,
                            child: DropdownButton<int>(
                              value: _focusedDay.month, // Mês ativo no topo
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 16),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              onChanged: (int? newMonth) {
                                if (newMonth != null) {
                                  setState(() {
                                    // Altera o mês reconfigurando o objeto de controle e resetando o dia padrão para 1
                                    _focusedDay = DateTime(_focusedDay.year, newMonth, 1);
                                    _selectedDay = 1; 
                                  });
                                }
                              },
                              items: List.generate(12, (index) => index + 1).map((int monthNum) {
                                return DropdownMenuItem<int>(
                                  value: monthNum,
                                  child: Text(monthsNames[monthNum - 1]),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: calendarBg),
                        child: DropdownButtonHideUnderline(
                          child: SizedBox(
                            height: 24,
                            child: DropdownButton<int>(
                              value: _focusedDay.year, // Ano ativo no topo
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 16),
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                              onChanged: (int? newYear) {
                                if (newYear != null) {
                                  setState(() {
                                    // Altera o ano reconfigurando o objeto de controle e resetando o dia padrão para 1
                                    _focusedDay = DateTime(newYear, _focusedDay.month, 1);
                                    _selectedDay = 1; 
                                  });
                                }
                              },
                              items: List.generate(6, (index) => 2026 + index).map((int year) {
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text("$year"),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                        color: Colors.white38, 
                        size: 14
                      )
                    ],
                  ),
                ),
              ),
              // Exibe botões rápidos de navegação de meses apenas se o calendário estiver expandido
              if (_isCalendarExpanded)
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left, color: Colors.white60, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                          _selectedDay = 1; 
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_right, color: Colors.white60, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                          _selectedDay = 1;
                        });
                      },
                    ),
                  ],
                )
              // Se tiver recolhido e contiver agendamentos salvos, desenha uma tag com a contagem de tarefas
              else if (filteredAppointments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: calendarPurpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "${filteredAppointments.length} Tasks",
                    style: TextStyle(color: calendarPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          // Injeta a grade estruturada de dias da semana e dias numéricos apenas se expandido
          if (_isCalendarExpanded) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ["D", "S", "T", "Q", "Q", "S", "S"].map((d) => 
                Expanded(
                  child: Center(
                    child: Text(d, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 6),
            // Desenha a malha quadriculada mapeando todos os dias do mês ativo
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Desativa rolagem independente interna no GridView
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,       // Define estruturalmente 7 colunas (uma para cada dia da semana)
                mainAxisSpacing: 4,      // Espaçamento vertical entre blocos
                crossAxisSpacing: 4,     // Espaçamento horizontal entre blocos
                childAspectRatio: 1.0,   // Força proporção perfeitamente quadrada para os dias
              ),
              itemCount: daysInMonth + firstDayOffset, // Soma total de dias úteis com o deslocamento da semana
              itemBuilder: (context, index) {
                // Devolve espaço invisível enquanto o loop não alcança o dia inicial da semana daquele mês
                if (index < firstDayOffset) return const SizedBox.shrink();
                final int day = index - firstDayOffset + 1; // Calcula o numeral exato correspondente ao dia
                final bool isSelected = day == _selectedDay; // Verifica se o bloco desenhado corresponde ao dia selecionado
                
                // Varre a lista de tarefas buscando se há registros para este dia específico da malha
                final bool hasAppointment = _appointments.any((element) => 
                  element['day'] == day && 
                  element['month'] == _focusedDay.month && 
                  element['year'] == _focusedDay.year
                );

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day), // Atualiza o dia ativo no painel de tarefas
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? calendarPurpleAccent : Colors.transparent, // Preenche se estiver selecionado
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "$day",
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white24, // Inverte cor do texto se ativo
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        // Desenha um pequeno ponto indicador roxo na base do quadrado caso o dia possua tarefa agendada
                        if (hasAppointment && !isSelected)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(color: calendarPurpleAccent, shape: BoxShape.circle),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          // Loop dinâmico desestruturando e renderizando todos os compromissos filtrados para o dia ativo
          ...filteredAppointments.map((app) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            // BUG CORRIGIDO: Modificado de Colors.black24 (inexistente) para custom opacity funcional
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.24), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text(app['time'], style: TextStyle(color: calendarPurpleAccent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                const SizedBox(width: 10),
                Expanded(child: Text(app['title'], style: const TextStyle(color: Colors.white60, fontSize: 11))),
              ],
            ),
          )).toList(),
          const SizedBox(height: 6),
          // Botão delineado para disparo e abertura da modal sheet de novos agendamentos
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: calendarPurpleAccent.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showAddAppointmentSheet(), // Invoca o método construtor da modal inferior
              icon: Icon(Icons.add, color: calendarPurpleAccent, size: 14),
              label: Text("ADD TASK", style: TextStyle(color: calendarPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}