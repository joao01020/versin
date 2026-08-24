# Versin — PostgreSQL Functions e RPC

> **Status:** Parcialmente verificado por auditoria\
> **Última revisão:** 2026-08-24\
> **Escopo:** functions do schema `public` e chamadas `.rpc()` do Flutter

---

## 1. Objetivo

Este documento registra a arquitetura de PostgreSQL Functions/RPC do Versin e os
principais pontos de segurança.

---

## 2. Inventário observado

Na auditoria foram encontradas:

```text
47 functions no schema public
```

Dessas:

```text
34 SECURITY DEFINER
```

No snapshot de permissões auditado:

```text
14 SECURITY DEFINER executáveis por anon
```

Esses números devem ser recontados após migrations.

---

## 3. SECURITY INVOKER

Uma função normal executa com os privilégios do chamador.

Conceitualmente:

```text
usuário
  │
  ▼
function
  │
  ▼
privilégios do usuário
```

---

## 4. SECURITY DEFINER

Uma função `SECURITY DEFINER` executa com os privilégios do owner.

```text
usuário
  │
  ▼
SECURITY DEFINER
  │
  ▼
privilégios do owner
```

Na auditoria observada, as functions `SECURITY DEFINER` estavam com:

```text
owner = postgres
search_path = public
```

Esse desenho exige revisão cuidadosa de cada função.

---

## 5. RPCs encontradas no Flutter

A extração de nomes literais encontrou:

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

Arquivos onde foram encontradas chamadas incluem módulos de:

- profile;
- Match;
- availability;
- storage;
- calls;
- recruitment;
- invitations;
- networking;
- royalties;
- dashboard/produção criativa;
- rhymes.

A lista literal não garante cobertura de chamadas dinâmicas.

---

## 6. Functions `SECURITY DEFINER` observadas com `EXECUTE` para anon

No snapshot auditado, o grupo incluía:

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

Importante:

> Estar nessa lista não significa automaticamente que a função é explorável.

Significa que ela merece revisão de necessidade, identidade, autorização e
grants.

---

## 7. Functions de trigger

Foram identificadas functions como:

```text
handle_new_user
set_welcome_activity_due_at
```

relacionadas a triggers.

Uma function destinada apenas a trigger normalmente não precisa ser uma API
pública de negócio.

Se `anon` possuir `EXECUTE` direto desnecessariamente, isso é candidato a
hardening após validação.

---

## 8. Helpers de autorização

Functions relevantes incluem:

```text
is_project_member(...)
is_recruitment_project_member(...)
can_access_project_storage(...)
```

Elas devem validar o recurso correto e não confiar em parâmetros adulteráveis
quando a identidade pode vir de `auth.uid()`.

---

## 9. `search_path`

Functions privilegiadas precisam de configuração segura de resolução de objetos.

O snapshot observado mostrou:

```text
search_path = public
```

A revisão deve verificar:

- se isso é intencional;
- se todos os objetos relevantes são resolvidos de forma segura;
- se é melhor qualificar objetos explicitamente;
- se schemas graváveis por usuários podem interferir.

---

## 10. Grants

Para cada function é necessário responder:

```text
PUBLIC pode executar?
anon pode executar?
authenticated pode executar?
service_role pode executar?
```

Princípio:

> conceder apenas o mínimo necessário.

---

## 11. Identidade

Para operações "do próprio usuário", preferir derivar identidade de:

```sql
auth.uid()
```

em vez de aceitar um `user_id` arbitrário como autoridade.

Parâmetros de recurso continuam podendo ser necessários, mas devem ser
autorizados em relação à identidade autenticada.

---

## 12. Idempotência

A produção criativa utiliza uma estratégia de origem única em:

```text
creative_activity_events
```

com índice:

```text
creative_activity_events_source_unique_idx
```

sobre:

```text
(user_id, event_type, source_id)
```

Isso é relevante para RPCs/eventos que possam ser reenviados.

---

## 13. Erro observado com `ON CONFLICT`

Durante testes manuais, foi observado:

```text
ERROR 42P10:
there is no unique or exclusion constraint matching the ON CONFLICT specification
```

Esse erro ocorre quando o alvo declarado em `ON CONFLICT` não corresponde a uma
constraint/índice único elegível na forma usada.

Também foi observado:

```text
ERROR 23505:
duplicate key value violates unique constraint
creative_activity_events_source_unique_idx
```

confirmando a existência da unicidade lógica acima.

---

## 14. Checklist por function

Para cada function:

- [ ] assinatura;
- [ ] retorno;
- [ ] owner;
- [ ] `SECURITY DEFINER` ou `INVOKER`;
- [ ] `search_path`;
- [ ] grants;
- [ ] chamada pelo Flutter?
- [ ] chamada por trigger?
- [ ] chamada por policy?
- [ ] usa `auth.uid()`?
- [ ] valida membership/ownership?
- [ ] aceita IDs controlados pelo cliente?
- [ ] possui SQL dinâmico?
- [ ] possui side effects?
- [ ] é idempotente quando necessário?

---

## 15. Regra de alteração

Não revogar ou alterar functions em massa sem mapear dependências.

Ordem recomendada:

```text
inventário
  → dependências
  → testes
  → migration pequena
  → teste anon
  → teste authenticated
  → teste do app
```

---

## 16. Pendências

Ainda precisamos registrar:

- todas as 47 assinaturas;
- retorno;
- grants completos;
- bodies das functions sensíveis;
- dependências de policies;
- dependências de triggers;
- functions não utilizadas;
- candidatas a `SECURITY INVOKER`;
- candidatas a revogação de `anon`.
