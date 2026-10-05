# Versin — Backend API

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** API HTTP da `versin_api`

---

## 1. Objetivo

Este documento descreve a API HTTP própria do Versin. O backend usa FastAPI e é
separado das APIs diretas do Supabase.

---

## 2. Estrutura

Camada HTTP identificada:

```text
versin_api/routes/chat_route.py
```

Entry point:

```text
versin_api/main.py
```

---

## 3. Responsabilidades

A API própria concentra operações relacionadas a:

- Chat;
- IA;
- quota;
- autenticação server-side;
- rate limiting;
- safety;
- storage de projeto.

Ela não substitui o acesso direto do Flutter ao Supabase em outros domínios.

---

## 4. Fluxo geral

```text
Flutter / cliente
      │
      ▼
FastAPI endpoint
      │
      ▼
Validação
      │
      ▼
Autenticação / identidade
      │
      ▼
Rate limit / quota
      │
      ▼
Service
      │
      ▼
Provider / Supabase / Redis
```

---

## 5. Endpoints confirmados em execução

### Health

```text
GET /health
```

Usado para verificar disponibilidade e informações operacionais do serviço.

### Quota

```text
GET /chat/quota/{user_id}
```

Resposta observada contém campos como:

```text
used_tokens
remaining_tokens
limit_tokens
usage_percentage
progress
level
message
blocked
can_use_ai
period
provider
billing_cycle_anchor
renewal_timezone
period_start
renews_at
renews_in_seconds
renews_in_hours
renews_in_days
redis_available
global
```

---

## 6. Chat

A rota de Chat está em:

```text
versin_api/routes/chat_route.py
```

Services relacionados:

```text
ChatService
AIService
PromptEngine
QuotaService
RateLimiter
SafetyService
SupabaseAuthService
```

---

## 7. Autenticação

Existe service dedicado:

```text
versin_api/services/supabase_auth_service.py
```

A identidade deve ser derivada de credencial autenticada validada, e não apenas
de um `user_id` informado no path ou body.

---

## 8. CORS

O backend possui CORS explícito. Foi confirmado em produção que a origem:

```text
http://localhost:8080
```

recebeu:

```text
access-control-allow-origin: http://localhost:8080
access-control-allow-credentials: true
```

quando permitida.

---

## 9. Rate limiting

Implementado em:

```text
versin_api/services/rate_limiter.py
```

Características verificadas:

- Redis;
- janela padrão de 60 segundos;
- limite por usuário;
- HTTP `429`;
- header `Retry-After`.

---

## 10. Safety

Implementado em:

```text
versin_api/services/safety_service.py
```

Entrada é validada, sanitizada e limitada a 12.000 caracteres. A detecção atual
de prompt injection sinaliza o evento, mas não bloqueia automaticamente.

---

## 11. Contratos ainda não fechados

Ainda precisam ser extraídos diretamente do código:

- todos os paths;
- métodos HTTP;
- request schemas;
- response schemas;
- códigos de erro;
- autenticação obrigatória;
- autorização;
- timeouts.
