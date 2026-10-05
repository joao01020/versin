# Versin — Módulo Dashboard

> **Status:** Parcialmente verificado no código e em execução\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/dashboard/`

---

## 1. Objetivo

O Dashboard é a principal superfície de agregação do Versin.

Ele reúne informações provenientes de vários domínios sem necessariamente ser
proprietário desses dados.

```text
Dashboard
├── conta/perfil
├── navegação
├── projetos
├── convites
├── IA/quota
├── produção criativa
├── atividades
└── widgets de resumo
```

---

## 2. Estrutura identificada

```text
lib/modules/dashboard/
├── account/
├── ai/
├── config/
├── controllers/
├── data/
├── global_call/
├── global_chat/
├── invitations/
├── layouts/
├── navigation/
├── production/
├── projects/
├── repositories/
├── services/
├── sheets/
├── views/
└── widgets/
```

A estrutura indica que o Dashboard funciona como uma camada de composição de
diversas features.

---

## 3. Responsabilidade arquitetural

O Dashboard deve:

- consultar controllers/services;
- compor dados;
- apresentar estado;
- oferecer navegação;
- reagir a atualizações.

Ele não deve concentrar regras de domínio que pertencem a:

- Match;
- Networking;
- Chat;
- Profile;
- Notifications;
- Storage.

---

## 4. Produção criativa

Existe um subdomínio específico:

```text
lib/modules/dashboard/production/
```

Arquivos identificados incluem:

```text
services/creative_activity_service.dart
services/creative_production_service.dart
models/creative_production_month.dart
```

Esse domínio transforma eventos de atividade em métricas mensais.

---

## 5. Creative Activity

O serviço:

```text
CreativeActivityService
```

registra e consulta eventos de produção.

Um evento confirmado é:

```text
composition_session
```

registrado pelo Studio.

Também existem métricas para:

```text
projects_created
composition_sessions
tasks_completed
collaborations_started
files_added
```

---

## 6. Eventos e idempotência

A tabela:

```text
creative_activity_events
```

possui unicidade observada por:

```text
(user_id, event_type, source_id)
```

através de:

```text
creative_activity_events_source_unique_idx
```

Isso permite que uma origem lógica seja identificada de forma única.

---

## 7. Studio → Dashboard

O Studio possui integração com:

```text
CreativeActivityService
```

Quando uma sessão de composição é registrada, o evento pode alimentar a produção
criativa.

Fluxo:

```text
Studio
  │
  ▼
composition_session
  │
  ▼
creative_activity_events
  │
  ▼
agregação mensal
  │
  ▼
Dashboard
```

---

## 8. Agregação mensal

Foi confirmado em execução um RPC retornando 12 meses.

Exemplo de campos:

```text
month_start
projects_created
composition_sessions
tasks_completed
collaborations_started
files_added
```

O Flutter transforma esses dados em:

```text
CreativeProductionMonth
```

---

## 9. Score

O serviço:

```text
CreativeProductionService
```

calcula score a partir das métricas.

Foi observado no código um peso de sessão de composição:

```text
compositionSessionWeight = 3.0
```

Os demais pesos devem ser documentados diretamente do arquivo antes de serem
tratados como contrato.

---

## 10. Gráfico de produção

O widget identificado é:

```text
lib/modules/dashboard/widgets/versin_statistics_card_widget.dart
```

Ele apresenta:

- barras mensais;
- mês atual;
- seleção de mês;
- comparação com mês anterior;
- detalhes de produção;
- tooltip/overlay;
- estado de loading.

---

## 11. Interação do gráfico

O gráfico permite selecionar um mês.

O resumo utiliza informações como:

```text
score
changeFromPreviousMonth
projectsCreated
compositionSessions
tasksCompleted
collaborationsStarted
filesAdded
```

A UI foi evoluída para apresentar os detalhes de maneira progressiva em vez de
expor tudo simultaneamente.

---

## 12. Loading

O Dashboard possui estado de carregamento para a produção criativa.

A intenção visual atual é manter o loading alinhado à identidade do Versin em
vez de utilizar apenas um indicador genérico.

Isso é uma decisão de apresentação, não uma regra de domínio.

---

## 13. Quota de IA

O Dashboard também consulta a quota real da IA Versin.

Logs confirmaram fluxo:

```text
Dashboard
  │
  ▼
Chat Repository
  │
  ▼
Chat Remote
  │
  ▼
Versin API
```

e retorno de:

```text
used
remaining
limit
```

---

## 14. Perfil

O Dashboard carrega dados de perfil, incluindo nome público e informações
profissionais.

Logs confirmaram carregamento de:

```text
função principal
funções
o que procura
nome público
```

A fonte de verdade pertence ao domínio Profile; o Dashboard apenas consome.

---

## 15. Projetos de Match

O Dashboard verifica a existência de projeto de Match ativo.

Essa informação pertence ao domínio Match/Projects e deve permanecer desacoplada
da lógica visual do Dashboard.

---

## 16. Convites

Existe:

```text
lib/modules/dashboard/invitations/
```

e integração com o controller de convites de projeto.

Foi observado:

```text
snapshot inicial
Realtime
contador de pendentes
```

---

## 17. Notificações e atividade recente

O Dashboard consome dados de:

```text
Recent Activity
Notifications
```

Logs confirmaram carregamento inicial e atualizações Realtime de notificações.

---

## 18. Navegação

Existe uma camada:

```text
lib/modules/dashboard/navigation/
```

O Dashboard deve centralizar composição de navegação sem transformar widgets
individuais em responsáveis por roteamento global.

---

## 19. Logout

A interface do Dashboard possui área de ícones/ações da conta e foi planejada
para incluir ação explícita de sair da conta.

A execução do logout deve continuar delegada ao sistema de autenticação/sessão,
não implementada como simples troca visual de página.

---

## 20. Dependências

```text
Dashboard
├── Profile
├── Match
├── Networking
├── Notifications
├── Chat/AI
├── Projects
├── Creative Production
└── Supabase Realtime
```

Isso torna o Dashboard um módulo de alta integração.

---

## 21. Regra de manutenção

Evitar:

```text
DashboardController
    └── toda regra do aplicativo
```

Preferir:

```text
domínio
  └── controller/service próprio
        │
        ▼
Dashboard consome estado
```

---

## 22. Pendências

Ainda precisamos documentar:

- controller principal completo;
- todos os repositories;
- todas as fontes de atividade recente;
- fluxo completo de global chat/call;
- regras de refresh;
- lifecycle de subscriptions;
- tratamento de erro;
- estados vazios;
- cache.
