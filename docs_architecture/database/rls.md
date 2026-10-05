# Versin — Row Level Security (RLS)

> **Status:** Auditoria em andamento\
> **Última revisão:** 2026-08-24\
> **Escopo:** policies e autorização PostgreSQL/Supabase

---

## 1. Objetivo

Este documento descreve o papel do Row Level Security na arquitetura do Versin.

Como o Flutter acessa tabelas Supabase diretamente, RLS é uma fronteira de
segurança real.

---

## 2. Modelo de ameaça

Não assumir que todas as requisições vêm do aplicativo oficial.

Um usuário autenticado pode construir chamadas manualmente.

```text
Flutter oficial ───────┐
                       │
cliente modificado ────┼──► Supabase
                       │
script/curl ───────────┘
```

Por isso, esconder recursos na interface não constitui autorização.

---

## 3. Papéis relevantes

No contexto Supabase, os papéis mais importantes para a auditoria são:

```text
anon
authenticated
service_role
```

### `anon`

Representa chamadas sem uma sessão de usuário autenticada.

### `authenticated`

Representa usuários autenticados.

### `service_role`

É privilegiado e deve permanecer exclusivamente em ambiente server-side.

---

## 4. Identidade

Policies e functions podem utilizar:

```sql
auth.uid()
```

para obter a identidade autenticada.

Regra importante:

> IDs enviados pelo cliente não devem substituir `auth.uid()` quando a operação
> pertence ao próprio usuário.

---

## 5. RLS versus GRANT

RLS e permissões SQL são mecanismos diferentes.

```text
GRANT
  │
  └── pode executar a operação na relação?

RLS
  │
  └── quais linhas essa sessão pode acessar/modificar?
```

Uma auditoria completa precisa revisar ambos.

---

## 6. Helpers de autorização

Foram identificados helpers como:

```text
is_project_member(...)
is_recruitment_project_member(...)
can_access_project_storage(...)
```

Essas funções podem participar de policies e/ou RPCs.

Elas devem ser tratadas como componentes de segurança e receber testes
negativos.

---

## 7. Membership

Uma regra recorrente no Versin é membership de projeto.

Conceitualmente:

```text
auth.uid()
    │
    ▼
é membro do projeto?
    │
    ├── sim → operação potencialmente permitida
    └── não → negar
```

A condição exata depende do recurso.

---

## 8. RLS e SECURITY DEFINER

`SECURITY DEFINER` exige atenção especial porque uma função pode executar com
privilégios do owner.

Não se deve presumir que RLS, isoladamente, torna qualquer RPC privilegiada
segura.

Cada função deve verificar:

- quem pode executar;
- identidade;
- ownership/membership;
- parâmetros;
- efeito da função.

---

## 9. Estado observado da auditoria

A auditoria anterior identificou RLS habilitado em tabelas do projeto e comparou
estados/policies.

Também foram observados resultados `true`/`false` durante a inspeção de
segurança.

Entretanto, o material disponível nesta etapa não contém o inventário textual
completo de todas as policies e suas expressões.

Portanto, este documento não inventa nomes ou condições que ainda não foram
exportados.

---

## 10. Policies por operação

Para cada tabela exposta, a documentação final deve registrar separadamente:

```text
SELECT
INSERT
UPDATE
DELETE
```

Para cada policy:

```text
nome
role
command
USING
WITH CHECK
```

---

## 11. Testes negativos

Uma policy não deve ser considerada validada apenas porque o usuário correto
consegue executar a ação.

Também devem ser testados:

```text
anon
usuário A acessando recurso de B
membro versus não membro
ex-membro
projeto inexistente
resource id adulterado
payload com user_id de terceiro
```

---

## 12. Service role

A chave `service_role`:

- não deve existir no Flutter;
- não deve ser incluída em assets;
- não deve ser commitada;
- não deve ser exposta em logs;
- deve ser usada apenas em ambiente server-side quando necessária.

---

## 13. Realtime

Quando uma tabela participa do Realtime, não se deve assumir que Realtime
elimina a necessidade de autorização.

A configuração de subscriptions deve ser revisada junto com RLS e publication.

---

## 14. Checklist de auditoria por tabela

Para cada tabela:

- [ ] RLS está habilitado?
- [ ] `anon` possui acesso necessário e somente necessário?
- [ ] `authenticated` possui somente acesso necessário?
- [ ] SELECT valida ownership/membership?
- [ ] INSERT possui `WITH CHECK` adequado?
- [ ] UPDATE protege linha e novos valores?
- [ ] DELETE exige autorização?
- [ ] helpers chamados são seguros?
- [ ] existe RPC que contorna a policy?
- [ ] existe Edge Function privilegiada acessando a tabela?

---

## 15. Pendências

Precisamos exportar e registrar:

- todas as tabelas com `relrowsecurity`;
- todas as policies;
- `roles`;
- `cmd`;
- `qual`;
- `with_check`;
- grants de tabela;
- testes reais como `anon` e `authenticated`.

Até essa etapa, o documento permanece propositalmente parcial.
