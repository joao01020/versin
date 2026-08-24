# Versin — Fluxo Chat & AI

> **Status:** Parcialmente verificado no código e em execução\
> **Última revisão:** 2026-08-24\
> **Escopo:** Flutter `lib/modules/chat/` + backend `versin_api/`

---

## 1. Objetivo

Este documento descreve o caminho de uma requisição de inteligência artificial
no Versin, separando claramente:

- cliente Flutter;
- autenticação;
- backend Versin;
- quota;
- rate limiting;
- safety;
- preparação de prompt;
- provider;
- resposta ao cliente.

O Flutter coordena a experiência, mas não deve ser a autoridade para controles
sensíveis.

---

## 2. Visão geral

```text
Usuário
  │
  ▼
Flutter / Chat
  │
  ▼
requisição autenticada
  │
  ▼
Versin API
  │
  ├── autenticação
  ├── validação
  ├── rate limit
  ├── quota
  ├── safety
  ├── prompt engine
  └── provider de IA
  │
  ▼
resposta
  │
  ▼
Flutter
```

---

## 3. Componentes conhecidos

### Flutter

```text
lib/modules/chat/
├── ai/
├── conversation/
├── data/
├── domain/
├── models/
├── rhymes/
├── services/
├── views/
└── vocabulary/
```

### Backend

```text
versin_api/routes/chat_route.py

versin_api/services/
├── ai_service.py
├── chat_service.py
├── prompt_engine.py
├── quota_service.py
├── rate_limiter.py
├── safety_service.py
└── supabase_auth_service.py
```

---

## 4. Início da requisição

O usuário envia uma entrada através da interface do Chat.

O cliente prepara a requisição e utiliza a sessão autenticada.

O cliente não deve possuir:

```text
service_role
segredos administrativos
autoridade final de quota
autoridade final de rate limit
```

---

## 5. Autenticação

O backend possui:

```text
supabase_auth_service.py
```

A identidade confiável deve ser derivada do JWT/sessão validada.

Regra:

```text
user_id informado pelo cliente
        !=
prova de identidade
```

Sempre que a operação depende do usuário atual, o backend deve relacioná-la à
identidade autenticada.

---

## 6. Validação da entrada

O backend possui:

```text
safety_service.py
```

Durante a auditoria foi identificado limite de entrada de aproximadamente:

```text
12.000 caracteres
```

Também existem verificações relacionadas a padrões simples de prompt injection.

Essas verificações são uma camada de proteção, não uma garantia absoluta contra
abuso.

---

## 7. Rate limiting

Existe:

```text
rate_limiter.py
```

A implementação auditada utiliza Redis e janela de limitação.

Conceitualmente:

```text
request
   │
   ▼
chave por usuário
   │
   ▼
contador / janela
   │
   ├── permitido
   │      ▼
   │   continua
   │
   └── excedido
          ▼
       HTTP 429
```

Foi observado uso de:

```text
Retry-After
```

quando o limite é excedido.

---

## 8. Falha do Redis

Na implementação auditada, o rate limiter possui comportamento `fail-open`
quando Redis fica indisponível.

Isso significa que indisponibilidade do Redis não necessariamente derruba o
Chat.

Esse comportamento deve permanecer uma decisão explícita de arquitetura, pois
troca disponibilidade por redução temporária da proteção de frequência.

---

## 9. Quota

Existe:

```text
quota_service.py
```

O backend controla a quota real.

O Flutter consulta e apresenta o estado, mas não deve ser responsável por
autorizar consumo.

Foram observadas duas dimensões:

```text
quota individual mensal
quota global diária
```

---

## 10. Consulta de quota

Endpoint confirmado em execução:

```text
GET /chat/quota/{user_id}
```

Logs do aplicativo confirmaram retorno com dados como:

```text
tokens usados
tokens restantes
limite
```

O endpoint e sua autorização devem permanecer alinhados ao usuário autenticado.

---

## 11. Cache no cliente

Foi observado:

```text
[AI QUOTA CACHE]
```

O cache local serve para experiência de UI.

Não deve ser usado como autoridade para decidir se uma chamada realmente pode
consumir IA.

---

## 12. Safety

Depois das validações necessárias, a camada de safety pode rejeitar ou sanitizar
entradas conforme as regras implementadas.

A ordem exata entre safety, quota e rate limit deve seguir o código atual do
backend; este documento registra as responsabilidades, não substitui a
implementação.

---

## 13. Prompt Engine

Existe:

```text
prompt_engine.py
```

Responsável pela preparação do contexto/prompt enviado ao provider.

Separar essa responsabilidade evita espalhar regras de prompt pelas rotas HTTP.

---

## 14. AI Service

Existe:

```text
ai_service.py
```

Essa camada encapsula a integração com o provider/modelo utilizado pelo backend
Versin.

Credenciais do provider devem existir somente em ambiente confiável.

---

## 15. Chat Service

Existe:

```text
chat_service.py
```

A responsabilidade detalhada precisa continuar alinhada ao código, mas ele
pertence à camada de serviço do fluxo de Chat.

---

## 16. Provider privado

O Flutter também possui arquitetura para distinguir:

```text
AiProviderSource.versin
AiProviderSource.privateApi
```

Quando uma API privada configurada pelo usuário é utilizada, o resultado informa
a origem da geração.

Isso é importante porque:

```text
Versin API
    → pode consumir quota Versin

API privada
    → não deve ser contabilizada como consumo da API Versin
```

A regra definitiva deve continuar implementada na camada apropriada.

---

## 17. Resultado padronizado

Foi trabalhado um resultado contendo:

```text
content
source
provider
model
```

Isso evita que a UI precise deduzir qual provider respondeu.

---

## 18. Resposta

Depois do processamento:

```text
provider
   │
   ▼
AI Service
   │
   ▼
Chat Service / Route
   │
   ▼
HTTP response
   │
   ▼
Flutter
```

O Flutter atualiza a experiência de conversa com o resultado.

---

## 19. Erros esperados

O fluxo deve tratar separadamente:

```text
401/403 → autenticação/autorização
429     → rate limit
quota   → limite de consumo
timeout → provider/rede
5xx     → backend/provider
entrada → validação/safety
```

Não transformar todos os erros em uma mensagem genérica quando o cliente pode
reagir de maneira útil.

---

## 20. Segurança

### Nunca confiar no cliente para

```text
definir sua própria quota
informar que já pagou consumo
escolher outro user_id
ignorar rate limit
enviar service_role
```

### Nunca registrar

```text
JWT completo
API key
service_role
segredo do provider
credenciais privadas do usuário
```

---

## 21. Observabilidade

Logs devem ajudar a responder:

```text
qual etapa falhou?
houve autenticação?
quota bloqueou?
rate limit bloqueou?
provider respondeu?
quanto tempo levou?
```

Sem expor conteúdo ou credenciais desnecessárias.

---

## 22. Fluxo resumido

```text
1. usuário envia mensagem
2. Flutter obtém sessão válida
3. requisição chega ao backend
4. backend valida identidade
5. entrada é validada
6. controles de frequência/consumo são aplicados
7. prompt é preparado
8. provider é chamado
9. resposta é processada
10. consumo aplicável é contabilizado
11. resposta retorna ao Flutter
12. UI atualiza conversa/quota
```

A posição exata da contabilização deve ser confirmada no backend para evitar
descontar chamadas que falharam antes do consumo real.

---

## 23. Arquivos relacionados

```text
lib/modules/chat/
versin_api/routes/chat_route.py
versin_api/services/ai_service.py
versin_api/services/chat_service.py
versin_api/services/prompt_engine.py
versin_api/services/quota_service.py
versin_api/services/rate_limiter.py
versin_api/services/safety_service.py
versin_api/services/supabase_auth_service.py
```

---

## 24. Documentação relacionada

```text
docs_architecture/modules/chat-ai.md
docs_architecture/backend/api.md
docs_architecture/backend/ai-quota.md
docs_architecture/backend/authentication.md
docs_architecture/security/secrets.md
```

---

## 25. Pendências

Ainda precisamos confirmar diretamente no código:

- endpoint exato de geração;
- schema completo de request;
- schema completo de response;
- ordem exata das validações;
- momento exato do desconto de quota;
- retries;
- timeout;
- persistência das conversas;
- fallback entre providers;
- tratamento de streaming, se existente;
- testes negativos de autenticação e quota.
