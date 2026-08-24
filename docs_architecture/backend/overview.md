# Versin — Backend Overview

> **Status:** Parcialmente verificado no código\
> **Última revisão:** 2026-08-24\
> **Escopo:** `versin_api/`

---

## 1. Objetivo

Este documento apresenta a visão geral do backend próprio do Versin. O backend é
separado do cliente Flutter e da infraestrutura Supabase.

Responsabilidades identificadas:

- Chat e IA;
- quota;
- rate limiting;
- safety;
- autenticação Supabase;
- armazenamento de projetos;
- integração com serviços externos.

---

## 2. Tecnologia principal

O backend utiliza **FastAPI** e está localizado em:

```text
versin_api/
```

---

## 3. Estrutura verificada

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
Cliente
  │
  ▼
FastAPI
  │
  ▼
Routes
  │
  ▼
Services
  │
  ├── Auth
  ├── Chat
  ├── Quota
  ├── Rate Limit
  ├── Safety
  ├── Prompt
  ├── AI
  └── Storage
  │
  ▼
Supabase / Redis / Provider de IA
```

---

## 5. Entry point

Ponto principal:

```text
versin_api/main.py
```

Configuração:

```text
versin_api/core/config.py
```

Infraestrutura de segurança:

```text
versin_api/core/security.py
```

---

## 6. Services principais

### `chat_service.py`

Orquestra o fluxo de Chat.

### `ai_service.py`

Integra com o provider de IA configurado.

### `prompt_engine.py`

Centraliza construção/preparação de prompts.

### `quota_service.py`

Controla quota individual e global.

### `rate_limiter.py`

Controla frequência de requisições via Redis.

### `safety_service.py`

Sanitiza entrada e valida respostas da IA.

### `supabase_auth_service.py`

Integra autenticação do backend com Supabase.

### `project_storage_service.py`

Coordena armazenamento relacionado a projetos.

---

## 7. Infraestrutura externa

Dependências identificadas:

```text
Supabase
Redis
Provider de IA
Render
```

---

## 8. Fronteira de segurança

O backend não deve confiar em:

- `user_id` arbitrário vindo do cliente;
- autorização decidida apenas no Flutter;
- payloads sem validação;
- nomes/caminhos de arquivo sem validação;
- estado local do cliente para quota.

Fluxo esperado:

```text
Request → Identidade → Autorização → Validação → Limites → Operação
```

---

## 9. Testes

Existe infraestrutura pytest em:

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

## 10. Deployment

O backend está implantado separadamente do Flutter. O ambiente atual usa
**Render** e existe:

```text
versin_api/start.sh
```

---

## 11. Documentos relacionados

- [`api.md`](api.md)
- [`authentication.md`](authentication.md)
- [`ai-quota.md`](ai-quota.md)
- [`deployment.md`](deployment.md)

---

## 12. Pendências

Ainda precisam de auditoria detalhada:

- todos os endpoints;
- schemas request/response;
- autenticação e autorização por endpoint;
- timeouts e retries;
- logging e observabilidade;
- comportamento multi-instância;
- cobertura de testes.
