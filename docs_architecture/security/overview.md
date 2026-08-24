# Versin — Security Overview

> **Status:** Baseline de segurança em construção\
> **Última revisão:** 2026-08-24\
> **Escopo:** Flutter, Supabase, PostgreSQL, Storage, Edge Functions e
> `versin_api`

---

## 1. Objetivo

Este diretório documenta o modelo de segurança do Versin.

A regra central é simples:

```text
o cliente Flutter não é uma fronteira de confiança
```

Qualquer informação enviada pelo cliente pode ser manipulada.

Por isso, controles que protegem dados, identidade, arquivos, quota, projetos e
operações sensíveis precisam existir no lado confiável.

---

## 2. Arquitetura de confiança

```text
┌──────────────────────────────┐
│ Flutter                      │
│ ambiente não confiável       │
└──────────────┬───────────────┘
               │ JWT / requests
               ▼
┌──────────────────────────────┐
│ Supabase / Versin API        │
│ fronteira de autorização     │
├──────────────────────────────┤
│ Auth                         │
│ RLS                          │
│ RPC                          │
│ Edge Functions               │
│ Storage policies             │
│ backend FastAPI              │
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐
│ PostgreSQL / Storage         │
│ dados persistentes           │
└──────────────────────────────┘
```

---

## 3. Princípios

O Versin deve seguir:

```text
deny by default
least privilege
defense in depth
server-side authorization
identity from authenticated session
short-lived access when possible
idempotency for retried operations
minimal secret exposure
minimal sensitive logging
```

---

## 4. Identidade

A identidade confiável deve vir da autenticação.

No ecossistema Supabase:

```sql
auth.uid()
```

é a referência natural para operações PostgreSQL relacionadas ao usuário
autenticado.

No backend próprio, a identidade deve ser obtida após validar o JWT.

Nunca considerar apenas:

```text
user_id enviado pelo Flutter
```

como prova de identidade.

---

## 5. Autenticação versus autorização

São problemas diferentes.

```text
Autenticação
    ↓
Quem é você?

Autorização
    ↓
O que você pode fazer?
```

Um JWT válido não significa que o usuário pode acessar qualquer projeto, arquivo
ou perfil.

---

## 6. Banco

O Flutter utiliza Supabase diretamente em vários módulos.

Consequentemente, RLS é uma parte crítica da segurança.

A regra esperada é:

```text
tabela acessível pelo cliente
        │
        ▼
RLS habilitado
        │
        ▼
policies mínimas e explícitas
```

A auditoria integral de policies ainda está em andamento.

---

## 7. RPC

O Flutter utiliza várias RPCs.

Entre as chamadas confirmadas:

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

RPC não é automaticamente segura apenas por estar no servidor.

Cada função precisa ser auditada quanto a:

- identidade;
- autorização;
- `SECURITY DEFINER`;
- `search_path`;
- owner;
- grants;
- validação de argumentos.

---

## 8. SECURITY DEFINER

A auditoria encontrou:

```text
34 funções public SECURITY DEFINER
```

Esse número torna a revisão dessas funções uma prioridade.

`SECURITY DEFINER` executa com privilégios do owner da função e, portanto,
amplia o impacto de qualquer falha de autorização.

---

## 9. Grants de funções

A auditoria também verificou executabilidade por roles como:

```text
anon
authenticated
```

Ter `EXECUTE` em uma função não significa necessariamente vulnerabilidade, mas
exige que a própria função seja segura para aquela role.

A matriz completa deve permanecer registrada em `database/rpc.md`.

---

## 10. Storage

Arquivos precisam de controles independentes de banco.

```text
RLS de tabela
    !=
Storage policy
```

Hash também não substitui autorização.

```text
SHA-256
    → integridade/identificação

não
    → confidencialidade
    → controle de acesso
```

---

## 11. Edge Functions

Foram identificadas funções relacionadas a arquivos:

```text
create-track-upload-url
create-track-playback-url
create-work-upload-url
create-work-playback-url
delete-profile-track
delete-work-file
```

Essas funções ficam em uma fronteira sensível porque podem emitir acesso a
objetos ou removê-los.

---

## 12. Backend próprio

O Versin possui:

```text
versin_api/
```

com componentes de segurança como:

```text
core/security.py
services/supabase_auth_service.py
services/rate_limiter.py
services/quota_service.py
services/safety_service.py
```

---

## 13. IA

O backend da IA possui controles independentes:

```text
autenticação
quota
rate limit
safety
```

A UI pode apresentar quota, mas não deve autorizar consumo.

---

## 14. Redis e rate limiting

Foi identificado rate limiting com Redis.

A implementação auditada possui comportamento `fail-open` em indisponibilidade
do Redis.

Isso é uma decisão de disponibilidade versus proteção e deve ser monitorada.

---

## 15. Realtime

Realtime não ignora o modelo de autorização.

Subscriptions precisam respeitar a visibilidade permitida ao usuário.

Também devem ser encerradas corretamente para evitar:

```text
listeners duplicados
vazamento de estado
processamento repetido
```

---

## 16. Logging

Logs não devem conter:

```text
JWT completo
refresh token
service_role
API keys
signed URLs completas
senhas
conteúdo privado desnecessário
```

IDs técnicos podem ser úteis, mas também devem ser registrados somente quando
necessários.

---

## 17. Segurança por domínio

### Profile

Proteger edição de identidade e campos privados.

### Match

Impedir ações em nome de outro usuário.

### Networking

Validar membership e permissões de projeto.

### Storage

Validar ownership/membership antes de emitir acesso.

### Chat & AI

Validar JWT, quota e frequência.

### Notifications

Impedir leitura de notificações de terceiros.

### Creative Production

Impedir falsificação de atividade para outro usuário.

---

## 18. Segurança não deve depender da UI

Esconder um botão não protege uma operação.

```text
botão oculto
    !=
autorização
```

Um atacante pode chamar diretamente APIs, RPCs e endpoints expostos.

---

## 19. Prioridades atuais

A ordem recomendada para hardening é:

```text
1. secrets
2. autenticação
3. RLS
4. SECURITY DEFINER / grants
5. Storage
6. autorização de projetos
7. Edge Functions
8. backend API
9. rate limiting / abuso
10. testes negativos
```

---

## 20. Critério de segurança

Uma feature não deve ser considerada segura apenas porque funciona no caminho
feliz.

Também precisa responder corretamente a:

```text
usuário errado
role errada
recurso inexistente
ID manipulado
requisição repetida
sessão expirada
concorrência
input inválido
acesso anônimo
```

---

## 21. Documentos deste diretório

```text
overview.md
threat-model.md
authentication.md
authorization.md
file-security.md
secrets.md
```

---

## 22. Pendências gerais

Ainda precisamos concluir:

- inventário integral de policies;
- grants completos;
- auditoria das 34 `SECURITY DEFINER`;
- Storage policies;
- secrets por ambiente;
- CORS;
- headers;
- expiração/revogação de sessões;
- testes negativos automatizados;
- análise de dependências;
- estratégia de incident response;
- backup/recovery.
