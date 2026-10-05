# Versin — Database Tables

> **Status:** Inventário parcial\
> **Última revisão:** 2026-08-24\
> **Escopo:** tabelas PostgreSQL utilizadas pelo Versin

---

## 1. Objetivo

Este documento registra as tabelas conhecidas e o papel arquitetural confirmado
de algumas delas.

Ele não inventa um catálogo completo de colunas sem exportação direta do banco.

---

## 2. Regra de documentação

Para cada tabela, a versão final deverá registrar:

```text
nome
domínio
propósito
PK
FKs
constraints
RLS
policies
triggers
Realtime
principais consumidores
estado: ativa / legado / em investigação
```

---

## 3. `projects`

Tabela utilizada pelo domínio de projetos.

Campos observados no código Flutter:

```text
id
title
members
founders
status
origin
created_at
updated_at
```

No fluxo Match, projetos são consultados/criados com:

```text
origin = 'match'
status = 'active'
```

e participantes são registrados em:

```text
members
founders
```

A estrutura completa da tabela ainda deve ser exportada.

---

## 4. `creative_activity_events`

Tabela utilizada para registrar eventos de produção criativa.

Campos observados em consultas:

```text
event_type
project_id
source_id
metadata
created_at
```

Também participa o usuário do evento (`user_id`), confirmado pela constraint
única observada.

Tipo de evento confirmado:

```text
composition_session
```

Outros tipos presentes no domínio incluem eventos associados às métricas de:

```text
project_created
task_completed
collaboration_started
file_added
```

A nomenclatura final de cada enum/event type deve continuar alinhada ao
código/SQL real.

### Unicidade

Foi confirmado o índice:

```text
creative_activity_events_source_unique_idx
```

com chave lógica:

```text
(user_id, event_type, source_id)
```

Ele evita duplicar a mesma origem de evento para o mesmo usuário/tipo.

---

## 5. `app_updates`

Tabela investigada durante auditoria de legado.

Snapshot observado:

```text
0 registros
```

Entretanto existe relação:

```text
system_notifications.update_id
    → app_updates.id
```

Classificação:

```text
não isolada
```

Não remover apenas com base em ausência de uso direto no Flutter.

---

## 6. `system_notifications`

Tabela relacionada a notificações de sistema.

Relação confirmada:

```text
system_notifications.update_id
    → app_updates.id
```

No snapshot auditado não havia registros de `system_notifications` referenciando
`update_id`, mas a FK existe estruturalmente.

---

## 7. `delivery_approvals`

Tabela investigada como possível legado.

Snapshot observado:

```text
0 registros
```

Possui FK:

```text
delivery_approvals.delivery_id
    → contribution_deliveries.id
```

Classificação:

```text
estruturalmente relacionada ao domínio de entregas
```

---

## 8. `contribution_deliveries`

Tabela destino da FK de approvals:

```text
delivery_approvals.delivery_id
    → contribution_deliveries.id
```

O modelo completo do domínio ainda precisa ser documentado.

---

## 9. `obras`

Tabela investigada extensivamente.

Resultados observados:

```text
registros                         0
uso direto pesquisado no código  não encontrado
triggers                          não encontrados
referência em functions public   não encontrada
foreign keys                      não encontradas
views/materialized views          não encontradas
```

Classificação atual:

```text
provável legado — alta evidência
```

Antes de remover:

- backup;
- migration;
- nova busca;
- verificação de produção;
- rollback.

---

## 10. `project_messages`

O domínio de mensagens de projeto utiliza essa tabela.

Em auditoria anterior do aplicativo foi observado constraint relacionada ao
conteúdo da mensagem:

```text
project_messages_content_not_empty
```

e uma regra de payload em que mensagens de texto/system precisam de conteúdo e
mensagens de áudio precisam do caminho de áudio correspondente.

A definição SQL completa deve ser exportada antes de documentar a expressão
exata da constraint.

---

## 11. Domínios com tabelas ainda a inventariar

Pelo código e arquitetura, existem tabelas relacionadas a:

```text
profiles
project invitations
recruitment
project members
project tasks
project chat/messages
calls
communication permissions
royalties
notifications
calendar
presence
availability
tracks
works/files
rhymes
```

Os nomes exatos e schemas completos não devem ser inferidos apenas desses
domínios.

---

## 12. Tabelas e código

A ausência de uma string `.from('tabela')` no Flutter não prova que a tabela é
legado.

Uma tabela pode ser usada por:

```text
foreign key
trigger
policy
function
view
Edge Function
backend
Realtime
```

Por isso, a auditoria de legado precisa combinar catálogo PostgreSQL e busca de
código.

---

## 13. Próxima etapa do inventário

Para tornar este arquivo definitivo, exportar do PostgreSQL:

```text
schema
table
column
data_type
nullable
default
primary key
unique constraints
foreign keys
RLS
```

Depois organizar as tabelas por domínio, evitando um documento gigante de SQL
bruto.
