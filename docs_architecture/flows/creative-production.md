# Versin — Fluxo Creative Production

> **Status:** Parcialmente verificado no código, banco e execução\
> **Última revisão:** 2026-08-24\
> **Escopo:** eventos criativos → agregação mensal → Dashboard

---

## 1. Objetivo

Creative Production transforma ações reais do usuário em uma visão mensal de
produção.

O gráfico não deve ser alimentado manualmente pela UI.

```text
ações do usuário
      │
      ▼
eventos criativos
      │
      ▼
creative_activity_events
      │
      ▼
agregação mensal
      │
      ▼
CreativeProductionMonth
      │
      ▼
score
      │
      ▼
Dashboard
```

---

## 2. Métricas conhecidas

O retorno mensal confirmado contém:

```text
projects_created
composition_sessions
tasks_completed
collaborations_started
files_added
```

Cada métrica representa uma categoria de produção.

---

## 3. Fonte de eventos

Eventos devem nascer no domínio onde a ação realmente ocorreu.

Exemplos:

```text
Studio
  → composition_session

Projects / Match
  → project_created

Tasks
  → task_completed

Collaboration
  → collaboration_started

Storage
  → file_added
```

Nem todos esses pontos de emissão já foram auditados integralmente.

---

## 4. Regra principal

Evitar:

```text
Widget abriu
   ↓
incrementa produção
```

Preferir:

```text
ação de domínio concluída
   ↓
evento idempotente
```

Isso evita que rebuilds, navegação ou refresh inflem as métricas.

---

## 5. CreativeActivityService

Foi identificado:

```text
lib/modules/dashboard/production/services/creative_activity_service.dart
```

Esse service registra e consulta atividade criativa.

---

## 6. Tabela de eventos

Foi confirmada:

```text
creative_activity_events
```

Essa tabela mantém eventos individuais antes da agregação mensal.

---

## 7. Identidade do evento

Foi confirmada a existência do índice:

```text
creative_activity_events_source_unique_idx
```

com unicidade em:

```text
(user_id, event_type, source_id)
```

Isso significa que a mesma origem lógica não pode ser registrada duas vezes para
o mesmo usuário e tipo.

---

## 8. `source_id`

`source_id` deve identificar a origem lógica do evento.

Exemplos conceituais:

```text
project:<project-id>
task:<task-id>
studio:<session-id>
file:<file-id>
```

O formato definitivo deve seguir cada implementação existente.

---

## 9. Duplicidade

Durante testes foi observado erro:

```text
23505
duplicate key value violates unique constraint
creative_activity_events_source_unique_idx
```

Isso confirmou que a proteção de unicidade estava ativa.

O teste tentou inserir novamente a mesma combinação:

```text
user_id
event_type
source_id
```

---

## 10. Studio

O fluxo mais claramente auditado é o Studio.

Em:

```text
studio_page.dart
```

existe:

```text
_registerCompositionSessionSafely()
```

que registra:

```text
composition_session
```

---

## 11. Início da sessão de composição

A página observa a transição para:

```text
controller.hasUnsavedChanges == true
```

e utiliza essa mudança como sinal de atividade.

Isso evita depender de rebuild.

---

## 12. Session ID

O Studio cria um identificador baseado em:

```text
studio_
timestamp em microssegundos
sequence
```

Esse ID é enviado como origem da sessão.

---

## 13. Metadata do Studio

Metadata observada:

```text
origin
started_at
studio_title
bpm
sequence
```

O evento deve manter metadata pequena e útil.

---

## 14. Best-effort

O registro de produção no Studio é explicitamente best-effort:

```text
falha na analytics
    !=
falha da edição
```

Uma indisponibilidade do Supabase não deve desfazer trabalho criativo.

---

## 15. Autenticação

O service verifica se existe usuário autenticado antes de registrar a sessão.

No lado confiável, a identidade deve ser derivada da sessão e não escolhida
livremente pelo cliente.

---

## 16. Agregação mensal

Foi confirmado em execução um RPC retornando 12 meses.

Exemplo:

```text
2025-09
...
2026-08
```

Cada item retornava:

```text
month_start
projects_created
composition_sessions
tasks_completed
collaborations_started
files_added
```

---

## 17. Meses sem atividade

O RPC retornou meses com zeros quando não existiam eventos.

Isso é importante para o gráfico manter uma janela temporal contínua.

Exemplo:

```text
2026-07 → 0
2026-08 → 0
```

em vez de omitir completamente o mês.

---

## 18. CreativeProductionMonth

No Flutter, os dados mensais são transformados em um modelo de produção.

O gráfico utiliza informações como:

```text
score
changeFromPreviousMonth
projectsCreated
compositionSessions
tasksCompleted
collaborationsStarted
filesAdded
```

---

## 19. Score

Foi observado no serviço:

```text
compositionSessionWeight = 3.0
```

Isso significa que uma sessão de composição contribui com peso específico para o
score.

Os pesos restantes devem ser copiados do código antes de serem tratados como
contrato oficial.

---

## 20. Normalização

O gráfico trabalha com score visual limitado a:

```text
0..100
```

Trecho observado:

```text
month.score.clamp(0.0, 100.0)
```

A fórmula de cálculo do score deve permanecer no service/model, não no widget.

---

## 21. Comparação mensal

O modelo expõe:

```text
changeFromPreviousMonth
```

A interface representa:

```text
↑ aumento
↓ queda
→ estável
```

O primeiro mês não possui comparação anterior dentro da janela.

---

## 22. Dashboard

Widget auditado:

```text
versin_statistics_card_widget.dart
```

Ele apresenta:

- barras;
- seleção de mês;
- mês atual;
- comparação;
- detalhes;
- loading;
- interação por hover/click.

---

## 23. Tooltip / detalhes

O gráfico utiliza dados mensais para apresentar:

```text
produção
projetos
sessões
tarefas
colaborações
arquivos
comparação anterior
```

A UI foi sendo refinada para mostrar informação de forma progressiva.

---

## 24. Testes manuais

Durante desenvolvimento foram inseridos eventos de teste para verificar se o
gráfico reagia.

A prática correta é:

```text
1. inserir eventos claramente identificados como teste
2. validar RPC
3. validar Flutter
4. remover apenas os eventos de teste
5. confirmar retorno a zero
```

Nunca desabilitar RLS ou abrir policies amplas apenas para facilitar esse teste.

---

## 25. Segurança

O cliente não deve conseguir:

```text
registrar atividade para outro usuário
alterar agregados arbitrariamente
duplicar a mesma origem
escrever score diretamente
```

O score deve ser derivado dos eventos válidos.

---

## 26. Analytics versus domínio

A atividade criativa é uma projeção do que aconteceu.

Ela não deve ser a fonte de verdade para o próprio recurso.

Exemplo:

```text
task
  → fonte de verdade: tabela/estado da tarefa

task_completed event
  → projeção analítica
```

Se o evento falhar, a tarefa ainda deve continuar concluída.

---

## 27. Fluxo resumido

```text
1. usuário executa ação real
2. domínio conclui a operação
3. cria source_id estável
4. registra creative activity
5. banco impede duplicação lógica
6. RPC agrega por mês
7. Flutter recebe janela mensal
8. service calcula score
9. Dashboard renderiza gráfico
```

---

## 28. Documentação relacionada

```text
docs_architecture/modules/dashboard.md
docs_architecture/modules/studio.md
docs_architecture/database/tables.md
docs_architecture/database/rpc.md
```

---

## 29. Pendências

Ainda precisamos confirmar:

- nome exato do RPC mensal;
- todos os event types;
- todos os pontos de emissão;
- todos os pesos;
- regra exata do score;
- comportamento ao apagar recurso original;
- retenção dos eventos;
- policies de INSERT/SELECT;
- testes automatizados;
- proteção server-side contra eventos forjados.
