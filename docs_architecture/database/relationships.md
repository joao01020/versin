# Versin — Database Relationships

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** relações estruturais PostgreSQL

---

## 1. Objetivo

Este documento registra relações importantes entre entidades do banco Versin.

Ele não pretende substituir um ERD completo enquanto o inventário integral de
foreign keys ainda não estiver consolidado.

---

## 2. Princípio

Relações persistentes devem, quando apropriado, ser protegidas por constraints
do banco.

```text
Aplicação
    │
    ▼
regra de domínio
    │
    ▼
Foreign Key / constraint
```

Validação apenas no Flutter não garante integridade.

---

## 3. Relações confirmadas durante a auditoria

### App updates e notificações de sistema

Foi confirmada:

```text
system_notifications.update_id
        │
        ▼
app_updates.id
```

Consequência:

> `app_updates` não deve ser considerada uma tabela totalmente isolada somente
> porque estava vazia ou não apareceu na busca do Flutter.

---

### Delivery approvals e contribution deliveries

Foi confirmada:

```text
delivery_approvals.delivery_id
        │
        ▼
contribution_deliveries.id
```

Consequência:

> `delivery_approvals` participa estruturalmente do modelo de entregas mesmo que
> não possua registros no snapshot auditado.

---

## 4. Projetos

O projeto possui forte conceito de membership.

No código Flutter foram observados campos como:

```text
projects.id
projects.members
projects.founders
projects.status
projects.origin
```

Em fluxos de Match, um projeto pode ser criado com:

```text
origin = 'match'
status = 'active'
```

e IDs dos participantes em `members` e `founders`.

A auditoria ainda precisa distinguir quais relações de projeto são:

- foreign keys normalizadas;
- arrays/JSON;
- tabelas associativas.

---

## 5. Membership como autorização

Foram identificados helpers SQL:

```text
is_project_member(...)
is_recruitment_project_member(...)
can_access_project_storage(...)
```

Isso indica que a relação entre usuário e projeto não é apenas informativa: ela
participa de autorização.

Qualquer refatoração do modelo de membership precisa revisar simultaneamente:

- RLS;
- RPCs;
- storage;
- networking;
- convites;
- recrutamento.

---

## 6. Convites e recrutamento

O código Flutter utiliza RPCs como:

```text
accept_project_invitation
reject_project_invitation
approve_project_recruitment_candidate
```

Essas operações conectam usuários a recursos de projeto.

As foreign keys específicas dessas tabelas ainda precisam ser exportadas para
este documento antes de desenhar o ERD definitivo.

---

## 7. Produção criativa

A tabela:

```text
creative_activity_events
```

registra eventos associados ao usuário e, conforme o evento, pode conter:

```text
project_id
source_id
metadata
created_at
```

Foi observada unicidade lógica por:

```text
(user_id, event_type, source_id)
```

no índice:

```text
creative_activity_events_source_unique_idx
```

Isso representa uma relação lógica de idempotência entre usuário, tipo de evento
e origem.

---

## 8. `obras`

Na auditoria específica de `obras` não foram encontradas foreign keys envolvendo
a tabela.

Também não foram encontradas dependências em:

- triggers;
- views/materialized views;
- corpos pesquisados de functions `public`;
- código pesquisado do projeto.

Estado:

```text
provável legado — alta evidência
```

A ausência dessas dependências deve ser revalidada imediatamente antes de
eventual remoção.

---

## 9. Relações que ainda precisam ser consolidadas

Ainda não há evidência suficiente no material atual para documentar com precisão
todas as relações de:

- profiles;
- project invitations;
- recruitment;
- project tasks;
- project messages;
- calls;
- royalties;
- notifications;
- calendar;
- tracks;
- works/files;
- Match availability.

Essas relações devem ser extraídas diretamente do catálogo PostgreSQL, não
inferidas apenas pelos nomes das tabelas.

---

## 10. Regra para documentação

Somente marcar uma relação como confirmada quando houver pelo menos uma destas
evidências:

```text
FOREIGN KEY
constraint
policy/function explicitamente relacionada
código de domínio confirmado
```

Relações inferidas devem ser rotuladas como inferência até validação.

---

## 11. Próxima etapa

O ERD definitivo deve ser gerado após exportar:

- tabela origem;
- coluna origem;
- constraint;
- tabela destino;
- coluna destino;
- `ON UPDATE`;
- `ON DELETE`.

Depois disso, este documento pode ser convertido de uma visão parcial para o
mapa oficial de relacionamentos.
