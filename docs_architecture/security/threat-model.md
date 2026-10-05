# Versin — Threat Model

> **Status:** Primeira versão operacional\
> **Última revisão:** 2026-08-24\
> **Método:** análise por ativos, fronteiras de confiança e cenários de abuso

---

## 1. Objetivo

Este threat model identifica os principais riscos técnicos do Versin.

Ele não tenta provar que o sistema está seguro.

Serve para orientar:

```text
auditoria
hardening
testes
priorização
decisões arquiteturais
```

---

## 2. Ativos

Ativos relevantes incluem:

```text
contas
sessões
perfis
projetos
membership
mensagens
áudios
arquivos criativos
tracks
tarefas
royalties
convites
notificações
dados de Match
quota de IA
API keys privadas
secrets de infraestrutura
```

---

## 3. Atores

### Usuário legítimo

Utiliza recursos autorizados.

### Usuário malicioso autenticado

Possui conta válida, mas tenta acessar recursos de terceiros.

### Atacante anônimo

Não possui sessão válida.

### Cliente modificado

Altera Flutter/requests e ignora regras da UI.

### Credencial comprometida

Atacante possui token ou secret válido.

### Serviço externo comprometido

Provider, Redis, storage ou outra dependência apresenta comportamento adverso.

---

## 4. Fronteiras de confiança

```text
[ dispositivo do usuário ]
          │
          │ NÃO CONFIÁVEL
          ▼
[ Supabase / Versin API ]
          │
          │ CONTROLADO
          ▼
[ DB / Storage / Redis / providers ]
```

Tudo que cruza a primeira fronteira deve ser validado.

---

## 5. Superfícies de ataque

```text
Supabase REST
Supabase RPC
Realtime
Storage
Edge Functions
FastAPI
Auth
uploads
signed URLs
Flutter Web
Redis-backed rate limit
provider de IA
```

---

## 6. T1 — IDOR/BOLA

### Cenário

Usuário A troca:

```text
project_id
file_id
notification_id
user_id
invitation_id
```

por um ID de B.

### Impacto

```text
leitura privada
alteração
delete
vazamento de arquivos
```

### Controles

```text
RLS
auth.uid()
membership server-side
Edge Function authorization
backend authorization
testes negativos
```

### Prioridade

**Crítica.**

---

## 7. T2 — RPC privilegiada

### Cenário

Uma `SECURITY DEFINER` aceita IDs controlados pelo cliente e executa operação
sem validar o usuário.

### Evidência de superfície

Foram encontradas:

```text
34 funções public SECURITY DEFINER
```

### Impacto

Pode ocorrer bypass de RLS e escalada de privilégio.

### Controles

```text
auditar corpo
auth.uid()
search_path fixo
grants mínimos
owner apropriado
argumentos validados
```

### Prioridade

**Crítica.**

---

## 8. T3 — Policies excessivamente permissivas

### Cenário

Policy utiliza condição ampla, por exemplo uma expressão equivalente a permitir
qualquer linha para `anon` ou `authenticated`.

### Impacto

Exposição ou alteração em massa.

### Controles

```text
inventário de RLS
matriz de roles
testes com A/B/anon
default deny
```

### Prioridade

**Crítica.**

---

## 9. T4 — Manipulação de membership

### Cenário

Cliente cria/atualiza projeto incluindo usuários arbitrários em:

```text
members
founders
```

### Impacto

Acesso indevido, falsificação de colaboração e autorização indireta.

### Controles

```text
RPC transacional
WITH CHECK
campos protegidos
validação server-side
```

### Prioridade

**Alta.**

---

## 10. T5 — Arquivo privado exposto

### Cenário

Bucket/path é público ou uma função emite playback sem validar acesso.

### Impacto

Vazamento de propriedade criativa.

### Controles

```text
private by default
signed URLs
TTL curto
membership
Storage policies
```

### Prioridade

**Crítica.**

---

## 11. T6 — Delete arbitrário de arquivo

### Cenário

Atacante envia path/file ID de outro usuário para:

```text
delete-profile-track
delete-work-file
```

### Impacto

Perda de dados.

### Controles

```text
derivar recurso server-side
validar owner/membership
não confiar em path
audit log
backup
```

### Prioridade

**Crítica.**

---

## 12. T7 — Secret no Flutter/Git

### Cenário

`service_role`, provider key ou Redis credential é incluído em:

```text
lib/
assets/
.env versionado
build
logs
```

### Impacto

Comprometimento amplo de infraestrutura.

### Controles

```text
secret scanning
gitignore
server-side secrets
rotação
least privilege
```

### Prioridade

**Crítica.**

---

## 13. T8 — Roubo de sessão

### Cenário

JWT/refresh token é obtido por malware, log, armazenamento inseguro ou XSS no
Web.

### Impacto

Impersonação do usuário.

### Controles

```text
armazenamento apropriado
não logar tokens
expiração
revogação
proteção Web
```

### Prioridade

**Alta.**

---

## 14. T9 — Endpoint confia em `user_id`

### Cenário

Endpoint como:

```text
/chat/quota/{user_id}
```

usa o path como identidade sem comparar com o JWT.

### Impacto

Leitura ou manipulação de dados de outro usuário.

### Controles

```text
JWT como identidade
comparação explícita
ou remover user_id quando desnecessário
```

### Prioridade

**Alta até auditoria confirmar proteção.**

---

## 15. T10 — Abuso da IA

### Cenário

Atacante automatiza chamadas para consumir quota/custos.

### Controles existentes

```text
quota
rate limiting
autenticação
safety
```

### Risco residual

O rate limiter auditado usa `fail-open` se Redis falhar.

### Prioridade

**Alta.**

---

## 16. T11 — Prompt injection

### Cenário

Entrada tenta alterar instruções ou manipular comportamento do sistema.

### Controles conhecidos

```text
safety_service.py
limite de entrada
detecção simples
prompt_engine.py
```

### Observação

Detecção textual simples não deve ser considerada defesa completa.

### Prioridade

**Média/Alta**, dependendo das ferramentas/dados disponíveis à IA.

---

## 17. T12 — Falsificação de Creative Production

### Cenário

Cliente registra eventos artificiais para aumentar score.

### Controle existente

```text
unique(user_id, event_type, source_id)
```

Isso evita duplicação da mesma origem, mas não prova que o evento é legítimo.

### Controles adicionais

```text
identidade server-side
eventos derivados de ações reais
restrição por tipo
RPCs específicas
```

### Prioridade

**Média**, maior se score ganhar valor econômico/social.

---

## 18. T13 — Race Match → Project

### Cenário

Dois clientes executam simultaneamente:

```text
SELECT inexistente
INSERT
```

### Impacto

Projetos duplicados e estado inconsistente.

### Controles

```text
constraint
RPC transacional
get-or-create atômico
```

### Prioridade

**Média/Alta.**

---

## 19. T14 — Race em convite/recrutamento

### Cenário

Duas operações alteram o mesmo estado simultaneamente.

### Impacto

Transições inválidas, membership duplicado ou inconsistência.

### Controles

```text
transação
estado esperado
constraint
RPC atômica
```

### Prioridade

**Alta** para operações de membership.

---

## 20. T15 — Realtime data leak

### Cenário

Subscription recebe linhas que o usuário não deveria observar.

### Controles

```text
RLS
filtros
policies corretas
testes com usuários diferentes
```

### Prioridade

**Alta.**

---

## 21. T16 — Upload malicioso

### Cenário

Usuário envia conteúdo com extensão/MIME falso, arquivo enorme ou conteúdo
ativo.

### Impacto

DoS, custo, exploração de consumidores ou XSS em contexto web.

### Controles

```text
size limit
MIME validation
Content-Disposition
private storage
scanning quando necessário
```

### Prioridade

**Alta.**

---

## 22. T17 — Signed URL vazada

### Cenário

URL aparece em log, analytics ou é compartilhada.

### Impacto

Acesso temporário sem nova autenticação.

### Controles

```text
TTL limitado
não logar URL
emitir somente após autorização
```

### Prioridade

**Média/Alta.**

---

## 23. T18 — Mass assignment

### Cenário

Cliente envia campos adicionais durante INSERT/UPDATE.

### Impacto

Alteração de:

```text
owner
role
status
members
flags internos
```

### Controles

```text
WITH CHECK
RPC específica
DTO/schema allowlist
campos imutáveis
```

### Prioridade

**Alta.**

---

## 24. T19 — Dados órfãos de Storage

### Cenário

Falha parcial deixa:

```text
objeto sem DB
DB sem objeto
```

### Impacto

vazamento, custo, arquivos quebrados.

### Controles

```text
reconciliação
cleanup
operações idempotentes
estado de upload
```

### Prioridade

**Média.**

---

## 25. T20 — Dependência externa indisponível

Dependências:

```text
Supabase
Redis
Render/backend
provider de IA
storage
```

Falhas podem causar indisponibilidade ou degradação de proteção.

Controles:

```text
timeouts
retries limitados
circuit breaker quando necessário
monitoramento
fallback explícito
```

---

## 26. Matriz resumida

| Ameaça                            | Prioridade       |
| --------------------------------- | ---------------- |
| IDOR/BOLA                         | Crítica          |
| SECURITY DEFINER insegura         | Crítica          |
| RLS permissiva                    | Crítica          |
| arquivo privado exposto           | Crítica          |
| delete arbitrário                 | Crítica          |
| secret exposto                    | Crítica          |
| membership manipulado             | Alta             |
| sessão comprometida               | Alta             |
| quota por user_id sem autorização | Alta até revisão |
| abuso de IA                       | Alta             |
| Realtime leak                     | Alta             |
| mass assignment                   | Alta             |
| upload malicioso                  | Alta             |
| concorrência Match/Project        | Média/Alta       |
| Creative Production forjada       | Média            |
| dados órfãos                      | Média            |

---

## 27. Plano de validação

### Fase 1 — Inventário

```text
tables
RLS
functions
grants
Storage
Edge Functions
API endpoints
secrets
```

### Fase 2 — Testes de identidade

Criar cenários:

```text
anon
user A
user B
```

### Fase 3 — Testes de autorização

Para cada recurso:

```text
A tenta recurso de B
B tenta projeto de A
ex-membro tenta arquivo
anon tenta RPC
```

### Fase 4 — Hardening

Corrigir:

```text
policies
grants
functions
paths
validation
secrets
```

### Fase 5 — Regressão

Transformar casos importantes em testes automatizados.

---

## 28. O que não fazer durante a auditoria

Evitar "corrigir" temporariamente com:

```text
USING (true)
WITH CHECK (true)
desabilitar RLS
dar EXECUTE amplo
usar service_role no Flutter
tornar bucket público
```

Isso pode fazer a feature funcionar enquanto remove a proteção que deveria ser
testada.

---

## 29. Critério de encerramento

Uma superfície só deve sair da lista de risco quando tivermos:

```text
implementação identificada
regra documentada
controle server-side
teste positivo
teste negativo
```

---

## 30. Documentação relacionada

```text
docs_architecture/security/overview.md
docs_architecture/security/authentication.md
docs_architecture/security/authorization.md
docs_architecture/security/file-security.md
docs_architecture/security/secrets.md
docs_architecture/database/rls.md
docs_architecture/database/rpc.md
```

---

## 31. Próximos pontos de auditoria

Prioridade prática:

```text
1. revisar secrets reais sem expor valores
2. fechar inventário de RLS
3. revisar as 34 SECURITY DEFINER
4. revisar grants para anon/authenticated
5. revisar Storage policies
6. revisar Edge Functions de arquivo
7. testar A × B × anon
8. revisar autorização do backend
9. automatizar regressões
```
