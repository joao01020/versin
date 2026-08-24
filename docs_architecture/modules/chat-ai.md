# Versin — Módulo Chat & AI

> **Status:** Parcialmente verificado no código e em execução\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/chat/` + integração com `versin_api/`

---

## 1. Objetivo

O módulo de Chat & AI concentra a experiência de conversa e os recursos de
inteligência artificial do Versin.

A arquitetura não coloca toda a responsabilidade no Flutter. O cliente coordena
a experiência, enquanto operações sensíveis da IA Versin são processadas pelo
backend próprio.

```text
Flutter
   │
   ▼
Chat
   │
   ├── estado/conversas
   ├── UI
   └── requisições
        │
        ▼
Versin API
   │
   ├── autenticação
   ├── rate limit
   ├── quota
   ├── safety
   ├── prompt
   └── provider de IA
```

---

## 2. Estrutura Flutter identificada

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

Essa divisão mostra que o módulo possui responsabilidades além de uma única tela
de chat.

---

## 3. Responsabilidades

O domínio inclui, em alto nível:

- interface de conversa;
- gerenciamento de mensagens;
- integração com IA;
- serviços de Chat;
- modelos;
- vocabulário;
- recursos de rimas;
- persistência/consulta de dados;
- integração com quota da IA.

---

## 4. Backend da IA Versin

O backend próprio está localizado em:

```text
versin_api/
```

Services identificados:

```text
versin_api/services/
├── ai_service.py
├── chat_service.py
├── prompt_engine.py
├── quota_service.py
├── rate_limiter.py
├── safety_service.py
└── supabase_auth_service.py
```

A rota identificada está em:

```text
versin_api/routes/chat_route.py
```

---

## 5. Fluxo de geração

Arquiteturalmente:

```text
Usuário
  │
  ▼
Flutter Chat
  │
  ▼
Versin API
  │
  ├── valida identidade
  ├── valida entrada
  ├── aplica rate limit
  ├── verifica quota
  ├── prepara prompt
  ├── chama provider
  └── processa resposta
  │
  ▼
Flutter
```

A ordem exata das chamadas internas deve continuar alinhada ao código real do
backend.

---

## 6. Provider da IA

O projeto possui uma camada de provider que permite distinguir entre:

```text
Versin API
API privada configurada pelo usuário
```

No código já trabalhado existe o conceito:

```text
AiProviderSource.versin
AiProviderSource.privateApi
```

e um resultado padronizado contendo:

```text
content
source
provider
model
```

Essa separação é importante para determinar quando o consumo deve ou não contar
contra a quota Versin.

---

## 7. API privada

Quando uma API privada está configurada, o fluxo pode utilizar dados como:

```text
provider
apiKey
model
baseUrl
```

Credenciais privadas não devem ser impressas em logs.

A responsabilidade por armazenamento seguro e ciclo de vida dessas credenciais
deve ser tratada na documentação de segurança.

---

## 8. Quota da IA Versin

A quota é controlada no backend.

Endpoint confirmado em execução:

```text
GET /chat/quota/{user_id}
```

Logs do Flutter confirmaram recebimento de:

```text
tokens usados
tokens restantes
limite
```

O backend também fornece metadata de período/renovação e estado global.

---

## 9. Quota individual e global

O sistema possui duas dimensões:

```text
quota individual mensal
+
quota global diária
```

O uso da IA depende de ambas permitirem a operação.

O Flutter pode representar visualmente a quota, mas não deve ser a fonte de
verdade.

---

## 10. Cache de quota

Foi observado no Flutter:

```text
[AI QUOTA CACHE]
```

com persistência local da quota para o usuário atual.

Esse cache melhora a experiência, mas não substitui a consulta e validação
server-side.

---

## 11. Rate limiting

O backend possui:

```text
versin_api/services/rate_limiter.py
```

Características já verificadas:

```text
Redis
janela padrão de 60 segundos
limite por usuário
HTTP 429
Retry-After
```

Rate limit e quota são mecanismos diferentes:

```text
quota      → volume permitido
rate limit → frequência permitida
```

---

## 12. Safety

O backend possui:

```text
versin_api/services/safety_service.py
```

A camada já foi identificada como responsável por validação/sanitização de
entrada e tratamento de segurança relacionado ao fluxo da IA.

O limite de entrada observado no backend é:

```text
12.000 caracteres
```

A implementação atual também identifica padrões simples relacionados a prompt
injection.

---

## 13. Autenticação

O backend possui:

```text
supabase_auth_service.py
```

A identidade confiável deve vir da sessão/JWT validado.

O backend não deve considerar um `user_id` enviado pelo cliente como prova
suficiente de identidade.

---

## 14. Chat de projeto versus Chat & AI

O Versin possui mais de um contexto de comunicação.

O módulo:

```text
lib/modules/chat/
```

não deve ser confundido automaticamente com:

```text
lib/modules/networking/chat/
```

O segundo pertence ao domínio colaborativo/networking de projetos.

Essa separação deve ser preservada para evitar acoplamento entre IA e
comunicação de projeto.

---

## 15. Áudio no chat de projeto

O projeto também possui trabalho relacionado a gravação de áudio em:

```text
project_messages
```

Foi observada uma constraint de conteúdo e uma distinção entre mensagens
textuais e mensagens com `audio_path`.

Esse fluxo pertence principalmente ao domínio de networking/chat de projeto e
não deve ser tratado como parte obrigatória da IA.

---

## 16. Falhas

Falhas de:

- provider;
- Redis;
- quota;
- autenticação;
- rede;

devem ser tratadas sem transformar o cliente em autoridade.

O rate limiter possui comportamento `fail-open` quando Redis está indisponível,
conforme auditoria anterior.

---

## 17. Segurança

Não devem existir no Flutter:

```text
service_role
segredos do backend
credenciais administrativas
regras de quota confiadas somente ao cliente
```

API keys privadas fornecidas pelo usuário exigem tratamento separado e nunca
devem aparecer em logs.

---

## 18. Arquivos relacionados

```text
lib/modules/chat/
versin_api/routes/chat_route.py
versin_api/services/chat_service.py
versin_api/services/ai_service.py
versin_api/services/prompt_engine.py
versin_api/services/quota_service.py
versin_api/services/rate_limiter.py
versin_api/services/safety_service.py
versin_api/services/supabase_auth_service.py
```

---

## 19. Documentação relacionada

```text
docs_architecture/backend/api.md
docs_architecture/backend/ai-quota.md
docs_architecture/backend/authentication.md
docs_architecture/flows/chat-ai.md
docs_architecture/security/secrets.md
```

---

## 20. Pendências

Ainda precisamos inventariar:

- controllers/services Flutter completos;
- endpoints completos do Chat;
- request/response schemas;
- persistência das conversas;
- política de retenção;
- tratamento completo de API privada;
- timeouts/retries;
- testes de autorização;
- comportamento de fallback entre providers.
