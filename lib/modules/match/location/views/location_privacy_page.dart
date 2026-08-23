import 'package:flutter/material.dart';

class LocationPrivacyPage
    extends
        StatelessWidget {
  const LocationPrivacyPage({
    super.key,
  });

  static const String routeName = '/location-privacy';

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),

      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0D0B1F,
        ),

        foregroundColor: Colors.white,

        title: const Text(
          'Como usamos sua localização',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          22,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Localização no Versin',

              style: TextStyle(
                color: Colors.white,

                fontSize: 22,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            _buildSection(
              title: 'Por que usamos sua localização?',

              text:
                  'Usamos sua localização aproximada para '
                  'encontrar artistas e profissionais próximos '
                  'que possam participar de projetos, sessões, '
                  'eventos e colaborações presenciais.',
            ),

            _buildSection(
              title: 'O que outros usuários conseguem ver?',

              text:
                  'Outros usuários não recebem sua latitude, '
                  'longitude, coordenadas GPS ou endereço exato. '
                  'A localização é utilizada apenas pelo sistema '
                  'para calcular proximidade entre perfis.',
            ),

            _buildSection(
              title: 'Compartilhamos sua localização?',

              text:
                  'Não compartilhamos sua localização exata com '
                  'outros usuários. O Versin utiliza os dados de '
                  'localização somente para executar os recursos '
                  'relacionados à descoberta por proximidade.',
            ),

            _buildSection(
              title: 'Como a proximidade funciona?',

              text:
                  'Quando você utiliza o modo Próximos, o Versin '
                  'obtém sua posição disponível no dispositivo e '
                  'compara a distância com outros profissionais '
                  'que também ativaram a localização.',
            ),

            _buildSection(
              title: 'O que você pode fazer?',

              text:
                  'Você pode negar a permissão de localização, '
                  'desativá-la posteriormente nas configurações '
                  'do seu dispositivo ou deixar de utilizar o '
                  'modo Próximos.',
            ),

            _buildSection(
              title: 'Projetos presenciais',

              text:
                  'A finalidade principal da descoberta por '
                  'proximidade é facilitar conexões entre artistas '
                  'que tenham possibilidade de trabalhar juntos '
                  'presencialmente.',
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Sua participação no modo Próximos é opcional.',

              style: TextStyle(
                color: Colors.white54,

                fontSize: 12,

                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSection({
    required String title,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 22,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 15,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            text,

            style: const TextStyle(
              color: Colors.white60,

              fontSize: 12,

              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
