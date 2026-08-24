# Versin — Módulo Notifications

> **Status:** Parcialmente verificado no código e em execução\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/notifications/`

---

## 1. Objetivo

O módulo Notifications concentra a leitura, representação e atualização das
notificações do usuário no Versin.

Ele funciona como um domínio compartilhado: diferentes partes da aplicação podem
produzir acontecimentos relevantes, enquanto Notifications oferece a camada
responsável por apresentá-los e manter seu estado.

```text
Eventos do Versin
      │
      ▼
dados de notificação
      │
      ▼
Notifications
      │
      ├── carregamento inicial
      ├── estado
      ├── Realtime
      ├── lidas / não lidas
      └── widgets
```

---

## 2. Estrutura identificada

```text
lib/modules/notifications/
├── controllers/
├── data/
├── models/
├── repositories/
└── widgets/
```

Essa divisão separa:

- coordenação de estado;
- acesso remoto/dados;
- representação do domínio;
- abstração de persistência;
- apresentação.

---

## 3. Responsabilidade do módulo

Notifications deve ser responsável por:

- buscar notificações;
- manter a lista em memória;
- atualizar o estado quando o backend muda;
- controlar contagem de não lidas;
- expor estado para a interface;
- representar notificações através de modelos próprios.

Regras de negócio que originam uma notificação devem permanecer no domínio
responsável pelo evento.

---

## 4. Carregamento inicial

Logs de execução confirmaram o fluxo:

```text
[NOTIFICATION REMOTE]
notificações carregadas

        │
        ▼

[NOTIFICATION CONTROLLER]
estado atualizado
```

Também foi observado cálculo de:

```text
total
não lidas
```

---

## 5. Realtime

O módulo utiliza atualização Realtime.

Logs confirmaram mensagens como:

```text
[NOTIFICATION CONTROLLER] Realtime atualizado.
[NOTIFICATION CONTROLLER] Total: ...
[NOTIFICATION CONTROLLER] Não lidas: ...
```

Fluxo conceitual:

```text
Supabase
   │
   │ mudança
   ▼
Realtime
   │
   ▼
Notification Remote
   │
   ▼
Controller
   │
   ▼
UI
```

---

## 6. Snapshot inicial

A arquitetura deve evitar que:

```text
fetch inicial
+
snapshot inicial do Realtime
```

cause duplicação visual ou processamento redundante.

Esse padrão também aparece em outros domínios do Versin e deve ser tratado de
forma consistente.

---

## 7. Estado lida / não lida

O controller mantém a contagem de notificações não lidas.

A fonte persistente desse estado deve permanecer no backend/banco.

A UI pode manter estado temporário para resposta imediata, mas não deve ser a
autoridade final.

---

## 8. Dashboard

O Dashboard consome o módulo Notifications.

```text
Notifications
      │
      ▼
Dashboard
      │
      ├── indicador
      ├── contador
      └── lista/ação
```

Isso significa que o Dashboard não deve reimplementar a lógica de consulta de
notificações.

---

## 9. Convites versus notificações

Convites de projeto possuem domínio próprio:

```text
networking/invitations
```

e controller específico.

Mesmo quando um convite produz uma notificação, os dois conceitos não devem ser
confundidos.

```text
Project Invitation
       │
       ├── estado do convite
       │
       └── pode gerar
              │
              ▼
          Notification
```

A notificação informa o usuário; o convite mantém o estado da operação.

---

## 10. Atividade recente

O Dashboard também possui fluxo de atividade recente.

Logs confirmaram:

```text
[RECENT ACTIVITY REMOTE]
[RECENT ACTIVITY CONTROLLER]
```

Atividade recente e notificação devem permanecer conceitos separados mesmo
quando representam acontecimentos semelhantes.

---

## 11. Notificações de sistema

Durante a auditoria do banco foi confirmada a existência de:

```text
system_notifications
```

e a relação:

```text
system_notifications.update_id
    → app_updates.id
```

Isso demonstra que existe pelo menos um contexto de notificações ligado a
atualizações do sistema.

Não se deve concluir que `system_notifications` seja a mesma tabela usada para
todas as notificações do usuário sem validar os datasources.

---

## 12. Segurança

Uma notificação destinada a um usuário não deve poder ser lida ou modificada por
outro usuário sem uma regra explícita.

A autorização precisa existir no banco/backend.

Testes importantes:

```text
usuário A lê notificação de A      → permitido
usuário A lê notificação de B      → negar
usuário A altera notificação de B  → negar
anon consulta notificações privadas → negar
```

---

## 13. Realtime e autorização

Realtime não substitui RLS.

Uma subscription só deve entregar dados que a sessão tem autorização para
observar.

A auditoria final deve confirmar:

- tabela;
- publication;
- filtros;
- policies;
- lifecycle da subscription.

---

## 14. Lifecycle

Controllers que iniciam Realtime precisam encerrar subscriptions quando deixam
de ser utilizados.

Objetivo:

```text
evitar subscriptions duplicadas
evitar listeners órfãos
evitar múltiplas atualizações da mesma mudança
```

---

## 15. Tratamento de falhas

O módulo deve diferenciar:

```text
carregando
sem notificações
erro
dados disponíveis
```

Uma falha temporária de Realtime não deve apagar automaticamente um snapshot
válido já carregado.

---

## 16. Dependências

```text
Notifications
├── Supabase
├── Realtime
├── Dashboard
├── Networking / Invitations
└── outros domínios produtores de eventos
```

---

## 17. Arquivos relacionados

```text
lib/modules/notifications/controllers/
lib/modules/notifications/data/
lib/modules/notifications/models/
lib/modules/notifications/repositories/
lib/modules/notifications/widgets/
```

---

## 18. Documentação relacionada

```text
docs_architecture/modules/dashboard.md
docs_architecture/modules/networking.md
docs_architecture/database/rls.md
docs_architecture/database/tables.md
docs_architecture/security/authorization.md
```

---

## 19. Pendências

Ainda precisamos confirmar diretamente no código:

- nomes de todas as tabelas;
- modelo completo de notificação;
- tipos de notificação;
- método de marcar como lida;
- método de excluir;
- paginação;
- ordenação;
- retenção;
- filtros do Realtime;
- RLS;
- origem de cada categoria;
- comportamento offline/cache.
