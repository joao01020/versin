# Versin — Módulo Hub

> **Status:** Inventário estrutural inicial\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/hub/`

---

## 1. Objetivo

Este documento registra o módulo Hub existente no aplicativo Versin.

Neste estágio, a estrutura de diretórios foi confirmada, mas o comportamento
funcional completo do módulo ainda não foi auditado arquivo por arquivo.

Por isso, este documento evita atribuir responsabilidades que ainda não foram
comprovadas.

---

## 2. Estrutura identificada

```text
lib/modules/hub/
├── controllers/
├── data/
├── views/
└── widgets/
```

Essa organização segue uma separação entre:

```text
estado/coordenação
dados
interface
componentes visuais
```

---

## 3. Posição na arquitetura

O Hub é um módulo Flutter independente dentro de:

```text
lib/modules/
```

Ele não deve ser confundido automaticamente com o projeto embarcado ESP32
`hub-lab`.

A documentação desta pasta descreve somente o módulo existente no código do
aplicativo Versin, salvo quando uma integração entre ambos for explicitamente
confirmada no código.

---

## 4. Controllers

Diretório:

```text
lib/modules/hub/controllers/
```

Responsabilidade arquitetural esperada de controllers:

- manter estado do módulo;
- coordenar ações;
- notificar UI;
- chamar camada de dados.

Os nomes e responsabilidades concretas ainda precisam ser inventariados.

---

## 5. Data

Diretório:

```text
lib/modules/hub/data/
```

Essa camada deve concentrar acesso a dados específico do módulo quando
existente.

Ainda precisamos verificar:

- datasources;
- repositories;
- Supabase;
- APIs;
- cache local;
- modelos usados.

---

## 6. Views

Diretório:

```text
lib/modules/hub/views/
```

Responsável pela apresentação das telas do Hub.

A documentação funcional das telas deve ser criada somente após listar os
arquivos e seus fluxos reais.

---

## 7. Widgets

Diretório:

```text
lib/modules/hub/widgets/
```

Deve conter componentes visuais reutilizáveis do domínio Hub.

Evitar colocar regras de negócio permanentes dentro desses widgets.

---

## 8. Fronteira de domínio

Até a auditoria detalhada, o Hub deve ser tratado como:

```text
módulo existente
+
responsabilidade funcional a confirmar
```

Não é seguro documentá-lo como marketplace, hardware, feed, dashboard ou outra
função específica sem evidência do código.

---

## 9. Segurança

Quando o módulo for auditado, verificar:

- acesso ao Supabase;
- tabelas utilizadas;
- autenticação;
- RLS;
- RPCs;
- uploads;
- Realtime;
- permissões locais;
- integrações externas.

---

## 10. Próximo levantamento

Para fechar este documento, o inventário deve obter:

```text
find lib/modules/hub -type f | sort
```

Depois, para cada arquivo relevante:

```text
controllers
data
views
widgets
```

devem ser identificadas dependências e responsabilidades.

---

## 11. Documentação relacionada

Dependendo do resultado da auditoria, este módulo poderá referenciar:

```text
architecture/flutter.md
architecture/supabase.md
security/authorization.md
database/tables.md
```

---

## 12. Pendências

Ainda não confirmados:

- propósito de negócio;
- telas;
- controllers;
- tabelas;
- repositories;
- integrações;
- fluxo de navegação;
- autorização;
- Realtime;
- relação, se houver, com hardware externo.
