# Versin — Arquitetura Supabase

> **Status:** Parcialmente verificado por inventário e auditoria\
> **Última revisão:** 2026-08-24\
> **Escopo:** Supabase Auth + PostgreSQL + RLS + RPC + Realtime + Edge Functions

---

## 1. Objetivo

Supabase é uma das principais camadas de infraestrutura do Versin.

Ele participa de:

```text
Supabase
├── Auth
├── PostgreSQL
├── RLS / Policies
├── RPC / PostgreSQL Functions
├── Realtime
└── Edge Functions
```

O backend FastAPI `versin_api/` é uma camada separada e não substitui o
Supabase.

---

## 2. Integração Flutter

O Flutter utiliza:

```text
supabase_flutter
```

e acessa:

```text
Supabase.instance.client
```

Padrões encontrados no código:

```text
.from(...)
.rpc(...)
.functions.invoke(...)
.channel(...)
```

Portanto, o cliente se comunica diretamente com diferentes serviços Supabase.

---

## 3. Configuração

A inicialização ocorre em:

```text
lib/main.dart
```

Configurações carregadas do ambiente:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

A `anon key` é uma credencial pública de cliente e não deve receber privilégios
equivalentes a uma chave de serviço.

Credenciais privilegiadas devem permanecer server-side.

---

## 4. Autenticação

Supabase Auth fornece a identidade principal do usuário.

A aplicação possui:

```text
SupabaseSessionManager
AuthWrapper
AuthGuard
```

A identidade autenticada também é utilizada por funções PostgreSQL através de:

```sql
auth.uid()
```

---

## 5. PostgreSQL

O banco PostgreSQL contém tabelas de múltiplos domínios do Versin, incluindo:

- perfis;
- projetos;
- networking;
- convites;
- recrutamento;
- comunicação;
- produção criativa;
- notificações;
- calendário;
- arquivos e entregas.

O inventário completo deve ser mantido em:

```text
docs_architecture/database/tables.md
```

---

## 6. RLS

Row Level Security faz parte da fronteira de autorização do banco.

A auditoria já identificou tabelas com RLS habilitado.

Regra arquitetural:

> O Flutter não deve ser considerado uma camada de autorização.

Quando uma tabela é acessível diretamente via Supabase Data API, policies
precisam representar corretamente quem pode:

```text
SELECT
INSERT
UPDATE
DELETE
```

A documentação completa ficará em:

```text
docs_architecture/database/rls.md
```

---

## 7. PostgreSQL Functions / RPC

Durante o inventário foram encontradas:

```text
47 funções no schema public
```

Dessas:

```text
34 SECURITY DEFINER
```

A auditoria também encontrou:

```text
14 SECURITY DEFINER executáveis pelo papel anon
```

Esse estado não prova vulnerabilidade por si só, mas constitui uma superfície
importante de hardening.

---

## 8. SECURITY DEFINER

Uma função `SECURITY DEFINER` executa com os privilégios do owner da função.

As funções observadas utilizam:

```text
owner = postgres
search_path = public
```

A auditoria está verificando:

- necessidade real de `SECURITY DEFINER`;
- quem possui `EXECUTE`;
- uso de `auth.uid()`;
- validação de membership/ownership;
- funções de trigger expostas desnecessariamente;
- qualificação de objetos e `search_path`.

---

## 9. SECURITY DEFINER acessíveis por anon

Entre as funções observadas nesse grupo estão:

```text
accept_project_invitation
can_access_project_storage
clear_my_available_now
handle_new_user
is_project_member
is_recruitment_project_member
leave_match_project
process_welcome_activities
reject_project_invitation
set_my_available_now
set_my_online_preference
set_welcome_activity_due_at
transfer_work
update_my_presence
```

Essa lista deve ser revalidada depois de qualquer migration de hardening.

Não significa que todas sejam vulneráveis.

---

## 10. RPCs confirmadas no Flutter

A busca por nomes literais de `.rpc()` encontrou:

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

Chamadas cujo nome é construído dinamicamente podem não aparecer nessa extração.

---

## 11. Helpers de autorização

Funções identificadas como especialmente relevantes para autorização incluem:

```text
is_project_member(...)
can_access_project_storage(...)
is_recruitment_project_member(...)
```

Helpers usados por RLS ou outras funções fazem parte da fronteira de segurança e
devem ser tratados como código sensível.

---

## 12. Triggers

O inventário confirmou triggers em `public` e `auth`.

Entre os fluxos identificados:

```text
auth.users
└── on_auth_user_created
    └── handle_new_user()
```

Também foram encontrados triggers de atualização de `updated_at` e inicialização
de dados de perfil.

Funções como:

```text
handle_new_user
set_welcome_activity_due_at
```

foram confirmadas como funções de trigger.

Isso torna o `EXECUTE` direto por `anon` um candidato a hardening, desde que a
revogação seja validada antes de aplicada.

---

## 13. Realtime

O Flutter utiliza canais Supabase Realtime.

Logs e código já confirmaram uso em áreas como:

- convites de projeto;
- notificações;
- comunicação.

A configuração detalhada de cada channel ainda será inventariada.

---

## 14. Edge Functions

Funções existentes no repositório:

```text
supabase/functions/
├── create-track-playback-url/
├── create-track-upload-url/
├── create-work-playback-url/
├── create-work-upload-url/
├── delete-profile-track/
└── delete-work-file/
```

Elas participam principalmente de fluxos de arquivo.

---

## 15. Relações verificadas durante auditoria

Foram confirmadas as seguintes foreign keys relevantes à análise de possíveis
tabelas legadas:

```text
delivery_approvals.delivery_id
        │
        └── contribution_deliveries.id
```

e:

```text
system_notifications.update_id
        │
        └── app_updates.id
```

No momento da auditoria:

```text
app_updates                            0 registros
system_notifications com update_id    0 registros
delivery_approvals                     0 registros
contribution_deliveries referenciadas 0 registros
obras                                  0 registros
```

Tabela vazia não é evidência suficiente para remoção.

---

## 16. Tabelas sob investigação de legado

### `obras`

Até o momento:

- sem uso direto encontrado no código pesquisado;
- sem trigger;
- sem referência encontrada em funções `public`;
- sem FK;
- sem view/materialized view;
- sem registros.

Classificação atual:

```text
provável legado — alta evidência
```

### `app_updates`

Não pode ser classificada como isolada porque:

```text
system_notifications.update_id
    → app_updates.id
```

### `delivery_approvals`

Não pode ser classificada como isolada porque:

```text
delivery_approvals.delivery_id
    → contribution_deliveries.id
```

---

## 17. Views

A auditoria específica procurando referências a:

```text
app_updates
delivery_approvals
obras
```

em views e materialized views retornou:

```text
0 rows
```

Esse resultado é específico a essas três tabelas e não significa que o projeto
inteiro não possua views.

---

## 18. Funções SQL e tabelas suspeitas

A busca nos corpos das funções/procedures normais do schema `public` por:

```text
app_updates
delivery_approvals
obras
```

retornou:

```text
0 rows
```

Novamente, esse resultado é específico ao escopo pesquisado.

---

## 19. Segurança por camadas

A arquitetura de autorização deve ser entendida assim:

```text
Flutter
   │
   │ JWT
   ▼
Supabase Auth
   │
   ├── Data API ──> RLS
   │
   ├── RPC ───────> auth.uid() + regras da função
   │
   ├── Realtime
   │
   └── Edge Functions ──> validação server-side
```

Nenhuma proteção visual no Flutter substitui essas regras.

---

## 20. Supabase e Versin API

Existem duas superfícies server-side distintas:

```text
Flutter
   │
   ├──────────────► Supabase
   │                 ├── Auth
   │                 ├── DB
   │                 ├── RPC
   │                 ├── Realtime
   │                 └── Edge Functions
   │
   └──────────────► Versin API
                     ├── Chat
                     ├── IA
                     ├── quota
                     ├── rate limit
                     └── safety
```

Isso deve permanecer explícito na documentação para evitar confundir Supabase
com o backend FastAPI.

---

## 21. Estrutura local Supabase

No repositório foram identificados:

```text
supabase/
├── config.toml
├── functions/
├── .gitignore
└── .temp/
```

Arquivos de `.temp/` representam estado/ferramentas locais e não documentação
arquitetural.

---

## 22. Princípios de hardening

Antes de produção madura:

1. conceder `EXECUTE` somente aos papéis necessários;
2. revisar todas as `SECURITY DEFINER`;
3. validar `auth.uid()` nas operações dependentes de usuário;
4. validar ownership/membership;
5. manter RLS nas tabelas expostas;
6. evitar service-role no cliente;
7. manter secrets server-side;
8. revisar Edge Functions;
9. testar chamadas como `anon`;
10. testar chamadas autenticadas sem autorização.

---

## 23. Documentos relacionados

Detalhes devem ficar separados em:

```text
docs_architecture/database/overview.md
docs_architecture/database/tables.md
docs_architecture/database/relationships.md
docs_architecture/database/rls.md
docs_architecture/database/rpc.md
docs_architecture/database/triggers.md
docs_architecture/database/storage.md
docs_architecture/security/authorization.md
```

---

## 24. Pendências da auditoria

Ainda precisamos fechar:

- inventário final de policies;
- permissões `GRANT/REVOKE`;
- corpo das funções sensíveis;
- dependências completas de tabelas candidatas a legado;
- Realtime por tabela/channel;
- Storage policies;
- autenticação das Edge Functions;
- migrations históricas;
- grants para `anon`, `authenticated` e `service_role`;
- testes negativos de autorização.
