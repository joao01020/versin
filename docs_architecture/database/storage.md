# Versin — Database Storage

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** dados de arquivo, Supabase/Edge Functions e relações no banco

---

## 1. Objetivo

Este documento descreve a parte de banco relacionada a arquivos.

A visão arquitetural geral está em:

```text
docs_architecture/architecture/storage.md
```

Aqui o foco é a relação entre registros persistentes, autorização e conteúdo
armazenado.

---

## 2. Separação entre banco e bytes

A arquitetura deve distinguir:

```text
PostgreSQL
├── IDs
├── owner
├── project
├── metadata
├── hash
├── storage key/path
├── status
└── timestamps

Storage
└── conteúdo binário
```

O banco representa identidade e relações do recurso; o provider de storage
mantém os bytes.

---

## 3. Hash

O projeto já utiliza SHA-256 em fluxos de arquivo.

Hash pode ser utilizado para:

- integridade;
- identificação de conteúdo;
- comparação;
- deduplicação, se a regra de negócio decidir.

Hash não fornece:

- criptografia;
- confidencialidade;
- autorização.

---

## 4. Edge Functions identificadas

```text
create-track-playback-url
create-track-upload-url
create-work-playback-url
create-work-upload-url
delete-profile-track
delete-work-file
```

Essas funções indicam que operações de arquivo não dependem apenas de acesso
irrestrito direto pelo Flutter.

---

## 5. Upload

Fluxo arquitetural esperado a partir dos componentes identificados:

```text
Flutter
   │
   ▼
solicita operação de upload
   │
   ▼
Edge Function
   │
   ▼
validação server-side
   │
   ▼
operação/URL autorizada
   │
   ▼
arquivo enviado ao storage
   │
   ▼
metadata persistida
```

A ordem exata e atomicidade ainda precisam ser verificadas no código das
funções.

---

## 6. Playback

Existem funções específicas:

```text
create-track-playback-url
create-work-playback-url
```

Isso permite uma arquitetura em que acesso ao arquivo pode ser concedido de
forma controlada sem exigir que o objeto seja permanentemente público.

A expiração exata dessas URLs ainda precisa ser auditada.

---

## 7. Delete

Existem:

```text
delete-profile-track
delete-work-file
```

Operações de delete precisam validar:

- autenticação;
- ownership/membership;
- registro alvo;
- chave/caminho real;
- relação entre registro e arquivo.

A implementação concreta ainda deve ser revisada antes de marcar esses controles
como confirmados.

---

## 8. Helper de autorização

Foi identificada a function:

```text
can_access_project_storage(...)
```

Ela faz parte da superfície de autorização de arquivos de projeto e deve ser
revisada junto com:

- grants;
- `SECURITY DEFINER`;
- `auth.uid()`;
- membership;
- RLS.

---

## 9. Backend próprio

Também existe:

```text
versin_api/services/project_storage_service.py
```

Isso mostra que parte do fluxo de storage relacionado a projetos possui
integração no backend FastAPI.

A divisão exata de responsabilidades entre:

```text
Flutter
Supabase
Edge Functions
Versin API
provider de storage
```

ainda precisa ser consolidada.

---

## 10. Entregas

Foi confirmada a relação:

```text
delivery_approvals.delivery_id
    → contribution_deliveries.id
```

Portanto, registros de aprovação fazem parte estruturalmente do domínio de
entregas, mesmo que a tabela estivesse vazia no snapshot auditado.

---

## 11. `obras`

A tabela:

```text
public.obras
```

foi investigada como possível legado.

Até o momento:

- 0 registros;
- sem uso encontrado no código pesquisado;
- sem triggers;
- sem referência encontrada em functions `public` pesquisadas;
- sem foreign keys;
- sem views/materialized views.

Classificação:

```text
provável legado — alta evidência
```

Não remover sem migration/backup e verificação final.

---

## 12. RLS e arquivos

Se metadata de arquivo é exposta pela Data API, RLS precisa proteger os
registros.

Acesso aos bytes e acesso ao registro são controles diferentes.

```text
pode ler metadata?
        │
        └── RLS / banco

pode obter/baixar arquivo?
        │
        └── Storage / Edge Function / backend
```

Ambos precisam estar coerentes.

---

## 13. Arquivos órfãos

Uma falha entre upload e persistência pode criar:

```text
arquivo sem registro
```

Uma falha entre remoção do registro e remoção do objeto pode criar:

```text
registro sem arquivo
```

A estratégia atual de reconciliação ainda não foi auditada.

---

## 14. Segurança de entrada

Nunca confiar somente em:

- filename;
- extensão;
- MIME enviado pelo cliente;
- tamanho declarado;
- path informado pelo Flutter;
- hash informado pelo cliente.

Quando relevante, o servidor deve validar/recalcular propriedades críticas.

---

## 15. Pendências

Precisamos confirmar:

- provider físico por categoria;
- buckets/containers;
- policies de Storage;
- público versus privado;
- limites de tamanho;
- MIME permitido;
- expiração de URLs;
- cálculo server-side de hash;
- atomicidade;
- limpeza de órfãos;
- retenção;
- backup;
- criptografia em repouso do provider.
