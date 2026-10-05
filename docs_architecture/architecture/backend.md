# Versin — Arquitetura do Backend

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** `versin_api/`

---

## 1. Objetivo

Este documento descreve a arquitetura do backend próprio do Versin.

---

## 2. Tecnologia

O backend utiliza FastAPI.

---

## 3. Estrutura

```text
versin_api/
├── core/
│   ├── config.py
│   └── security.py
├── models/
│   └── schemas.py
├── routes/
│   └── chat_route.py
├── services/
│   ├── ai_service.py
│   ├── chat_service.py
│   ├── project_storage_service.py
│   ├── prompt_engine.py
│   ├── quota_service.py
│   ├── rate_limiter.py
│   ├── safety_service.py
│   └── supabase_auth_service.py
├── tests/
│   ├── conftest.py
│   └── test_chat.py
├── main.py
├── requirements.txt
├── pytest.ini
└── start.sh
```

---

## 4. Organização conceitual

```text
HTTP
 │
 ▼
routes/
 │
 ▼
services/
 │
 ├── autenticação
 ├── regras/orquestração
 ├── quota
 ├── rate limiting
 ├── safety
 ├── prompt
 ├── IA
 └── storage
```

---

## 5. Entry point

```text
versin_api/main.py
```

Configuração principal:

```text
versin_api/core/config.py
```

Infraestrutura de segurança:

```text
versin_api/core/security.py
```

---

## 6. Chat

Rota:

```text
versin_api/routes/chat_route.py
```

Serviço:

```text
versin_api/services/chat_service.py
```

Fluxo conceitual:

```text
request
  │
  ▼
Chat Route
  │
  ▼
Chat Service
  │
  ├── auth
  ├── quota
  ├── rate limit
  ├── safety
  ├── prompt
  └── AI
```

---

## 7. AI Service

```text
versin_api/services/ai_service.py
```

Responsável pela comunicação com o provider configurado.

Na configuração de produção observada, o health endpoint reporta Groq e o modelo
configurado pela API.

---

## 8. Prompt Engine

```text
versin_api/services/prompt_engine.py
```

Centraliza preparação/construção de prompts.

---

## 9. Quota Service

```text
versin_api/services/quota_service.py
```

Mantém:

- quota mensal por usuário;
- quota global diária;
- tokens usados;
- tokens restantes;
- limite;
- percentual;
- bloqueio;
- renovação;
- disponibilidade do Redis.

O frontend deve usar `renews_at` como fonte da verdade para renovação.

---

## 10. Redis

Redis participa de:

- quota;
- rate limiting.

---

## 11. Rate Limiter

```text
versin_api/services/rate_limiter.py
```

Características verificadas:

- Redis;
- janela padrão de 60 segundos;
- limite configurável por minuto;
- chave por usuário;
- TTL;
- HTTP 429;
- header `Retry-After`.

Formato conceitual:

```text
rate_limit:ai:<user_id>
```

### Fail-open

Se Redis estiver indisponível, o rate limiter atualmente opera em `fail-open`.

Essa decisão deve permanecer documentada porque impacta o hardening.

---

## 12. Safety Service

```text
versin_api/services/safety_service.py
```

Responsabilidades verificadas:

- sanitização de entrada;
- remoção de caracteres de controle;
- normalização de quebras de linha;
- limite de 12.000 caracteres;
- sinalização de possível prompt injection;
- validação de estrutura da resposta da IA.

A detecção de prompt injection atualmente sinaliza e não bloqueia
automaticamente.

---

## 13. Supabase Auth Service

```text
versin_api/services/supabase_auth_service.py
```

Camada específica para integração da API com autenticação Supabase.

A identidade deve ser derivada de credencial autenticada validada, e não de
`user_id` arbitrário enviado pelo cliente.

---

## 14. Project Storage Service

```text
versin_api/services/project_storage_service.py
```

Existe uma camada própria para armazenamento relacionado a projetos.

---

## 15. Deployment

O backend está implantado separadamente do Flutter.

Ambiente atual:

```text
Render
```

Existe:

```text
versin_api/start.sh
```

---

## 16. CORS

O backend possui configuração explícita de CORS.

A origem local usada pelo Flutter Web já foi testada com headers CORS adequados
quando permitida.

---

## 17. Testes

Existe infraestrutura pytest:

```text
versin_api/pytest.ini
versin_api/tests/
```

Arquivos identificados:

```text
conftest.py
test_chat.py
```

---

## 18. Cenários prioritários de hardening

Testes importantes:

- JWT ausente;
- JWT inválido;
- JWT expirado;
- payload inválido;
- usuário não autorizado;
- quota excedida;
- rate limit excedido;
- Redis indisponível;
- provider indisponível;
- Supabase indisponível.

---

## 19. Fronteira de confiança

```text
Flutter oficial ────────┐
                        │
cliente alterado ───────┼──> Versin API
                        │
curl / script ──────────┘
```

O backend deve validar:

- identidade;
- autorização;
- entrada;
- limites.

---

## 20. Pendências

Ainda precisam ser detalhados:

- endpoints completos;
- schemas request/response;
- autenticação por endpoint;
- autorização;
- timeouts;
- retries;
- logging;
- observabilidade;
- política de secrets;
- integração completa com storage;
- cobertura de testes.
