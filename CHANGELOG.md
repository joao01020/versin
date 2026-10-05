# Changelog

Todas as alterações relevantes do VERSIN serão documentadas neste arquivo.

O changelog acompanha a evolução funcional e técnica do projeto, incluindo novos
recursos, mudanças de comportamento, correções e ajustes de infraestrutura.

## [Unreleased]

Alterações em desenvolvimento que ainda não fazem parte de uma versão publicada.

---

## [1.0.1] - 2026-10-05

Build: `2`

Esta versão amplia os recursos de colaboração, composição e assistência por
inteligência artificial do VERSIN, além de consolidar melhorias de estabilidade
e manutenção interna.

### Added

#### Comunicação entre artistas

- Adicionado suporte a chat entre artistas.
- Adicionada infraestrutura para chamadas de áudio.
- Adicionado suporte à comunicação em tempo real entre usuários conectados.
- Estabelecida uma base para expansão futura dos recursos colaborativos.

#### Conexões

- Adicionado acompanhamento da quantidade de conexões realizadas.
- Adicionado gráfico para visualização da evolução das conexões.
- Ampliada a visibilidade da atividade de networking dentro da plataforma.

#### Escrita e Timeline

- Adicionado acompanhamento das rimas utilizadas durante a escrita.
- Adicionada marcação de rimas utilizadas diretamente na Timeline.
- Melhorada a integração entre escrita, biblioteca de rimas e Timeline.
- Adicionado suporte visual para identificação do conteúdo já incorporado à
  composição.

#### Armazenamento

- Adicionado suporte ao armazenamento de letras associadas aos projetos.
- Adicionado suporte ao armazenamento de beats.
- Adicionada identificação de arquivos por hash.
- Criada uma base para validação de integridade dos conteúdos armazenados.
- Preparada a estrutura de armazenamento para futuras funcionalidades de
  sincronização e versionamento.

### Changed

#### Inteligência artificial

- Refinado o mecanismo de recomendação de rimas.
- Melhorada a relevância das sugestões apresentadas durante a composição.
- Ampliado o limite de tokens disponível para os recursos de inteligência
  artificial.
- Ajustado o gerenciamento de quota e consumo de tokens.
- Melhorado o comportamento da IA em sessões de composição mais longas.

#### Conexões entre artistas

- Revisado o fluxo de descoberta e conexão entre usuários.
- Melhorada a continuidade das sessões entre artistas.
- Ajustado o comportamento das interações em tempo real.
- Melhorada a estabilidade do processo de estabelecimento de conexões.

#### Studio

- Melhorada a integração entre diferentes etapas do fluxo de composição.
- Refinada a comunicação entre escrita, rimas e Timeline.
- Ajustados componentes internos relacionados ao gerenciamento do Studio.

### Fixed

- Corrigidos problemas relacionados a null-safety.
- Corrigidos avisos e erros identificados pelo Dart Analyzer.
- Corrigidos fluxos relacionados à atualização das informações de perfil.
- Corrigidos comportamentos inconsistentes na biblioteca de rimas.
- Corrigidos pontos relacionados ao gerenciamento de sessão.
- Corrigidos estados não utilizados em componentes do Studio.
- Removidos trechos de código inacessíveis ou redundantes.
- Ajustadas verificações de valores nullable no serviço WebRTC.

### Technical

#### WebRTC

- Revisado o tratamento de ICE candidates.
- Ajustadas validações de valores nullable.
- Melhorada a infraestrutura utilizada pelas chamadas de áudio.
- Removidas verificações redundantes identificadas pelo analyzer.
- Mantido o tratamento de candidates inválidos ou vazios antes do
  encaminhamento.

#### Supabase

- Melhorado o gerenciamento de sessão.
- Removido uso de eventos depreciados da API de autenticação.
- Ajustados fluxos relacionados ao estado autenticado do usuário.
- Revisada a integração entre perfil e sessão.

#### Flutter e Dart

- Substituídas APIs depreciadas por equivalentes atuais.
- Atualizado o uso de propriedades de cor para APIs compatíveis com versões
  recentes do Flutter.
- Corrigidos usos protegidos de `ChangeNotifier`.
- Ajustados construtores de widgets para propagação adequada de `Key`.
- Corrigidas estruturas condicionais apontadas pelas regras de lint.
- Removidos campos e estados não utilizados.
- Reduzido o número de warnings apresentados pelo Dart Analyzer.

#### Manutenção

- Realizada limpeza de código em diferentes módulos.
- Removidos estados sem utilização.
- Simplificadas validações redundantes.
- Melhorada a compatibilidade com regras atuais de análise estática.
- Aplicados ajustes internos sem alteração intencional do comportamento das
  funcionalidades existentes.

### Modules updated

Os principais módulos afetados nesta versão incluem:

- autenticação e gerenciamento de sessão;
- chat;
- comunicação e chamadas;
- conexões entre artistas;
- perfil;
- biblioteca de rimas;
- Studio;
- Timeline;
- mapa mental;
- armazenamento;
- recursos de inteligência artificial;
- royalties e visualização de dados.

---

## Versioning

O VERSIN utiliza versionamento no formato:

`MAJOR.MINOR.PATCH+BUILD`

Exemplo:

`1.0.1+2`

Onde:

- `MAJOR` representa alterações incompatíveis ou grandes mudanças estruturais;
- `MINOR` representa novas funcionalidades compatíveis com versões anteriores;
- `PATCH` representa correções e ajustes compatíveis;
- `BUILD` identifica internamente uma compilação específica da aplicação.

O GitHub Release utiliza a versão pública sem o número de build:

`v1.0.1`

Enquanto a aplicação mantém:

`1.0.1+2`
