# Versin — Backend Authentication

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** autenticação da Versin API

---

## 1. Objetivo

Este documento descreve a arquitetura de autenticação do backend FastAPI.

Service identificado:

```text
versin_api/services/supabase_auth_service.py
```

---

## 2. Fonte de identidade

A identidade confiável deve vir de uma credencial autenticada.

```text
Flutter
  │
  │ Authorization: Bearer <JWT>
  ▼
Versin API
  │
  ▼
SupabaseAuthService
  │
  ▼
JWT validado
  │
  ▼
user_id confiável
```

---

## 3. Regra de confiança

O backend não deve assumir que um `user_id` informado pelo cliente é verdadeiro.

Mesmo quando um ID aparece em URL ou payload, operações sensíveis precisam
validar a identidade autenticada e a autorização sobre o recurso.

---

## 4. Relação com Supabase Auth

O Flutter usa Supabase Auth diretamente. O backend reutiliza essa identidade
para operações server-side.

```text
Supabase Auth
    │
    ├── sessão Flutter
    └── JWT usado pelo backend
```

---

## 5. Authentication x Authorization

```text
Authentication
     │
     ▼
Quem é o usuário?

Authorization
     │
     ▼
Esse usuário pode fazer isso?
```

Autenticar não autoriza automaticamente acesso a projetos, arquivos ou recursos
de terceiros.

---

## 6. Flutter versus backend

No cliente existem:

```text
AuthWrapper
AuthGuard
SupabaseSessionManager
```

Esses componentes controlam sessão e navegação, mas não substituem validação no
backend.

---

## 7. Secrets

Segredos devem permanecer somente no servidor.

Exemplos conceituais:

```text
VERSIN_API_SECRET
provider API keys
credenciais privilegiadas
service-role credentials
```

Valores reais não devem entrar nesta documentação.

---

## 8. Testes prioritários

```text
sem Authorization
JWT malformado
JWT inválido
JWT expirado
usuário inexistente
usuário diferente do recurso solicitado
token válido sem autorização
```

---

## 9. Pendências

Ainda precisamos documentar:

- implementação completa de `supabase_auth_service.py`;
- forma exata de validação do JWT;
- issuer/audience, se verificados;
- tratamento de expiração;
- respostas 401/403;
- autorização por endpoint;
- logging seguro de falhas.
