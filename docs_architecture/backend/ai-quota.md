# Versin — AI Quota

> **Status:** Verificado em nível funcional e parcialmente verificado no código\
> **Última revisão:** 2026-08-24\
> **Escopo:** quota e rate limiting da IA Versin

---

## 1. Objetivo

O sistema de quota é aplicado no backend e não depende exclusivamente do
Flutter.

Componentes:

```text
QuotaService
RateLimiter
Redis
```

---

## 2. Quota Service

Arquivo:

```text
versin_api/services/quota_service.py
```

O serviço mantém:

```text
quota mensal por usuário
quota global diária
```

---

## 3. Status individual

Campos verificados:

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
```

Metadata do ciclo:

```text
period
provider
billing_cycle_anchor
renewal_timezone
period_start
renews_at
renews_in_seconds
renews_in_hours
renews_in_days
```

---

## 4. Renovação

O código indica que o frontend deve utilizar:

```text
renews_at
```

como fonte da verdade da renovação.

---

## 5. Quota global

A quota global usa período diário e timezone UTC.

Campos:

```text
used_tokens
remaining_tokens
limit_tokens
usage_percentage
progress
blocked
period
reset_timezone
resets_at
resets_in_seconds
```

---

## 6. Regra de uso

Conceitualmente:

```text
can_use_ai =
    not user_blocked
    and not global_blocked
```

---

## 7. Redis

Redis participa da quota e o status expõe:

```text
redis_available
```

---

## 8. Endpoint confirmado

```text
GET /chat/quota/{user_id}
```

Foi validado retorno `HTTP 200` em produção.

---

## 9. Rate limiter

Arquivo:

```text
versin_api/services/rate_limiter.py
```

Quota e rate limit são diferentes:

```text
Quota      → quanto pode consumir
Rate limit → quantas requisições pode fazer por janela
```

Chave Redis confirmada:

```text
rate_limit:ai:<user_id>
```

Janela padrão:

```text
60 segundos
```

Configuração:

```text
AI_RATE_LIMIT_PER_MINUTE
```

---

## 10. Limite excedido

Quando excedido:

```text
HTTP 429
Retry-After
```

Resposta inclui:

```text
limit
window_seconds
retry_after
```

---

## 11. Fail-open

Se Redis falhar no rate limiter, o comportamento atual é:

```text
fail-open
```

A IA não é derrubada apenas pela indisponibilidade do limiter.

---

## 12. Responsabilidade do Flutter

O Flutter pode mostrar quota, progresso e renovação, mas o backend continua
sendo a fonte de verdade.

---

## 13. Pendências

Ainda precisam ser auditados:

- atomicidade da contagem de tokens;
- concorrência;
- expiração das chaves;
- comportamento multi-instância;
- consumo em falha do provider;
- rollback de tokens;
- vínculo entre JWT autenticado e `user_id` consultado.
