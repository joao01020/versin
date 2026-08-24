# Versin — Visão Geral da Arquitetura

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Fonte de verdade:** código e configuração atuais do projeto

---

## 1. Objetivo

Este documento apresenta a arquitetura técnica de alto nível do Versin.

Seu objetivo é permitir que um desenvolvedor entenda rapidamente:

- quais são os principais componentes do sistema;
- onde cada componente está localizado;
- quais responsabilidades pertencem ao cliente;
- quais responsabilidades pertencem ao backend;
- qual é o papel do Supabase;
- como autenticação e inicialização funcionam;
- onde procurar detalhes adicionais.

Este documento não descreve regras internas de cada módulo.

---

## 2. Arquitetura macro

O Versin é composto por três grandes áreas:

```text
                     VERSIN
                        │
      ┌─────────────────┼─────────────────┐
      │                 │                 │
      ▼                 ▼                 ▼
Flutter Client      Versin API        Supabase
      │                 │                 │
      │                 │                 ├── Auth
      │                 │                 ├── PostgreSQL
      │                 │                 ├── Storage
      │                 │                 ├── Realtime
      │                 │                 └── Edge Functions
      │                 │
      └─────────────────┴─────────────────┘
                        │
                        ▼
                 Dados e serviços
```
