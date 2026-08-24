# Versin — Arquitetura de Autenticação

> **Status:** Verificado no código em nível arquitetural\
> **Última revisão:** 2026-08-24\
> **Escopo:** Flutter + Supabase Auth

---

## 1. Objetivo

Este documento descreve o fluxo de autenticação do Versin e as responsabilidades
dos principais componentes envolvidos.

A autenticação utiliza Supabase Auth no cliente Flutter.

A aplicação separa três responsabilidades:

```text
SupabaseSessionManager
        │
        ├── valida sessão restaurada
        ├── verifica expiração
        └── coordena refresh do JWT

AuthWrapper
        │
        └── decide o fluxo principal da aplicação

AuthGuard
        │
        └── protege rotas privadas
```

---

## 2. Inicialização do Supabase

O Supabase é inicializado durante o bootstrap em:

```text
lib/main.dart
```

As configurações são carregadas do `.env`:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Fluxo:

```text
main()
  │
  ├── dotenv.load()
  ├── Supabase.initialize()
  ├── SupabaseSessionManager.initialize()
  └── aplicação continua
```

O cliente utiliza `AuthFlowType.implicit`.

---

## 3. SupabaseSessionManager

Localização:

```text
lib/core/auth/supabase_session_manager.dart
```

Responsabilidades verificadas:

- acessar a sessão atual;
- acessar o usuário atual;
- identificar sessão ausente;
- identificar sessão expirada;
- renovar sessão quando necessário;
- acompanhar mudanças de autenticação;
- acompanhar `tokenRefreshed`;
- evitar refreshes simultâneos.

Fluxo conceitual:

```text
sessão restaurada
      │
      ▼
ensureValidSession()
      │
      ├── sem sessão ─────────────> false
      ├── sessão válida ──────────> true
      └── sessão expirada
             │
             ▼
        refreshSession()
```

O manager é inicializado após `Supabase.initialize()` e antes de serviços que
dependem de sessão válida.

---

## 4. AuthWrapper

Localização:

```text
lib/app/auth_wrapper.dart
```

O `AuthWrapper` é o gate principal da aplicação.

```text
AuthWrapper
    │
    ├── recuperação de senha ──> ResetPasswordPage
    ├── usuário autenticado ───> DashboardPage
    └── sem usuário ───────────> LoginPage
```

A recuperação de senha possui prioridade sobre o estado autenticado.

---

## 5. Ordem de inicialização do AuthWrapper

A ordem verificada é:

1. registrar listener de autenticação;
2. verificar sessão inicial existente;
3. processar deep link inicial depois do primeiro frame.

---

## 6. Eventos de autenticação

O `AuthWrapper` acompanha:

```text
Supabase.auth.onAuthStateChange
```

Eventos tratados explicitamente:

- `passwordRecovery`;
- `signedOut`;
- `userUpdated`.

Durante `passwordRecovery`, o Dashboard não é aberto.

Durante `signedOut`, o usuário atual é limpo e a aplicação retorna ao fluxo não
autenticado.

Durante `userUpdated` em recuperação de senha, o fluxo de recovery permanece
ativo até a experiência da página de redefinição concluir.

---

## 7. AuthGuard

Localização:

```text
lib/app/auth_guard.dart
```

O `AuthGuard`:

- lê o usuário Supabase atual;
- acompanha `onAuthStateChange`;
- mostra loading durante resolução do estado;
- mostra `LoginPage` sem usuário;
- libera o widget protegido quando autenticado.

> O `AuthGuard` não substitui RLS, policies, autorização em RPCs ou validação no
> backend.

---

## 8. Deep links

### Web

O Supabase Flutter normalmente processa a URL recebida pelo navegador.

### Desktop

O Versin utiliza:

```text
versin://...
```

O `main.dart` encaminha o URI ao `AuthWrapper`, que utiliza:

```text
_supabase.auth.getSessionFromUrl(uri)
```

---

## 9. Fronteira de segurança

```text
Flutter/AuthGuard
      │
      └── controle de experiência e navegação

Supabase / Backend
      │
      └── autorização real
```

O cliente não deve ser tratado como fronteira final de segurança.

---

## 10. Estado atual da auditoria

### Confirmado

- Supabase Auth é utilizado;
- Supabase é inicializado no bootstrap;
- `SupabaseSessionManager` valida sessão;
- `AuthWrapper` decide Login/Dashboard/Recovery;
- `AuthGuard` protege rotas;
- recovery possui prioridade;
- Desktop utiliza `versin://`.

### Ainda será auditado

- policies relacionadas a autenticação;
- claims usados nas RPCs;
- revogação de `EXECUTE` desnecessário;
- cenários extremos de expiração;
- logout em todas as plataformas.
