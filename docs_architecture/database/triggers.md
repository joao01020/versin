# Versin — Database Triggers

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** triggers PostgreSQL/Supabase

---

## 1. Objetivo

Este documento registra automações executadas por triggers no banco Versin e os
cuidados de segurança associados.

---

## 2. Por que triggers importam

Triggers são dependências invisíveis para uma busca simples no Flutter.

Uma tabela aparentemente sem uso pode ainda participar de:

```text
INSERT
  │
  ▼
TRIGGER
  │
  ▼
FUNCTION
  │
  ▼
efeito em outra tabela
```

Por isso, triggers fazem parte da auditoria antes de remover estruturas.

---

## 3. Criação de usuário

Foi confirmado o fluxo:

```text
auth.users
    │
    ▼
on_auth_user_created
    │
    ▼
handle_new_user()
```

Esse trigger participa da inicialização de dados após criação de usuário no
Supabase Auth.

---

## 4. `handle_new_user`

A function:

```text
handle_new_user
```

foi identificada como:

```text
SECURITY DEFINER
```

e apareceu no snapshot de functions com `EXECUTE` disponível para `anon`.

Como sua finalidade está relacionada a trigger, a necessidade de execução direta
por `anon` deve ser revisada.

Não revogar sem testar o fluxo real de signup.

---

## 5. Welcome activity

Também foi identificada a function:

```text
set_welcome_activity_due_at
```

relacionada a trigger/automação de atividade inicial.

Ela também apareceu entre as `SECURITY DEFINER` expostas a `anon` no snapshot
auditado.

A mesma regra se aplica:

> função usada internamente por trigger não deve permanecer publicamente
> executável sem necessidade comprovada.

---

## 6. `updated_at`

A auditoria encontrou triggers relacionados à atualização automática de
timestamps `updated_at`.

Esse padrão é usado para manter timestamps consistentes no banco sem depender
exclusivamente do cliente.

A lista completa de tabelas que utilizam esse mecanismo ainda precisa ser
exportada.

---

## 7. Auditoria de tabelas candidatas a legado

Foi executada uma busca de triggers nas tabelas:

```text
app_updates
delivery_approvals
obras
```

A consulta específica retornou vazia.

Portanto, no snapshot auditado:

```text
nenhuma dessas três tabelas possuía trigger não-interno
```

Isso é apenas uma das verificações necessárias para avaliar legado.

---

## 8. Trigger functions e grants

É importante separar:

```text
trigger chama function internamente
```

de:

```text
cliente chama function por RPC
```

Uma trigger function pode precisar existir e ser privilegiada sem precisar ser
exposta como RPC a `anon`.

---

## 9. SECURITY DEFINER

Quando uma trigger function é `SECURITY DEFINER`, revisar:

- owner;
- `search_path`;
- tabelas modificadas;
- valores de `NEW`/`OLD`;
- possibilidade de execução direta;
- grants;
- comportamento em cascata;
- recursão.

---

## 10. Ordem de execução

Quando houver múltiplos triggers na mesma operação, a ordem e efeitos precisam
ser conhecidos.

Isso é especialmente importante em:

- criação de perfil;
- notificações;
- timestamps;
- atividades iniciais;
- produção criativa.

O inventário completo ainda não foi consolidado.

---

## 11. Remoção de tabela

Antes de remover uma tabela:

```text
1. procurar triggers na própria tabela
2. procurar trigger functions que referenciem a tabela
3. procurar triggers em outras tabelas que escrevam nela
4. procurar functions normais
5. procurar FKs
6. procurar views
7. procurar policies
8. procurar código externo
```

A consulta apenas por `pg_trigger.tgrelid` encontra triggers definidos sobre a
tabela, mas não necessariamente functions de triggers de outras tabelas que
escrevam nela.

---

## 12. Testes

Triggers importantes devem ter testes para:

```text
evento esperado
efeito esperado
duplicidade
rollback em erro
dados incompletos
execução por signup
concorrência quando relevante
```

---

## 13. Pendências

Ainda precisamos gerar um inventário completo contendo:

```text
schema
table
trigger
timing
event
function
security mode da function
owner
enabled state
```

Depois disso, este documento poderá listar cada trigger ativo por domínio.
