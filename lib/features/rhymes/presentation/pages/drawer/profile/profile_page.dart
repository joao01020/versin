import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  String? _username;
  String? _walletAddress;
  String? _avatarUrl;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select('username, wallet_address, avatar_url, created_at')
          .eq('id', user.id)
          .single();

      setState(() {
        _username = data['username'];
        _walletAddress = data['wallet_address'];
        _avatarUrl = data['avatar_url'];
        _createdAt = DateTime.parse(data['created_at']);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE UPLOAD DE FOTO ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      final fileBytes = await image.readAsBytes();
      final fileName = '${user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Upload para o Storage
      await _supabase.storage.from('avatars').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      // 2. Pegar URL Pública
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // 3. Atualizar no banco
      await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);

      setState(() {
        _avatarUrl = publicUrl;
        _isLoading = false;
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto atualizada! 📸")));
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Erro upload: $e");
    }
  }

  // --- MODAL DE EDIÇÃO COMPLETO ---
  Future<void> _showEditModal() async {
    final nameController = TextEditingController(text: _username);
    final walletController = TextEditingController(text: _walletAddress);
    bool isCheckingWallet = false;
    bool isSaving = false;
    String? walletError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
          title: const Text("EDITAR PERFIL", style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameController, "Nome de Usuário", Icons.person_outline),
                const SizedBox(height: 16),
                _buildField(
                  walletController, 
                  "Nome da Carteira", 
                  Icons.account_balance_wallet_outlined,
                  prefix: "wallet@",
                  errorText: walletError,
                  onChanged: (val) async {
                    if (val.isEmpty || val == _walletAddress) {
                      setModalState(() => walletError = null);
                      return;
                    }
                    setModalState(() => isCheckingWallet = true);
                    // Verifica se o nome já existe no banco
                    final res = await _supabase.from('profiles').select('wallet_address').eq('wallet_address', val).maybeSingle();
                    setModalState(() {
                      isCheckingWallet = false;
                      walletError = res != null ? "Este nome já está em uso" : null;
                    });
                  }
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: (isSaving || isCheckingWallet || walletError != null) ? null : () async {
                setModalState(() => isSaving = true);
                final user = _supabase.auth.currentUser;
                await _supabase.from('profiles').update({
                  'username': nameController.text.trim(),
                  'wallet_address': walletController.text.trim(),
                }).eq('id', user!.id);
                
                await _loadProfileData(); // Recarrega os dados na tela principal
                if (mounted) Navigator.pop(context);
              },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Salvar", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String memberSince = _createdAt != null ? DateFormat('MMMM yyyy', 'pt_BR').format(_createdAt!) : "Carregando...";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('MEU PERFIL', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w300, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.purpleAccent, width: 2),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                  ? NetworkImage(_avatarUrl!)
                                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            ),
                          ),
                        ),
                      ),
                      Positioned(bottom: 0, right: 0, child: IgnorePointer(child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 18, color: Colors.black)))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(_username?.toUpperCase() ?? "USUÁRIO SEM NOME", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 16, color: _walletAddress != null ? Colors.greenAccent : Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Text(_walletAddress != null ? "wallet@$_walletAddress" : "Sem carteira vinculada", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildInfoTile("Status da Carteira", _walletAddress != null ? "Carteira Ativa ✅" : "Sem Carteira Ativa ❌", Icons.verified_user),
                _buildInfoTile("Membro desde", memberSince, Icons.calendar_today),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _showEditModal,
                    child: const Text("EDITAR INFORMAÇÕES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {String? prefix, String? errorText, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixText: prefix,
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purpleAccent)),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}