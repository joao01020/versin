# Versin — Architecture Decision Records

> **Diretório:** `docs_architecture/decisions/`\
> **Tipo:** Architecture Decision Records (ADR)\
> **Status:** Ativo\
> **Última revisão:** 2026-08-24

---

## 1. Objetivo

Este diretório registra decisões arquiteturais importantes do Versin.

A documentação localizada em:

```text
architecture/
modules/
database/
backend/
security/
flows/
```

descreve principalmente **como o sistema funciona atualmente**.

Os documentos deste diretório possuem outro objetivo:

```text
registrar por que uma decisão foi tomada
```

Um ADR deve permitir que, no futuro, um desenvolvedor consiga responder:

```text
Qual problema existia?

Quais alternativas foram consideradas?

Qual solução foi escolhida?

Por que essa solução foi escolhida?

Quais consequências ela trouxe?

A decisão ainda continua válida?
```

---

## 2. Por que manter decisões arquiteturais

O código mostra:

```text
o que foi implementado
```

A documentação arquitetural mostra:

```text
como o sistema está organizado
```

Mas nenhum deles necessariamente explica:

```text
por que escolhemos fazer dessa forma
```

Essa informação é importante porque decisões aparentemente estranhas podem
existir por motivos que não são evidentes olhando apenas para o código.

Sem esse histórico, uma implementação pode ser removida ou alterada no futuro
sem que o desenvolvedor conheça o problema que ela originalmente resolvia.

---

## 3. O que deve virar um ADR

Nem toda alteração precisa de uma decisão arquitetural documentada.

Criar um ADR quando uma decisão:

- afeta múltiplos módulos;
- altera uma fronteira de segurança;
- muda a fonte de verdade de algum dado;
- introduz uma dependência importante;
- altera autenticação ou autorização;
- altera armazenamento de arquivos;
- altera banco ou modelo de dados significativamente;
- introduz uma nova camada de infraestrutura;
- modifica contratos entre Flutter, Supabase e backend;
- possui trade-offs relevantes;
- seria difícil entender apenas olhando o código;
- provavelmente será questionada novamente no futuro.

---

## 4. O que normalmente não precisa de ADR

Mudanças locais e facilmente reversíveis normalmente não precisam de ADR.

Exemplos:

```text
alteração de padding
mudança de cor
renomear variável
refatoração interna pequena
extração de Widget
mudança de ícone
correção simples de bug
formatação
```

A pergunta principal é:

```text
Um desenvolvedor daqui a um ano precisaria saber
por que escolhemos isso?
```

Se a resposta for não, provavelmente não precisa de ADR.

---

## 5. Estrutura

Os registros devem permanecer neste diretório:

```text
docs_architecture/
└── decisions/
    ├── README.md
    ├── ADR-001-<nome>.md
    ├── ADR-002-<nome>.md
    ├── ADR-003-<nome>.md
    └── ...
```

Exemplo:

```text
ADR-001-use-supabase-auth.md
ADR-002-private-project-files.md
ADR-003-server-side-ai-quota.md
```

Os exemplos acima demonstram apenas a convenção de nomes.

Eles não significam que essas decisões já foram formalmente registradas.

---

## 6. Numeração

Cada decisão recebe um número sequencial.

Formato:

```text
ADR-001
ADR-002
ADR-003
...
```

O número nunca deve ser reutilizado.

Mesmo que uma decisão seja posteriormente substituída, o ADR original deve
continuar existindo.

---

## 7. Nome dos arquivos

Utilizar:

```text
ADR-NNN-descricao-curta.md
```

Preferir:

```text
ADR-004-private-storage.md
```

em vez de:

```text
decisao-storage-nova-versao-final.md
```

O nome deve representar a decisão de forma curta.

---

## 8. Estados de uma decisão

Cada ADR deve possuir um estado.

Estados recomendados:

### Proposed

A decisão está sendo discutida.

```text
Status: Proposed
```

---

### Accepted

A decisão foi aprovada e representa a arquitetura atual.

```text
Status: Accepted
```

---

### Implemented

A decisão foi aceita e sua implementação principal já existe.

```text
Status: Implemented
```

---

### Deprecated

A decisão continua registrada, mas não é mais recomendada.

```text
Status: Deprecated
```

---

### Superseded

A decisão foi substituída por outro ADR.

```text
Status: Superseded by ADR-XXX
```

---

### Rejected

A proposta foi analisada, mas não adotada.

```text
Status: Rejected
```

Registrar decisões rejeitadas pode ser útil quando existe grande chance de a
mesma discussão reaparecer.

---

## 9. ADRs são imutáveis historicamente

Depois que uma decisão importante foi aceita, não devemos reescrever seu
contexto para fazer parecer que sempre soubemos o resultado.

Se a arquitetura mudar:

```text
ADR-003
   │
   │ decisão original
   ▼
Accepted
```

e depois surgir uma solução melhor:

```text
ADR-003
   │
   ▼
Superseded by ADR-009

ADR-009
   │
   ▼
Accepted
```

Isso preserva o histórico técnico.

Correções de:

```text
ortografia
links
formatação
```

podem ser feitas sem criar outro ADR.

---

## 10. Template oficial

Novos ADRs devem utilizar preferencialmente esta estrutura:

````markdown
# ADR-NNN — Título da decisão

> **Status:** Proposed **Data:** YYYY-MM-DD **Responsável:** Versin
> **Relacionado:** caminho/para/documentacao.md

---

## 1. Contexto

Descreva o problema que levou à decisão.

Explique apenas o necessário para entender por que uma decisão arquitetural
precisou ser tomada.

---

## 2. Problema

Qual problema concreto precisa ser resolvido?

```text
problema atual
    │
    ▼
impacto
    │
    ▼
necessidade de decisão
```
````

---

## 3. Restrições

Liste restrições relevantes.

Exemplos:

- segurança;
- custo;
- compatibilidade;
- Flutter multiplataforma;
- Supabase;
- performance;
- complexidade operacional.

---

## 4. Alternativas consideradas

### Alternativa A

Descrição.

Vantagens:

- ...

Desvantagens:

- ...

### Alternativa B

Descrição.

Vantagens:

- ...

Desvantagens:

- ...

---

## 5. Decisão

Descreva objetivamente a solução escolhida.

---

## 6. Motivos

Explique por que essa alternativa foi escolhida.

---

## 7. Consequências positivas

- ...
- ...
- ...

---

## 8. Consequências negativas

- ...
- ...
- ...

---

## 9. Riscos

- ...
- ...
- ...

---

## 10. Impacto de segurança

Descreva se a decisão altera:

```text
autenticação
autorização
RLS
secrets
arquivos
privacidade
rede
backend
```

Se não houver impacto relevante:

```text
Nenhum impacto de segurança relevante identificado.
```

---

## 11. Impacto na arquitetura

Liste os componentes afetados.

Exemplo:

```text
Flutter
   │
   ▼
Versin API
   │
   ▼
Supabase
```

---

## 12. Implementação

Liste os principais arquivos, módulos ou componentes envolvidos.

```text
lib/...
versin_api/...
supabase/...
```

Não reproduzir código inteiro.

---

## 13. Validação

Descreva como confirmar que a decisão foi implementada corretamente.

Exemplos:

```text
teste automatizado
teste de integração
consulta SQL
teste negativo de autorização
inspeção de logs
```

---

## 14. Documentação relacionada

```text
docs_architecture/...
```

---

## 15. Decisões relacionadas

```text
ADR-XXX
```

Se não houver:

```text
Nenhuma.
```

````
---

## 11. Decisões de segurança

Decisões relacionadas a segurança merecem atenção especial.

Exemplos de temas que podem exigir ADR:

```text
modelo de autorização de projetos
estratégia de Storage privado
signed URLs
armazenamento de API keys privadas
uso de SECURITY DEFINER
modelo de membership
autorização de Edge Functions
rate limiting
estratégia de sessão
````

Um ADR de segurança deve explicar não apenas a solução escolhida, mas também:

```text
qual ameaça ela reduz
qual risco continua existindo
onde o controle é aplicado
```

---

## 12. Decisão versus implementação

Um ADR não deve virar documentação detalhada de implementação.

Exemplo:

```text
ADR

"Arquivos privados serão acessados através de URLs
temporárias emitidas após autorização."
```

Enquanto:

```text
architecture/storage.md
security/file-security.md
flows/project-files.md
```

explicam como isso funciona tecnicamente.

---

## 13. Decisão versus regra de negócio

Nem toda regra de negócio é uma decisão arquitetural.

Exemplo:

```text
"Projeto possui status active."
```

é principalmente modelo/regra de domínio.

Já:

```text
"Membership de projeto será validado server-side
e não será confiado ao cliente Flutter."
```

é uma decisão arquitetural e de segurança.

---

## 14. Decisão versus documentação histórica

Não criar ADR retroativamente apenas porque determinada implementação já existe.

Antes de registrar uma decisão histórica, precisamos conseguir confirmar:

```text
contexto
motivo
alternativas ou restrições
decisão
```

Se só sabemos que determinada implementação existe hoje, ela pertence
inicialmente à documentação arquitetural.

---

## 15. Evidência

Quando uma decisão for reconstruída a partir do projeto atual, indicar isso.

Exemplo:

```text
Tipo: Reconstructed
```

E documentar somente fatos que possam ser sustentados pelo:

```text
código
banco
configuração
Git
issue
commit
teste
infraestrutura
```

Não inventar a justificativa original.

---

## 16. Relação com o código

Quando possível, ADRs devem apontar para os componentes principais afetados.

Exemplo:

```text
Flutter:
lib/modules/storage/

Backend:
versin_api/services/project_storage_service.py

Supabase:
supabase/functions/
```

Evitar referências a números de linha porque eles mudam frequentemente.

---

## 17. Relação com Git

Quando uma decisão for implementada através de uma mudança relevante, o commit
ou Pull Request pode mencionar:

```text
ADR-XXX
```

Exemplo:

```text
security: enforce project membership for storage (ADR-007)
```

Isso conecta:

```text
decisão
   │
   ▼
implementação
   │
   ▼
histórico Git
```

---

## 18. Índice de decisões

Quando os primeiros ADRs forem criados, manter uma tabela neste README.

Formato:

| ADR     | Decisão | Status   | Data |
| ------- | ------- | -------- | ---- |
| ADR-001 | ...     | Accepted | ...  |
| ADR-002 | ...     | Proposed | ...  |

No momento, nenhuma decisão deve ser adicionada à tabela apenas por inferência.

---

## 19. Decisões que provavelmente precisarão ser formalizadas

A auditoria atual já revelou temas que podem justificar ADRs no futuro.

Entre eles:

```text
modelo de autorização de projetos

arquivos privados e URLs temporárias

fonte de verdade da quota da IA

estratégia de Creative Production

Match → Project

modelo de membership

uso de RPC para operações atômicas

uso de SECURITY DEFINER

armazenamento de API keys privadas

estratégia de rate limiting
```

Esses itens são **candidatos a ADR**.

Eles ainda não devem ser tratados como decisões históricas formalizadas sem
validarmos contexto e motivação.

---

## 20. Processo para uma nova decisão

Fluxo recomendado:

```text
problema identificado
        │
        ▼
alternativas levantadas
        │
        ▼
ADR criado como Proposed
        │
        ▼
análise de trade-offs
        │
        ▼
decisão
    ┌───┴────┐
    ▼        ▼
Accepted   Rejected
    │
    ▼
implementação
    │
    ▼
Implemented
```

---

## 21. Quando substituir uma decisão

Uma decisão deve ser reconsiderada quando:

- suas premissas deixarem de existir;
- surgir risco de segurança relevante;
- a escala mudar significativamente;
- a infraestrutura mudar;
- a solução gerar complexidade excessiva;
- uma alternativa apresentar vantagem clara;
- requisitos do produto mudarem.

Nesse caso, criar um novo ADR.

Não apagar o antigo.

---

## 22. Revisão

ADRs não precisam ser revisados constantemente como documentação operacional.

Entretanto, durante mudanças arquiteturais, verificar se algum ADR existente:

```text
continua válido
foi parcialmente invalidado
precisa ser substituído
```

---

## 23. Princípios adotados

O sistema de decisões arquiteturais do Versin segue estes princípios:

```text
decisões importantes devem deixar rastros

contexto é tão importante quanto resultado

trade-offs devem ser explícitos

decisões antigas não devem ser apagadas

suposições não devem virar fatos históricos

segurança deve fazer parte da decisão

documentação deve permanecer próxima do código
```

---

## 24. Fonte de verdade

Para o estado atual do sistema:

```text
código + infraestrutura + banco
```

Para saber como o sistema funciona:

```text
docs_architecture/
```

Para saber por que uma decisão arquitetural foi tomada:

```text
docs_architecture/decisions/
```

Para saber como a implementação mudou ao longo do tempo:

```text
Git
```

Essas fontes se complementam.

---

## 25. Regra final

Um ADR deve ser curto o suficiente para ser lido, mas completo o suficiente para
impedir que a mesma discussão precise ser reconstruída do zero.

A pergunta que cada registro deve conseguir responder é:

```text
Por que o Versin funciona dessa maneira,
e quais consequências aceitamos ao escolher esse caminho?
```

Se ainda não sabemos a resposta com evidência suficiente, não devemos
inventá-la.

Registramos a pendência e investigamos primeiro.
