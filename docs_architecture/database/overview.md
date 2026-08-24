# Versin — Database Overview

> **Status:** Parcialmente verificado por auditoria do banco e do código\
> **Última revisão:** 2026-08-24\
> **Escopo:** PostgreSQL/Supabase — schema `public`

---

## 1. Objetivo

Este documento apresenta a visão arquitetural do banco de dados do Versin.

O banco principal utiliza PostgreSQL através do Supabase e atende vários
domínios da aplicação:

- identidade e perfil;
- projetos;
- Match;
- Networking;
- convites e recrutamento;
- comunicação;
- tarefas e colaboração;
- arquivos e entregas;
- produção criativa;
- notificações;
- calendário;
- presença e disponibilidade.

Detalhes específicos são separados em:

```text
database/
├── overview.md
├── tables.md
├── relationships.md
├── rls.md
├── rpc.md
├── triggers.md
└── storage.md
```

---

## 2. Posição do banco na arquitetura

```text
Flutter
   │
   ├──────────────► Supabase Auth
   │
   ├──────────────► PostgreSQL / Data API
   │                    │
   │                    ├── RLS
   │                    ├── Policies
   │                    ├── Functions / RPC
   │                    └── Triggers
   │
   ├──────────────► Supabase Realtime
   │
   └──────────────► Edge Functions

Versin API
   │
   └──────────────► Supabase / serviços server-side
```

O Flutter acessa parte do banco diretamente. Por isso, autorização no banco é
uma parte essencial da segurança.

---

## 3. Fonte da verdade

Para dados persistentes de domínio armazenados no Supabase, o PostgreSQL deve
ser tratado como fonte da verdade.

Estado local no Flutter pode servir para:

- cache;
- experiência offline;
- estado temporário de UI.

Ele não deve substituir validações server-side de:

- ownership;
- membership;
- autorização;
- integridade referencial;
- operações privilegiadas.

---

## 4. Mecanismos utilizados

A auditoria confirmou uso de:

```text
PostgreSQL tables
Foreign Keys
RLS
Policies
PostgreSQL Functions
RPC
SECURITY DEFINER
Triggers
Supabase Realtime
```

Também existem Edge Functions que participam de fluxos de arquivo.

---

## 5. Functions do schema `public`

No inventário realizado durante a auditoria foram encontradas:

```text
47 funções no schema public
34 funções SECURITY DEFINER
```

Também foi identificado, naquele snapshot de permissões:

```text
14 SECURITY DEFINER executáveis pelo papel anon
```

Esses números representam o estado observado durante a auditoria e devem ser
atualizados após migrations.

---

## 6. RPCs usadas pelo Flutter

A busca por chamadas literais `.rpc()` encontrou:

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

A lista pode não incluir chamadas cujo nome seja construído dinamicamente.

---

## 7. Helpers de autorização

Foram identificadas funções importantes para regras de acesso, incluindo:

```text
is_project_member(...)
can_access_project_storage(...)
is_recruitment_project_member(...)
```

Helpers utilizados por policies ou funções privilegiadas devem ser considerados
parte da fronteira de segurança.

---

## 8. Integridade referencial

O banco utiliza foreign keys para representar relações entre recursos.

Durante a auditoria de possíveis tabelas legadas foram confirmadas, entre
outras, as relações:

```text
system_notifications.update_id
    → app_updates.id

delivery_approvals.delivery_id
    → contribution_deliveries.id
```

Uma tabela vazia não deve ser removida apenas por estar sem registros quando
ainda possui dependências estruturais.

---

## 9. Tabelas sob investigação de legado

Três tabelas receberam atenção específica:

```text
app_updates
delivery_approvals
obras
```

### `app_updates`

Possui dependência:

```text
system_notifications.update_id
    → app_updates.id
```

Logo, não foi classificada como isolada.

### `delivery_approvals`

Possui dependência:

```text
delivery_approvals.delivery_id
    → contribution_deliveries.id
```

Logo, não foi classificada como isolada.

### `obras`

Até o ponto auditado:

- 0 registros;
- nenhum uso direto encontrado no código pesquisado;
- nenhum trigger encontrado;
- nenhuma referência encontrada nos corpos pesquisados de funções `public`;
- nenhuma foreign key encontrada;
- nenhuma view/materialized view encontrada.

Classificação atual:

```text
provável legado — alta evidência
```

Isso ainda não equivale a autorização automática para remoção.

---

## 10. Produção criativa

O banco contém:

```text
creative_activity_events
```

Esse domínio alimenta as métricas de produção criativa.

Um tipo de evento confirmado é:

```text
composition_session
```

Também foi observada uma restrição única relacionada a:

```text
(user_id, event_type, source_id)
```

através do índice:

```text
creative_activity_events_source_unique_idx
```

Essa unicidade ajuda a impedir duplicação do mesmo evento lógico quando o mesmo
`source_id` é reutilizado.

---

## 11. RLS e autorização

Como o Flutter acessa Supabase diretamente, o banco deve assumir que um cliente
pode ser modificado.

```text
Flutter oficial ──────┐
                      ├──► Supabase Data API
cliente alterado ─────┘
```

A segurança não pode depender de botões escondidos ou validações apenas no Dart.

---

## 12. SECURITY DEFINER

A auditoria encontrou uso significativo de `SECURITY DEFINER`.

Esse recurso é legítimo, mas aumenta a necessidade de revisar:

- owner;
- `search_path`;
- permissões `EXECUTE`;
- uso de `auth.uid()`;
- ownership/membership;
- parâmetros controlados pelo cliente;
- exposição desnecessária a `anon`.

---

## 13. Triggers

Existem triggers responsáveis por automações de banco.

Um fluxo confirmado é:

```text
auth.users
   │
   └── on_auth_user_created
          │
          └── handle_new_user()
```

Também foram identificados triggers relacionados a atualização de timestamps e
inicialização de dados.

---

## 14. Realtime

A aplicação utiliza Supabase Realtime em diferentes domínios.

Logs e código já confirmaram uso em áreas como:

- convites de projeto;
- notificações;
- comunicação.

O inventário exato de tabelas/publications/channels ainda precisa ser fechado.

---

## 15. Princípios para evolução

Alterações estruturais devem preferencialmente ser feitas por migrations
reproduzíveis.

Antes de remover uma tabela, coluna, policy, trigger ou função:

1. procurar uso no Flutter;
2. procurar uso no backend;
3. procurar uso em Edge Functions;
4. verificar foreign keys;
5. verificar triggers;
6. verificar views;
7. verificar functions/procedures;
8. verificar policies;
9. verificar dados existentes;
10. preparar rollback/backup quando necessário.

---

## 16. Pendências

Ainda precisam ser consolidados:

- inventário completo das tabelas e colunas;
- todas as foreign keys;
- todas as policies;
- grants por role;
- bodies das functions sensíveis;
- todos os triggers;
- publications do Realtime;
- migrations históricas;
- Storage policies.
