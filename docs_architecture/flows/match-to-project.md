# Versin — Fluxo Match → Project

> **Status:** Parcialmente verificado diretamente no Flutter\
> **Última revisão:** 2026-08-24\
> **Escopo:** conexão no Match → localização/criação de projeto → Networking

---

## 1. Objetivo

Este fluxo descreve como uma conexão no Match se transforma em um projeto
utilizável pelo restante do Versin.

```text
Usuário A
    │
    ├── Match
    │
Usuário B
    │
    ▼
conexão
    │
    ▼
procura projeto existente
    │
    ├── existe ──► reutiliza
    │
    └── não existe
           │
           ▼
        cria projeto
           │
           ▼
        projectId
           │
           ▼
       Networking
```

---

## 2. Código principal identificado

O fluxo foi observado em:

```text
lib/modules/match/controllers/match_controllers.dart
```

---

## 3. IDs normalizados

O código utiliza:

```text
normalizedMyId
normalizedOtherId
```

antes de consultar/criar o projeto.

A normalização no cliente melhora consistência, mas a autorização definitiva
continua sendo responsabilidade do banco/backend.

---

## 4. Busca de projeto existente

Foi observado:

```dart
_supabase
    .from('projects')
    .select('id, members')
    .contains(
      'members',
      [
        normalizedMyId,
        normalizedOtherId,
      ],
    )
    .limit(1);
```

A intenção é evitar criar outro projeto quando já existe um contendo os dois
usuários.

---

## 5. Projeto encontrado

Quando a consulta retorna um projeto válido:

```text
existingProjectId
```

o controller:

```text
emite evento de Match
retorna sucesso
```

e não cria outro registro.

---

## 6. Criação

Quando nenhum projeto correspondente é encontrado, o código insere:

```text
title: Studio Session

members:
- normalizedMyId
- normalizedOtherId

founders:
- normalizedMyId
- normalizedOtherId

status: active

origin: match
```

Depois recupera:

```text
id
```

---

## 7. `origin`

O campo:

```text
origin = match
```

permite identificar que o projeto nasceu desse fluxo.

---

## 8. `status`

O projeto é criado como:

```text
status = active
```

Outros estados precisam ser documentados a partir do schema/código completo.

---

## 9. `members`

O projeto contém inicialmente os dois usuários envolvidos.

A representação observada é compatível com uma coleção em:

```text
projects.members
```

A arquitetura completa de membership ainda precisa ser consolidada com outras
tabelas/helpers do Networking.

---

## 10. `founders`

Os dois participantes iniciais também são gravados como:

```text
founders
```

Isso diferencia membros iniciais de participantes que podem entrar
posteriormente.

---

## 11. Consulta de projetos Match

Em outra view foi observado filtro:

```text
origin = match
status = active
members contém userId
```

Esse padrão é utilizado para recuperar projetos ativos originados no Match.

---

## 12. Evento de Match

Depois de encontrar ou criar o projeto, o controller chama um mecanismo como:

```text
_emitMatchEvent(projectId)
```

Isso desacopla a criação do projeto das próximas ações de navegação/atualização.

---

## 13. Networking

Depois que existe um `projectId`, o projeto passa a ser contexto para recursos
de Networking:

```text
membros
chat
tarefas
convites
recrutamento
calls
royalties
arquivos
```

---

## 14. Saída

Foi encontrada RPC:

```text
leave_match_project
```

em:

```text
networking_session_view.dart
```

Ela representa parte do ciclo posterior de um projeto originado pelo Match.

---

## 15. Disponibilidade

O ecossistema Match também possui:

```text
set_my_available_now
clear_my_available_now
```

Essas RPCs participam da descoberta/disponibilidade, mas não são a criação do
projeto em si.

---

## 16. Username

O Match Controller utiliza:

```text
check_username_available
set_my_username
```

Essas operações fazem parte da preparação da identidade pública utilizada no
ecossistema Match.

---

## 17. Problema de concorrência

O padrão:

```text
SELECT
se não existe
INSERT
```

pode sofrer corrida.

Exemplo:

```text
cliente A → SELECT vazio
cliente B → SELECT vazio

cliente A → INSERT
cliente B → INSERT
```

Sem proteção server-side, dois projetos equivalentes podem ser criados.

---

## 18. Proteção recomendada

A solução definitiva deve existir no lado confiável.

Possibilidades arquiteturais:

```text
constraint de chave canônica
RPC transacional
índice único apropriado
função get-or-create
```

Não devemos afirmar qual delas já existe sem verificar o banco.

---

## 19. Autorização

O cliente não deve poder criar um projeto arbitrário dizendo:

```text
founders = qualquer usuário
members = qualquer usuário
```

A regra server-side precisa validar a identidade do solicitante e o fluxo
permitido.

---

## 20. Idempotência

O resultado desejado é:

```text
mesma relação lógica
      │
      ▼
mesmo projeto
```

quando a regra de produto determina que deve existir apenas um projeto Match
para aquela relação.

A regra exata de unicidade precisa ser confirmada.

---

## 21. Produção criativa

Projetos criados podem alimentar:

```text
projects_created
```

no sistema de Creative Production.

O evento deve ocorrer somente após criação real e deve possuir `source_id`
idempotente.

---

## 22. Falhas

Casos a tratar:

```text
projeto encontrado sem id válido
falha no SELECT
falha no INSERT
sessão expirada
RLS negando
projeto duplicado por corrida
usuário removido/bloqueado durante operação
```

---

## 23. Fluxo resumido

```text
1. conexão de Match é confirmada
2. IDs são normalizados
3. procura projeto contendo os dois
4. se existe, reutiliza
5. se não existe, cria projeto origin=match
6. grava membros/founders iniciais
7. recebe projectId
8. emite evento
9. projeto passa ao ecossistema Networking
```

---

## 24. Arquivos relacionados

```text
lib/modules/match/controllers/match_controllers.dart
lib/modules/match/views/match_projects_view.dart
lib/modules/networking/views/networking_session_view.dart
```

---

## 25. Documentação relacionada

```text
docs_architecture/modules/match.md
docs_architecture/modules/networking.md
docs_architecture/database/relationships.md
docs_architecture/database/rls.md
docs_architecture/security/authorization.md
```

---

## 26. Pendências

Precisamos confirmar:

- constraint contra duplicação;
- RLS de `projects`;
- tipos reais de `members` e `founders`;
- regra de Match confirmado;
- bloqueios;
- comportamento ao sair;
- owner/founder permissions;
- evento `project_created`;
- transação server-side;
- testes concorrentes.
