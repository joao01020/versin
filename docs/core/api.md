# API.md

# Versin API Architecture

> A API do Versin não existe apenas para comunicação entre sistemas.
>
> Ela existe para conectar:
>
> - criatividade,
> - memória,
> - identidade artística,
> - IA contextual,
> - sincronização colaborativa.

---

# Objetivo

A infraestrutura de API do Versin foi projetada para:

- modularidade,
- escalabilidade,
- comunicação em tempo real,
- integração cognitiva,
- sincronização criativa,
- segurança distribuída.

---

# Estrutura Geral

```text
Frontend
    ↓
API Gateway
    ↓
Authentication
    ↓
Core Services
    ↓
AI Services
    ↓
Database
    ↓
Storage
```

---

# Filosofia da API

A API deve funcionar como um sistema vivo.

Ela precisa:

- preservar contexto,
- manter continuidade,
- reduzir latência,
- permitir evolução modular,
- integrar múltiplos sistemas criativos.

---

# Stack Principal

## Backend

- Node.js
- TypeScript
- Supabase
- PostgreSQL

---

## IA

- Python
- FastAPI
- NLP
- embeddings vetoriais

---

## Realtime

- Supabase Realtime
- WebSockets

---

# Estrutura Recomendada

```bash
backend/
│
├── api/
├── controllers/
├── services/
├── middleware/
├── routes/
├── websocket/
├── ai/
├── auth/
├── storage/
└── utils/
```

---

# Camadas da API

## Authentication Layer

Responsável por:

- autenticação,
- sessão,
- JWT,
- controle de acesso,
- segurança.

---

## Creative Layer

Responsável por:

- letras,
- projetos,
- sincronização criativa,
- histórico artístico.

---

## Cognitive Layer

Responsável por:

- memória contextual,
- embeddings,
- interpretação semântica,
- perfil cognitivo.

---

## Matchmaking Layer

Responsável por:

- compatibilidade artística,
- ranking contextual,
- conexões inteligentes.

---

## Legal Layer

Responsável por:

- hashes,
- timestamps,
- contratos,
- validações.

---

# Fluxo de Requisição

```text
Usuário
    ↓
Frontend
    ↓
API Gateway
    ↓
Autenticação
    ↓
Serviço correspondente
    ↓
Banco de dados
    ↓
Resposta contextual
```

---

# Endpoints Planejados

## Authentication

```http
POST /auth/signup
POST /auth/login
POST /auth/logout
GET  /auth/me
```

---

## Profiles

```http
GET    /profiles
GET    /profiles/:id
PATCH  /profiles/:id
```

---

## Lyrics

```http
GET    /lyrics
POST   /lyrics
PATCH  /lyrics/:id
DELETE /lyrics/:id
```

---

## Semantic Memory

```http
POST /memory/context
POST /memory/embedding
GET  /memory/history
```

---

## Matchmaking

```http
POST /matchmaking/analyze
GET  /matchmaking/recommendations
POST /matchmaking/connect
```

---

## Projects

```http
GET    /projects
POST   /projects
PATCH  /projects/:id
```

---

## Contracts

```http
POST /contracts/create
POST /contracts/sign
GET  /contracts/history
```

---

# Realtime System

O sistema em tempo real permitirá:

- colaboração simultânea,
- sincronização de letras,
- edição compartilhada,
- notificações inteligentes,
- eventos colaborativos.

---

# Segurança

## Proteções

- JWT
- RLS
- validação contextual
- rate limit
- middleware de autenticação

---

# Privacidade

O sistema prioriza:

- controle do usuário,
- memória privada,
- sincronização opcional,
- armazenamento seguro.

---

# IA Contextual

A API também funciona como ponte para:

- modelos de IA,
- embeddings,
- ranking semântico,
- memória cognitiva.

---

# Objetivo Futuro

A arquitetura foi planejada para suportar:

- IA multimodal,
- voz,
- colaboração em tempo real,
- memória híbrida,
- sistema neural artístico,
- sincronização descentralizada.

---

# Filosofia Técnica

A API do Versin não deve parecer uma API tradicional.

Ela deve funcionar como:

- infraestrutura cognitiva,
- ponte criativa,
- sistema contextual vivo.

---

# Objetivo Final

Construir uma API:

- modular,
- inteligente,
- escalável,
- segura,
- contextual,
- preparada para evolução artística contínua.