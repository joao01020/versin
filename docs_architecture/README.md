# Versin — Documentação Técnica

> **Status:** Documentação técnica ativa e em validação contínua\
> **Última revisão:** 2026-08-24\
> **Fonte de verdade:** código, banco de dados, infraestrutura e configuração
> atuais do projeto

---

## 1. Sobre esta documentação

Este diretório contém a documentação técnica da arquitetura atual do Versin.

Ele foi criado porque a documentação anterior deixou de acompanhar a evolução do
projeto. Por esse motivo, os documentos presentes aqui não utilizam a
documentação antiga como fonte principal.

A documentação é reconstruída e validada progressivamente a partir de:

- código-fonte atual;
- estrutura do Flutter;
- backend Versin;
- configuração do Supabase;
- PostgreSQL;
- Row Level Security (RLS);
- RPCs e funções PostgreSQL;
- autenticação;
- Storage;
- Edge Functions;
- fluxos reais da aplicação;
- logs e comportamento observado durante execução;
- auditorias técnicas realizadas no projeto.

Quando uma informação ainda não tiver sido confirmada diretamente no projeto,
ela deve ser explicitamente identificada como:

```text
pendente
não verificada
parcialmente verificada
```

Hipóteses não devem ser transformadas em especificações oficiais.

---

## 2. Objetivo

Esta documentação existe para permitir que um desenvolvedor compreenda
rapidamente:

- como o Versin está organizado;
- quais são seus principais componentes;
- como os componentes se comunicam;
- onde estão as principais regras de negócio;
- como autenticação e autorização são tratadas;
- como dados e arquivos são armazenados;
- como os módulos se relacionam;
- quais serviços externos fazem parte do sistema;
- quais fluxos atravessam múltiplas camadas;
- quais decisões arquiteturais são relevantes;
- quais superfícies possuem impacto de segurança;
- quais pontos ainda precisam de auditoria ou hardening.

A documentação não pretende reproduzir o código linha por linha.

Detalhes que podem ser compreendidos diretamente pelo código não devem ser
duplicados sem necessidade.

---

## 3. Princípio de documentação

A documentação segue esta ordem de confiança:

```text
1. Código atual
2. Schema e configuração atuais
3. Infraestrutura atual
4. Comportamento observado em execução
5. Testes e auditorias
6. Documentação técnica atual
7. Documentação antiga apenas como referência histórica
```

Se houver conflito entre documentação e implementação atual, a implementação
deve ser investigada antes de atualizar este diretório.

A documentação não deve tentar esconder divergências.

---

## 4. Visão geral do Versin

O Versin possui atualmente três grandes áreas técnicas:

```text
VERSIN
│
├── Flutter Client
│   │
│   ├── app/
│   ├── core/
│   ├── features/
│   └── modules/
│
├── Versin API
│   │
│   ├── core/
│   ├── models/
│   ├── routes/
│   ├── services/
│   └── tests/
│
└── Supabase
    │
    ├── Authentication
    ├── PostgreSQL
    ├── Row Level Security
    ├── RPC / PostgreSQL Functions
    ├── Storage
    ├── Realtime
    └── Edge Functions
```

O Flutter é responsável principalmente pela experiência do usuário e
orquestração client-side.

O Supabase concentra uma parte importante da persistência, autenticação,
autorização e infraestrutura de dados.

O `versin_api` fornece uma camada backend adicional para operações que não devem
depender diretamente do cliente, incluindo o fluxo de IA.

---

## 5. Estrutura principal do projeto

A estrutura técnica atualmente conhecida inclui:

```text
versin/
│
├── lib/
│   ├── app/
│   ├── controllers/
│   ├── core/
│   ├── features/
│   └── modules/
│
├── versin_api/
│   ├── core/
│   ├── models/
│   ├── routes/
│   ├── services/
│   └── tests/
│
├── supabase/
│   ├── functions/
│   └── config.toml
│
├── assets/
├── test/
├── cloudflare/
└── docs_architecture/
```

A existência de um diretório não significa necessariamente que ele esteja
completo ou atualmente ativo.

---

## 6. Módulos Flutter

Os módulos identificados atualmente incluem:

```text
activities
brain
calendar
chat
dashboard
hub
login
market
match
networking
notifications
onboarding
profile
rhymelibrary
settings
storage
studio
vnode
wallet
```

Nem todos possuem ainda documentação individual neste diretório.

Os módulos documentados primeiro são aqueles com maior impacto arquitetural,
integração entre camadas ou relevância para segurança.

---

## 7. Backend Versin

O backend próprio está localizado em:

```text
versin_api/
```

Componentes conhecidos incluem:

```text
core/
models/
routes/
services/
tests/
```

Entre os serviços já identificados estão:

```text
ai_service.py
chat_service.py
project_storage_service.py
prompt_engine.py
quota_service.py
rate_limiter.py
safety_service.py
supabase_auth_service.py
```

O backend participa especialmente de operações relacionadas a:

- inteligência artificial;
- autenticação de requisições backend;
- quota;
- rate limiting;
- safety;
- prompts;
- storage de projeto, conforme implementação atual.

---

## 8. Supabase

O Supabase é uma parte central da arquitetura.

Atualmente são utilizados ou identificados:

```text
Supabase Auth
PostgreSQL
RLS
RPC / PostgreSQL Functions
Realtime
Storage
Edge Functions
```

O Flutter realiza operações diretamente contra Supabase em diversos módulos.

Por esse motivo, segurança não pode depender somente da aplicação cliente.

RLS, funções PostgreSQL, Storage Policies e validações server-side fazem parte
da fronteira real de segurança.

---

## 9. Edge Functions conhecidas

Foram identificadas funções relacionadas principalmente a arquivos:

```text
create-track-playback-url
create-track-upload-url
create-work-playback-url
create-work-upload-url
delete-profile-track
delete-work-file
```

Cada função deve possuir documentação e auditoria compatíveis com o nível de
acesso que concede.

---

## 10. Segurança

O princípio fundamental adotado é:

```text
Flutter não é uma fronteira de confiança.
```

Qualquer informação enviada pelo cliente pode ser modificada.

Consequentemente, controles importantes devem existir no lado confiável.

Isso inclui:

```text
autenticação
autorização
RLS
membership
RPC
Storage
quota
rate limiting
validação de arquivos
controle de acesso
```

A documentação específica está em:

```text
security/
```

---

## 11. Auditoria de PostgreSQL Functions

Durante a auditoria foi identificado um conjunto relevante de funções PostgreSQL
no schema `public`.

Também foram encontradas:

```text
34 funções SECURITY DEFINER
```

Essas funções são uma superfície prioritária de revisão porque executam com os
privilégios do owner da função.

Cada função deve ser analisada considerando:

```text
auth.uid()
autorização
argumentos
search_path
owner
EXECUTE grants
efeitos colaterais
```

A existência de `SECURITY DEFINER` não significa automaticamente
vulnerabilidade.

Ela significa que a função exige revisão cuidadosa.

---

## 12. RPCs utilizadas pelo Flutter

Entre as RPCs confirmadas diretamente no código Flutter estão:

```text
accept_project_invitation
approve_project_recruitment_candidate
check_username_available
clear_my_available_now
increment_word_score
leave_match_project
reject_project_invitation
set_my_available_now
set_my_online_preference
set_my_username
update_my_presence
```

A lista representa chamadas confirmadas durante a auditoria realizada até esta
revisão.

Novas RPCs devem ser adicionadas quando forem identificadas.

---

## 13. Arquivos e Storage

O Versin possui fluxos de arquivos associados a diferentes domínios.

A arquitetura conhecida utiliza mecanismos relacionados a:

```text
upload
playback
delete
metadata
hash
Storage
URLs temporárias
```

SHA-256 pode ser utilizado para integridade e identificação de conteúdo.

Entretanto:

```text
hash != criptografia
hash != autorização
hash != controle de acesso
```

A proteção real de arquivos depende também das regras de autorização, Storage
Policies e componentes server-side.

---

## 14. Creative Production

O Versin possui uma camada de atividade criativa que transforma eventos reais da
aplicação em métricas mensais.

Fluxo conhecido:

```text
ação do usuário
      │
      ▼
creative activity event
      │
      ▼
creative_activity_events
      │
      ▼
agregação mensal
      │
      ▼
Creative Production
      │
      ▼
Dashboard
```

Métricas confirmadas incluem:

```text
projects_created
composition_sessions
tasks_completed
collaborations_started
files_added
```

Existe proteção contra duplicação lógica utilizando a combinação:

```text
user_id
event_type
source_id
```

---

## 15. Match e Networking

O Match pode originar projetos utilizados pelo Networking.

Fluxo conhecido:

```text
Match
  │
  ▼
conexão entre usuários
  │
  ▼
procura projeto existente
  │
  ├── existe → reutiliza
  │
  └── não existe → cria
                    │
                    ▼
                 Project
                    │
                    ▼
               Networking
```

Projetos originados pelo Match foram observados utilizando:

```text
origin = match
status = active
```

e contendo inicialmente os participantes em:

```text
members
founders
```

A proteção server-side contra concorrência e manipulação desses campos ainda faz
parte da auditoria.

---

## 16. Chat e IA

O fluxo de IA possui backend próprio.

Componentes identificados:

```text
chat_route.py
ai_service.py
chat_service.py
prompt_engine.py
quota_service.py
rate_limiter.py
safety_service.py
supabase_auth_service.py
```

Controles conhecidos incluem:

```text
JWT
quota
rate limiting
safety
prompt processing
```

A quota real deve ser controlada pelo backend.

Caches existentes no Flutter são utilizados para experiência de UI e não devem
ser considerados autoridade de segurança.

---

## 17. Estrutura desta documentação

```text
docs_architecture/
│
├── README.md
│
├── architecture/
│   ├── overview.md
│   ├── flutter.md
│   ├── backend.md
│   ├── supabase.md
│   ├── authentication.md
│   └── storage.md
│
├── modules/
│   ├── dashboard.md
│   ├── studio.md
│   ├── match.md
│   ├── networking.md
│   ├── chat-ai.md
│   ├── profile.md
│   ├── notifications.md
│   ├── storage.md
│   └── hub.md
│
├── database/
│   ├── overview.md
│   ├── tables.md
│   ├── relationships.md
│   ├── rls.md
│   ├── rpc.md
│   ├── triggers.md
│   └── storage.md
│
├── security/
│   ├── overview.md
│   ├── threat-model.md
│   ├── authentication.md
│   ├── authorization.md
│   ├── file-security.md
│   └── secrets.md
│
├── backend/
│   ├── overview.md
│   ├── api.md
│   ├── authentication.md
│   ├── ai-quota.md
│   └── deployment.md
│
├── flows/
│   ├── match-to-project.md
│   ├── project-files.md
│   ├── project-tasks.md
│   ├── creative-production.md
│   └── chat-ai.md
│
└── decisions/
    └── README.md
```

---

## 18. Como navegar pela documentação

Para entender o projeto pela primeira vez, a ordem recomendada é:

```text
README.md
    │
    ▼
architecture/overview.md
    │
    ├── flutter.md
    ├── backend.md
    ├── supabase.md
    ├── authentication.md
    └── storage.md
    │
    ▼
modules/
    │
    ▼
flows/
    │
    ▼
database/
    │
    ▼
security/
```

Para trabalhar especificamente em segurança:

```text
security/overview.md
        │
        ▼
security/threat-model.md
        │
        ├── authentication.md
        ├── authorization.md
        ├── file-security.md
        └── secrets.md
        │
        ▼
database/rls.md
        │
        ▼
database/rpc.md
        │
        ▼
database/storage.md
```

---

## 19. Estados utilizados nos documentos

Cada documento pode utilizar um dos seguintes estados:

### Verificado

Comportamento confirmado diretamente no código, configuração, banco ou execução.

### Parcialmente verificado

Parte do comportamento foi confirmada, mas existem pontos relevantes ainda não
auditados.

### Pendente

Área identificada, mas ainda sem evidência suficiente para documentação
definitiva.

### Histórico

Informação mantida apenas para explicar uma decisão ou implementação anterior.

---

## 20. Regra para novas informações

Antes de adicionar uma afirmação técnica importante:

```text
Existe evidência atual?
        │
        ├── SIM
        │    ↓
        │ documentar
        │
        └── NÃO
             ↓
       marcar como pendente
```

Nunca transformar suposição em arquitetura oficial.

---

## 21. Atualização da documentação

Mudanças arquiteturais relevantes devem atualizar a documentação no mesmo ciclo
da mudança.

Exemplos:

```text
nova tabela
nova RPC
nova Edge Function
nova policy
novo módulo
novo fluxo
mudança de autenticação
mudança de Storage
mudança de quota
nova integração externa
```

Pequenas alterações internas que não modificam o contrato ou a arquitetura não
precisam necessariamente gerar mudanças na documentação.

---

## 22. Definition of Done arquitetural

Para superfícies críticas, especialmente segurança, uma implementação não deve
ser considerada encerrada apenas porque funciona.

O objetivo é chegar a:

```text
implementação identificada
        +
regra documentada
        +
controle server-side
        +
teste positivo
        +
teste negativo
```

Exemplo:

```text
User A acessa seu próprio arquivo
        → permitido

User B tenta acessar o arquivo de A
        → negado

Anon tenta acessar o arquivo
        → negado
```

---

## 23. Pendências atuais

As principais áreas que ainda precisam de auditoria aprofundada incluem:

- inventário completo de RLS;
- revisão das funções `SECURITY DEFINER`;
- revisão dos grants das funções;
- Storage Policies;
- autorização das Edge Functions;
- regras completas de membership;
- concorrência em Match → Project;
- segurança de arquivos;
- armazenamento de secrets;
- autenticação por plataforma;
- testes negativos de autorização;
- Realtime;
- comportamento completo de Tasks;
- lifecycle de arquivos;
- hardening do backend;
- testes automatizados de segurança.

---

## 24. Princípio final

A documentação do Versin deve responder:

```text
O que existe?
Por que existe?
Onde está?
Quem pode acessar?
Como os componentes se comunicam?
Qual é a fonte de verdade?
O que acontece quando falha?
Como sabemos que está protegido?
```

Se uma dessas respostas ainda não for conhecida, isso deve aparecer como
pendência.

A documentação deve representar o sistema que existe hoje, e não o sistema que
imaginamos existir.
