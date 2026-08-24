# Versin — Fluxo Project Tasks

> **Status:** Estrutura do domínio confirmada; fluxo detalhado parcialmente
> pendente\
> **Última revisão:** 2026-08-24\
> **Escopo:** tarefas dentro de projetos do Networking

---

## 1. Objetivo

Project Tasks representa trabalho operacional dentro de um projeto.

O fluxo pertence ao módulo Networking:

```text
lib/modules/networking/tasks/
```

e pode alimentar a produção criativa quando uma tarefa é efetivamente concluída.

---

## 2. Contexto

```text
Project
  │
  ▼
Networking
  │
  ▼
Tasks
  │
  ├── criar
  ├── atribuir
  ├── atualizar
  └── concluir
         │
         ▼
  Creative Production
```

As operações concretas disponíveis precisam ser confirmadas diretamente nos
arquivos do submódulo.

---

## 3. Projeto como fronteira

Toda tarefa de projeto precisa estar vinculada a um contexto autorizado.

Conceitualmente:

```text
task
└── project
      └── members / permissions
```

Conhecer o `taskId` não deve conceder acesso se o usuário não pode acessar o
projeto.

---

## 4. Membership

Antes de leitura ou alteração sensível, a camada confiável deve validar:

```text
auth.uid()
membership
papel/permissão
estado da tarefa
```

O helper geral:

```text
is_project_member(...)
```

já foi identificado na auditoria do banco.

A função específica usada por Tasks ainda precisa ser confirmada.

---

## 5. Criação

Fluxo conceitual:

```text
membro autorizado
      │
      ▼
cria tarefa
      │
      ▼
validação server-side
      │
      ▼
task persistida
      │
      ▼
UI atualizada
```

Campos exatos ainda precisam ser extraídos do model/schema.

---

## 6. Atribuição

Se Tasks suporta responsáveis, o servidor deve validar que o usuário atribuído
pode participar daquele projeto.

Não confiar apenas em um `assignee_id` enviado pelo cliente.

Essa regra precisa ser confirmada na implementação atual antes de ser tratada
como funcionalidade existente.

---

## 7. Estados

O estado exato das tarefas ainda precisa ser levantado.

Não devemos assumir enums como:

```text
todo
doing
done
```

sem evidência do código/schema.

Este documento utiliza apenas o conceito confirmado de:

```text
tasks_completed
```

na produção criativa.

---

## 8. Conclusão

Quando uma tarefa muda para um estado considerado concluído pelo domínio, ela
pode gerar:

```text
task_completed
```

para Creative Activity.

O evento deve representar uma transição real, não a simples visualização de uma
tarefa já concluída.

---

## 9. Problema de duplicação

Um usuário pode:

```text
concluir
reabrir
concluir novamente
```

ou o cliente pode repetir uma requisição após timeout.

A regra de analytics precisa decidir se isso representa:

```text
uma conclusão lógica
ou
múltiplas conclusões
```

A política atual ainda precisa ser confirmada.

---

## 10. `source_id`

Se uma tarefa deve contar apenas uma vez, um `source_id` estável baseado na
tarefa permite idempotência.

Exemplo conceitual:

```text
task:<task-id>
```

O formato real deve seguir o service responsável.

---

## 11. Creative Production

A agregação mensal possui:

```text
tasks_completed
```

confirmado no retorno do RPC de produção.

Fluxo:

```text
Task concluída
    │
    ▼
CreativeActivityService
    │
    ▼
creative_activity_events
    │
    ▼
agregação mensal
    │
    ▼
tasks_completed
    │
    ▼
score do Dashboard
```

---

## 12. Analytics não é fonte de verdade

Se o registro de Creative Activity falhar:

```text
task concluída
      continua
      concluída
```

Não desfazer a operação principal apenas porque a métrica não foi registrada.

Esse é o mesmo princípio utilizado no Studio.

---

## 13. Realtime

Tasks colaborativas podem se beneficiar de Realtime para manter múltiplos
membros sincronizados.

A existência e configuração exatas da subscription de Tasks ainda precisam ser
auditadas.

Se houver Realtime:

```text
mudança no banco
      │
      ▼
subscription
      │
      ▼
controller/repository
      │
      ▼
UI
```

---

## 14. Concorrência

Dois membros podem editar a mesma tarefa quase simultaneamente.

Casos:

```text
A conclui
B altera descrição
A reabre
B exclui
```

A estratégia atual para conflito ainda precisa ser confirmada.

---

## 15. Autorização

Testes necessários:

```text
membro autorizado lê tarefa       → permitido
não membro lê tarefa               → negar
não membro altera tarefa           → negar
usuário altera projeto_id          → negar
usuário conclui tarefa de outro projeto sem acesso → negar
anon acessa tarefa privada         → negar
```

---

## 16. Delete

Se Tasks permite exclusão, precisamos definir impacto sobre Creative Production.

Pergunta arquitetural:

```text
apagar uma tarefa concluída
    ↓
remove o evento histórico?
ou
mantém histórico?
```

Isso ainda não está documentado no comportamento atual.

---

## 17. Histórico

Também precisamos decidir se alterações de tarefa exigem:

```text
audit log
updated_at
completed_at
completed_by
```

Os campos reais precisam ser confirmados no banco.

---

## 18. Notifications

Mudanças em tarefas podem potencialmente produzir notificações.

Exemplos possíveis:

```text
atribuição
prazo
conclusão
comentário
```

Não devemos registrar esses tipos como existentes até confirmar o código.

---

## 19. Project membership alterado

Se um usuário sai do projeto, o acesso às tarefas deve acompanhar a nova
autorização.

Não manter permissões apenas porque o cliente ainda possui dados em cache.

---

## 20. Offline/retry

Em uma aplicação colaborativa, retry pode repetir mutações.

Operações críticas devem ser idempotentes ou detectar versão/estado atual quando
necessário.

---

## 21. Fluxo resumido

```text
1. usuário entra em projeto autorizado
2. carrega tarefas permitidas
3. cria/edita tarefa
4. servidor valida membership/permissão
5. banco persiste mudança
6. UI sincroniza estado
7. ao concluir, domínio registra atividade criativa
8. evento idempotente alimenta tasks_completed
9. Dashboard reflete nova produção
```

---

## 22. Dependências

```text
Project Tasks
├── Networking
├── Projects
├── Membership
├── Supabase
├── Creative Activity
└── possivelmente Notifications / Realtime
```

---

## 23. Documentação relacionada

```text
docs_architecture/modules/networking.md
docs_architecture/modules/dashboard.md
docs_architecture/flows/creative-production.md
docs_architecture/database/rls.md
docs_architecture/security/authorization.md
```

---

## 24. Pendências

Este é o fluxo com mais detalhes ainda a levantar.

Precisamos inspecionar:

```text
lib/modules/networking/tasks/
```

para confirmar:

- arquivos;
- models;
- repository;
- service;
- controller;
- tabela;
- colunas;
- estados;
- criação;
- atribuição;
- edição;
- conclusão;
- exclusão;
- Realtime;
- RLS;
- RPCs;
- notifications;
- source_id de `task_completed`;
- concorrência;
- histórico.
