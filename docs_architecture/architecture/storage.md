# Versin — Arquitetura de Storage

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** Flutter + Supabase Edge Functions + armazenamento de arquivos

---

## 1. Objetivo

Este documento descreve a arquitetura de armazenamento de arquivos do Versin em
nível de sistema.

O projeto separa o armazenamento de dados relacionais do armazenamento de
arquivos.

```text
Flutter
   │
   ├── PostgreSQL / Supabase
   │       └── metadados e registros
   │
   └── fluxo de arquivos
           │
           ├── serviços Flutter
           ├── Edge Functions
           └── armazenamento externo
```

A implementação detalhada de buckets, policies e regras de acesso será mantida
em documentos específicos de banco e segurança.

---

## 2. Componentes Flutter

O módulo principal está localizado em:

```text
lib/modules/storage/
```

Estrutura identificada:

```text
lib/modules/storage/
├── controllers/
├── data/
├── services/
├── views/
└── widgets/
```

Também existem fluxos de arquivo dentro de outros domínios, especialmente:

```text
lib/modules/profile/public_profile/
lib/modules/networking/
lib/features/rhymes/
```

---

## 3. Serviços identificados

Entre os componentes já identificados está:

```text
lib/modules/storage/services/beat_storage_service.dart
```

Também existe repository Supabase relacionado ao módulo:

```text
lib/modules/storage/data/repositories/supabase_storage_repository.dart
```

Esses componentes fazem parte da camada Flutter que coordena operações de
armazenamento.

---

## 4. Edge Functions de arquivos

O repositório contém as seguintes Edge Functions:

```text
supabase/functions/
├── create-track-playback-url/
├── create-track-upload-url/
├── create-work-playback-url/
├── create-work-upload-url/
├── delete-profile-track/
└── delete-work-file/
```

Elas separam operações sensíveis de arquivo do cliente Flutter.

### Tracks

```text
create-track-upload-url
create-track-playback-url
delete-profile-track
```

### Works / obras armazenadas

```text
create-work-upload-url
create-work-playback-url
delete-work-file
```

---

## 5. Fluxo conceitual de upload

A arquitetura observada utiliza um fluxo intermediado em vez de depender somente
de upload direto irrestrito pelo cliente.

```text
Flutter
   │
   │ solicita autorização/URL
   ▼
Edge Function
   │
   │ valida contexto
   ▼
URL/operação autorizada
   │
   ▼
Flutter envia arquivo
   │
   ▼
Storage
```

Os detalhes exatos de autenticação e autorização de cada função ainda precisam
ser auditados individualmente.

---

## 6. Fluxo conceitual de playback

```text
Flutter
   │
   │ solicita acesso
   ▼
Edge Function
   │
   ▼
URL de playback autorizada
   │
   ▼
cliente acessa o arquivo
```

A existência de funções específicas de playback permite evitar a necessidade de
tornar arquivos privados permanentemente públicos.

---

## 7. Exclusão

Existem funções separadas para exclusão:

```text
delete-profile-track
delete-work-file
```

Operações destrutivas devem validar server-side:

- usuário autenticado;
- ownership ou permissão equivalente;
- identificação do recurso;
- relação entre registro e arquivo.

A confirmação de como cada uma dessas verificações está implementada será feita
na auditoria das Edge Functions.

---

## 8. Integridade de arquivo

O projeto já utiliza geração/verificação de hash em fluxos de arquivo.

SHA-256 é útil para:

- identificar conteúdo;
- verificar integridade;
- detectar alterações;
- evitar depender apenas do nome do arquivo.

Importante:

> Hash não fornece confidencialidade.

Um SHA-256 não criptografa o arquivo e não substitui autorização, storage
privado ou controle de acesso.

---

## 9. Metadados versus conteúdo

A arquitetura deve manter clara a separação:

```text
Banco
├── proprietário
├── projeto
├── metadata
├── hash
├── caminho/chave
├── timestamps
└── estado

Storage
└── bytes do arquivo
```

Isso evita armazenar blobs grandes diretamente nas tabelas de domínio quando não
for necessário.

---

## 10. Segurança

A segurança de arquivos deve ser aplicada em múltiplas camadas:

```text
Autenticação
      │
      ▼
Autorização
      │
      ▼
RPC / Edge Function / Policy
      │
      ▼
URL ou operação limitada
      │
      ▼
Arquivo
```

O cliente Flutter não deve decidir sozinho se um usuário pode acessar
determinado arquivo.

---

## 11. Project Storage

O backend próprio possui:

```text
versin_api/services/project_storage_service.py
```

Isso confirma que armazenamento relacionado a projetos também possui integração
no backend FastAPI.

A responsabilidade exata desse serviço e sua relação com Edge Functions deve ser
documentada após inspeção do arquivo.

---

## 12. Relação com projetos e entregas

O banco possui estruturas relacionadas a projetos e entregas.

Durante a auditoria foi confirmada a FK:

```text
delivery_approvals.delivery_id
        │
        └── contribution_deliveries.id
```

A tabela `delivery_approvals` estava vazia no momento da auditoria, mas não deve
ser tratada como removível somente por isso, pois possui relação estrutural no
banco.

---

## 13. Tabela `obras`

Durante a auditoria, a tabela:

```text
public.obras
```

apresentou até o momento:

- 0 registros;
- nenhuma referência direta encontrada no Flutter pesquisado;
- nenhum trigger encontrado;
- nenhuma referência encontrada nos corpos das funções `public`;
- nenhuma foreign key encontrada;
- nenhuma view/materialized view encontrada.

Ela permanece classificada como:

```text
provável legado — alta evidência
```

Não deve ser removida sem a etapa final de auditoria e uma migration
reversível/backup apropriado.

---

## 14. Fronteira de confiança

Nunca assumir:

```text
arquivo veio do app oficial
        =
arquivo é confiável
```

O servidor deve tratar nome, extensão, MIME, tamanho, identificadores e metadata
fornecidos pelo cliente como entrada não confiável.

---

## 15. Documentos relacionados

Detalhes complementares devem ficar em:

```text
docs_architecture/database/storage.md
docs_architecture/security/file-security.md
docs_architecture/flows/project-files.md
docs_architecture/modules/storage.md
```

Este arquivo permanece focado na visão arquitetural.

---

## 16. Pendências de auditoria

Ainda precisamos confirmar:

- provider físico usado para cada categoria de arquivo;
- buckets/containers existentes;
- visibilidade pública/privada;
- policies de Storage;
- tamanho máximo;
- MIME types permitidos;
- expiração de URLs;
- autorização das Edge Functions;
- estratégia de arquivos órfãos;
- atomicidade entre upload e registro no banco;
- comportamento de rollback;
- deduplicação por hash;
- retenção e exclusão;
- backup;
- criptografia em repouso oferecida pelo provider.
