# Versin — Módulo Networking

> **Status:** Parcialmente verificado no código\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/networking/`

---

## 1. Objetivo

Networking é o domínio colaborativo de projetos do Versin.

Ele continua o fluxo após conexões criadas pelo Match e concentra recursos de
trabalho entre participantes.

```text
Match
  │
  ▼
Project
  │
  ▼
Networking
  │
  ├── membros
  ├── convites
  ├── recrutamento
  ├── tarefas
  ├── chat
  ├── chamadas
  ├── royalties
  └── permissões
```

---

## 2. Estrutura identificada

```text
lib/modules/networking/
├── call/
├── chat/
├── core/
├── invitations/
├── members/
├── recruitment/
├── royalties/
├── tasks/
├── views/
└── widgets/
```

Também existem services/repositories distribuídos dentro dessas subáreas.

---

## 3. Projeto como contexto

Grande parte do Networking opera dentro de um:

```text
projectId
```

Membership do projeto é, portanto, uma regra central de autorização.

Helpers SQL identificados:

```text
is_project_member(...)
can_access_project_storage(...)
is_recruitment_project_member(...)
```

---

## 4. Members

Diretório:

```text
lib/modules/networking/members/
```

O domínio gerencia participantes do projeto.

O código também utiliza `projects.members` em diferentes pontos.

A representação completa de membership — array, tabelas associativas ou
combinação — ainda precisa ser consolidada.

---

## 5. Invitations

Diretório:

```text
lib/modules/networking/invitations/
```

Service identificado:

```text
project_invitation_service.dart
```

RPCs confirmadas:

```text
accept_project_invitation
reject_project_invitation
```

---

## 6. Realtime de convites

Logs confirmaram:

```text
snapshot inicial
início do Realtime
atualização de pendentes
```

Isso permite atualizar a interface quando o estado de convites muda.

Subscriptions precisam ser encerradas corretamente no lifecycle correspondente.

---

## 7. Recruitment

Diretório:

```text
lib/modules/networking/recruitment/
```

Service identificado:

```text
project_recruitment_service.dart
```

RPC confirmada:

```text
approve_project_recruitment_candidate
```

O código também trabalha com estados como:

```text
open
invited
interested
closed
```

conforme fluxos observados anteriormente.

---

## 8. Tasks

Diretório:

```text
lib/modules/networking/tasks/
```

Tarefas de projeto fazem parte do trabalho colaborativo.

Elas também podem alimentar a produção criativa através da métrica:

```text
tasks_completed
```

A integração exata entre conclusão da tarefa e evento analítico deve permanecer
documentada no fluxo `project-tasks.md`.

---

## 9. Chat de projeto

Diretório:

```text
lib/modules/networking/chat/
```

Esse Chat é distinto do módulo geral:

```text
lib/modules/chat/
```

O Chat de Networking está ligado ao contexto do projeto.

---

## 10. `project_messages`

Foi observado uso da tabela:

```text
project_messages
```

Uma constraint encontrada anteriormente foi:

```text
project_messages_content_not_empty
```

Também foi observada regra em que:

- mensagens text/system precisam de conteúdo;
- mensagens de áudio precisam de `audio_path`.

A expressão SQL completa ainda deve ser exportada antes de ser documentada
literalmente.

---

## 11. Áudio

O projeto possui suporte a gravação de áudio no Chat de projeto.

No Linux, durante desenvolvimento, foi necessário distinguir fontes PipeWire
como:

```text
monitor
microfone
```

A decisão posterior foi manter o fluxo simples de gravação pelo microfone sem
perguntar a fonte a cada gravação.

A compatibilidade multiplataforma ainda deve ser tratada pelo service
apropriado.

---

## 12. Calls

Diretório:

```text
lib/modules/networking/call/
```

Repositories identificados incluem:

```text
project_call_repository_impl.dart
communication_permission_repository_impl.dart
```

Esses arquivos possuem várias chamadas RPC.

Os nomes de todas elas ainda precisam ser extraídos porque a busca literal
anterior retornou apenas as chamadas cujo primeiro argumento era string estática
detectável.

---

## 13. Communication permissions

Existe repository dedicado a:

```text
communication_permission_repository_impl.dart
```

Isso indica que permissões de comunicação possuem lógica própria e não devem ser
tratadas apenas como estado visual.

A matriz completa de permissões ainda precisa ser auditada.

---

## 14. Royalties

Diretório:

```text
lib/modules/networking/royalties/
```

Repository identificado:

```text
royalties_repository_impl.dart
```

Esse domínio merece revisão especial porque alterações de participação/royalties
são operações sensíveis.

A UI nunca deve ser a autoridade final para alterações desse tipo.

---

## 15. Leave Match Project

A view:

```text
networking_session_view.dart
```

utiliza:

```text
leave_match_project
```

Isso conecta diretamente o ciclo Match ao Networking.

A função server-side deve validar que o usuário autenticado pode remover a
própria participação de acordo com as regras do projeto.

---

## 16. Storage de projeto

O helper:

```text
can_access_project_storage(...)
```

e o backend:

```text
versin_api/services/project_storage_service.py
```

mostram que arquivos de projeto dependem de membership/autorização.

O Networking não deve gerar URLs de acesso apenas com base em um `projectId`
fornecido pelo cliente.

---

## 17. Produção criativa

Atividades do Networking podem alimentar métricas do Dashboard, como:

```text
tasks_completed
collaborations_started
files_added
```

Isso deve ocorrer por eventos de domínio/idempotentes e não por rebuild de UI.

---

## 18. Segurança

Operações sensíveis devem validar:

```text
auth.uid()
project membership
role/permissão
estado atual do recurso
```

Não confiar apenas em:

```text
projectId
memberId
candidateId
ownerId
```

enviados pelo cliente.

---

## 19. Concorrência

Convites, recrutamento, tarefas e royalties podem sofrer atualizações
concorrentes.

Quando necessário, preferir:

- constraints;
- transactions;
- RPCs atômicas;
- optimistic concurrency;
- idempotência.

A estratégia exata precisa ser verificada por subdomínio.

---

## 20. Dependências

```text
Networking
├── Projects
├── Match
├── Profile
├── Notifications
├── Storage
├── Realtime
└── Creative Production
```

---

## 21. Documentação relacionada

```text
docs_architecture/flows/match-to-project.md
docs_architecture/flows/project-files.md
docs_architecture/flows/project-tasks.md
docs_architecture/database/rpc.md
docs_architecture/security/authorization.md
```

---

## 22. Pendências

Ainda precisamos fechar:

- modelo de membership;
- todas as RPCs de calls;
- communication permissions;
- fluxo de royalties;
- tabelas por subdomínio;
- policies RLS;
- lifecycle Realtime;
- chat completo;
- uploads;
- eventos de produção;
- testes de concorrência;
- testes negativos de autorização.
