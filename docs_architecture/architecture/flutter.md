# Versin — Arquitetura Flutter

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** cliente Flutter

---

## 1. Objetivo

Este documento descreve a organização arquitetural do cliente Flutter do Versin.

---

## 2. Estrutura principal

```text
lib/
├── app/
├── controllers/
├── core/
├── features/
└── modules/
```

---

## 3. `app/`

Componentes confirmados:

```text
lib/app/
├── auth_guard.dart
├── auth_wrapper.dart
├── locator.dart
├── my_app.dart
└── routes/
```

Responsabilidades:

- composição principal;
- autenticação;
- proteção de rotas;
- roteamento;
- dependency injection.

---

## 4. `core/`

```text
lib/core/
├── auth/
├── database/
├── models/
├── network/
├── services/
├── utils/
└── widgets/
```

---

## 5. `features/`

Existe atualmente:

```text
lib/features/rhymes/
├── data/
├── domain/
└── presentation/
```

---

## 6. `modules/`

Módulos identificados:

```text
activities
brain
calendar
chat
dashboard
hub
login
market
match
networking
notifications
onboarding
profile
rhymelibrary
settings
storage
studio
vnode
wallet
```

Estruturas internas encontradas incluem:

```text
controllers/
data/
models/
repositories/
services/
views/
widgets/
```

---

## 7. Bootstrap

Ponto de entrada:

```text
lib/main.dart
```

Fluxo verificado:

```text
main()
  │
  ├── inicialização Flutter
  ├── configuração de plataforma
  ├── SQLite FFI em desktop
  ├── carregamento do .env
  ├── Supabase.initialize()
  ├── SupabaseSessionManager.initialize()
  ├── SyncManager().watchConnection()
  ├── IPC do Studio em desktop
  └── runApp(...)
```

---

## 8. Dependency Injection

O Versin utiliza GetIt.

Registro principal:

```text
lib/app/locator.dart
```

Ciclos identificados:

```text
LazySingleton
Factory
```

O `MatchController` foi identificado como caso relevante de `Factory`.

---

## 9. Navegação e autenticação

A aplicação utiliza:

```text
AuthWrapper
AuthGuard
AppRoutes
```

Fluxo principal:

```text
Recovery        → ResetPasswordPage
Authenticated   → DashboardPage
Unauthenticated → LoginPage
```

---

## 10. Comunicação com Supabase

Foram identificados usos de:

```text
Supabase.instance.client
.from(...)
.rpc(...)
.functions.invoke(...)
.channel(...)
```

---

## 11. RPCs chamadas diretamente pelo Flutter

Chamadas literais confirmadas:

```text
accept_project_invitation
approve_project_recruitment_candidate
check_username_available
clear_my_available_now
increment_word_score
leave_match_project
reject_project_invitation
set_my_available_now
set_my_online_preference
set_my_username
update_my_presence
```

Essa lista não inclui necessariamente chamadas construídas por variável.

---

## 12. Edge Functions

Funções presentes no repositório:

```text
create-track-playback-url
create-track-upload-url
create-work-playback-url
create-work-upload-url
delete-profile-track
delete-work-file
```

---

## 13. Networking

```text
lib/modules/networking/
├── call/
├── chat/
├── core/
├── invitations/
├── members/
├── recruitment/
├── royalties/
├── tasks/
├── views/
└── widgets/
```

Networking é um domínio composto.

---

## 14. Match

Subáreas identificadas:

```text
availability/
controllers/
data/
demo/
discovery/
filters/
location/
models/
profile/
search/
services/
team_expansion/
views/
widgets/
```

---

## 15. Chat

```text
ai/
conversation/
data/
domain/
models/
rhymes/
services/
views/
vocabulary/
```

O módulo se comunica com a Versin API para IA e quota.

---

## 16. Storage

```text
lib/modules/storage/
├── controllers/
├── data/
├── services/
├── views/
└── widgets/
```

Responsabilidades identificadas:

- inspeção de arquivos;
- SHA-256;
- obras;
- beats;
- Edge Functions;
- armazenamento externo.

---

## 17. Studio

```text
lib/modules/studio/
├── controllers/
├── models/
├── services/
├── views/
├── widgets/
└── windows/
```

No desktop existem janelas externas com Flutter Engines independentes.

```text
         Main Window
             │
      StudioController
             │
   ┌─────────┴─────────┐
   │                   │
   ▼                   ▼
Lyrics              Mind Map
Window               Window
   │                   │
   └────── IPC ────────┘
```

---

## 18. SQLite e sincronização

Em desktop, o bootstrap inicializa SQLite por FFI.

Também existe:

```text
SyncManager().watchConnection()
```

---

## 19. Fronteira de confiança

> O Flutter não é a fronteira final de segurança.

Não devem depender exclusivamente do cliente:

- autorização;
- ownership;
- membership;
- acesso a arquivos;
- quota;
- operações privilegiadas.

---

## 20. Estado arquitetural

O projeto possui mais de um padrão:

```text
features/rhymes
    → data/domain/presentation

modules/*
    → arquitetura modular própria
```

A documentação descreve primeiro o estado real.

---

## 21. Pendências

Ainda serão detalhados:

- repositories por módulo;
- fonte da verdade de estado;
- cache;
- sincronização offline;
- tratamento global de erros;
- contratos Flutter ↔ Backend;
- lifecycle de dependências;
- segurança de Storage.
