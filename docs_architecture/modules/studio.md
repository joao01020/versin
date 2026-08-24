# Versin — Módulo Studio

> **Status:** Parcialmente verificado no código\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/studio/`

---

## 1. Objetivo

Studio é o espaço de criação/composição do Versin.

O módulo mantém estado de uma sessão criativa e integra acontecimentos
relevantes com o sistema de produção criativa do Dashboard.

```text
Usuário
  │
  ▼
Studio
  │
  ├── edição
  ├── estado
  ├── modelos
  ├── serviços
  └── janelas/widgets
       │
       ▼
Creative Activity
       │
       ▼
Dashboard
```

---

## 2. Estrutura identificada

```text
lib/modules/studio/
├── controllers/
├── models/
├── services/
├── views/
├── widgets/
└── windows/
```

---

## 3. Arquivos confirmados

Foi trabalhado diretamente:

```text
lib/modules/studio/views/studio_page.dart
lib/modules/studio/controllers/studio_controller.dart
```

O controller é responsável pelo estado do Studio, enquanto a página coordena a
experiência visual e integra eventos de lifecycle.

---

## 4. Estado não salvo

O Studio Controller possui:

```text
hasUnsavedChanges
```

A página observa mudanças através de:

```text
controller.addListener(_handleStudioControllerChanged)
```

e remove o listener no encerramento:

```text
controller.removeListener(_handleStudioControllerChanged)
```

Isso permite reagir à transição do estado salvo/não salvo.

---

## 5. Detecção de início de atividade

A página mantém:

```text
_wasUnsaved
```

e compara o estado anterior com:

```text
controller.hasUnsavedChanges
```

A transição:

```text
sem alterações
      │
      ▼
possui alterações
```

é utilizada para reconhecer atividade de composição sem registrar eventos a cada
rebuild.

---

## 6. CreativeActivityService

`studio_page.dart` possui:

```dart
final CreativeActivityService _creativeActivityService =
    CreativeActivityService();
```

Esse service conecta o Studio ao domínio de produção criativa.

---

## 7. Composition Session

Existe o método:

```text
_registerCompositionSessionSafely()
```

responsável por registrar:

```text
composition_session
```

---

## 8. Best-effort analytics

O código documenta explicitamente o registro como:

```text
Best-effort
```

Com as seguintes propriedades:

- analytics não bloqueia o Studio;
- falha no Supabase não desfaz edição;
- cada sessão recebe `source_id` único;
- rebuilds não duplicam a métrica.

Essa separação é importante: telemetria/produção criativa não deve impedir o
trabalho do usuário.

---

## 9. Usuário autenticado

Antes do registro:

```text
_creativeActivityService.isAuthenticated
```

é verificado.

Sem autenticação, o evento é ignorado e registrado apenas em log de debug.

---

## 10. Proteção contra registro simultâneo

O método verifica:

```text
_isRegisteringCompositionSession
```

Se já existe um registro em andamento, retorna.

Depois:

```text
_isRegisteringCompositionSession = true
```

e no `finally`:

```text
_isRegisteringCompositionSession = false
```

Isso reduz duplicações durante a mesma execução do fluxo.

---

## 11. Sequence

A página mantém:

```text
_compositionSessionSequence
```

e incrementa:

```text
final sequence = ++_compositionSessionSequence;
```

Essa sequência participa da construção do identificador da sessão.

---

## 12. Session ID

O ID observado é construído como:

```text
studio_
+ startedAt.microsecondsSinceEpoch
+ sequence
```

Conceitualmente:

```text
studio_172..._1
```

Isso fornece uma origem distinta para cada sessão registrada pela página.

---

## 13. Timestamp

O início utiliza:

```dart
final startedAt = DateTime.now().toUtc();
```

O uso de UTC evita ambiguidade de timezone no evento persistido.

---

## 14. Metadata

O registro envia metadata contendo:

```text
origin: studio
started_at
studio_title
bpm
sequence
```

Esses dados enriquecem o evento sem transformar o Dashboard em dependente do
estado interno do Studio.

---

## 15. Registro

A chamada confirmada é:

```text
recordCompositionSession(
    sessionId: sessionId,
    metadata: ...
)
```

em:

```text
CreativeActivityService
```

---

## 16. Falha no registro

O método utiliza:

```text
try
catch
finally
```

Em falha:

- o erro é logado;
- o stack trace é logado;
- o Studio continua funcionando;
- a edição não é revertida.

Essa é uma decisão arquitetural correta para uma métrica secundária.

---

## 17. Idempotência no banco

A camada de produção criativa utiliza:

```text
creative_activity_events
```

com índice único:

```text
creative_activity_events_source_unique_idx
```

sobre:

```text
(user_id, event_type, source_id)
```

Portanto, além da proteção local, existe proteção de unicidade para a mesma
origem lógica.

---

## 18. Dashboard

O evento segue conceitualmente:

```text
Studio
   │
   ▼
composition_session
   │
   ▼
creative_activity_events
   │
   ▼
RPC/agregação mensal
   │
   ▼
CreativeProductionMonth
   │
   ▼
Dashboard
```

---

## 19. Métrica

No serviço de produção foi observado:

```text
compositionSessionWeight = 3.0
```

Assim, sessões de composição participam do cálculo do score criativo.

O Studio não deve calcular esse score diretamente.

---

## 20. Separação de responsabilidades

Preferir:

```text
Studio
  └── produz evento

CreativeActivityService
  └── registra evento

CreativeProductionService
  └── calcula produção

Dashboard
  └── apresenta
```

Evitar:

```text
Studio
  └── altera diretamente números do gráfico
```

---

## 21. Controller

`studio_controller.dart` mantém a lógica e estado do Studio.

Um comentário já observado no arquivo indica que o controller não deve assumir
diretamente a responsabilidade de `CreativeActivityService`.

Essa separação mantém analytics fora da regra principal de edição.

---

## 22. Dados da composição

Pelo trecho auditado, o Studio expõe ao evento pelo menos:

```text
title
bpm
```

O inventário completo dos modelos de composição ainda precisa ser feito antes de
documentar todos os campos suportados.

---

## 23. Windows

Existe:

```text
lib/modules/studio/windows/
```

Essa pasta indica componentes/janelas específicas do Studio.

A responsabilidade exata ainda precisa ser levantada arquivo por arquivo.

---

## 24. Segurança

Dados de analytics não devem permitir:

- registrar atividade para outro usuário;
- escolher arbitrariamente `user_id`;
- inflar métricas reutilizando payloads diferentes sem regra;
- modificar agregados diretamente pelo cliente.

A identidade confiável deve vir da sessão autenticada.

---

## 25. Privacidade

Metadata de analytics deve ser mínima.

Campos como:

```text
studio_title
bpm
```

devem existir porque têm valor real para o produto, não apenas porque estão
disponíveis no controller.

Evitar armazenar conteúdo criativo completo em eventos analíticos sem
necessidade.

---

## 26. Concorrência

Existem duas camadas de proteção observadas:

```text
Flutter:
_isRegisteringCompositionSession

Banco:
unique(user_id, event_type, source_id)
```

Elas resolvem problemas diferentes e são complementares.

---

## 27. Dependências

```text
Studio
├── StudioController
├── CreativeActivityService
├── Supabase
└── Dashboard / Creative Production
```

---

## 28. Documentação relacionada

```text
docs_architecture/modules/dashboard.md
docs_architecture/flows/creative-production.md
docs_architecture/database/tables.md
docs_architecture/database/rpc.md
```

---

## 29. Pendências

Ainda precisamos documentar:

- modelos completos;
- services do Studio;
- persistência da composição;
- fluxo de salvar;
- autosave, se existente;
- recuperação;
- windows;
- widgets;
- ciclo exato de início/fim da sessão;
- testes de duplicidade;
- tratamento offline;
- critérios finais para registrar uma `composition_session`.
