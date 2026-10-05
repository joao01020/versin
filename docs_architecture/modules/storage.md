# Versin — Módulo Storage

> **Status:** Parcialmente verificado no código\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/storage/`

---

## 1. Objetivo

O módulo Storage concentra fluxos de armazenamento utilizados pelo aplicativo
Versin.

A arquitetura separa:

```text
interface Flutter
dados/metadados
autorização
operação de arquivo
conteúdo binário
```

Essa separação é importante para segurança e manutenção.

---

## 2. Estrutura identificada

```text
lib/modules/storage/
├── controllers/
├── data/
├── services/
├── views/
└── widgets/
```

---

## 3. Componentes identificados

Foram encontrados:

```text
lib/modules/storage/services/beat_storage_service.dart
lib/modules/storage/data/repositories/supabase_storage_repository.dart
```

Esses componentes participam de operações de armazenamento.

---

## 4. Edge Functions relacionadas

Na estrutura Supabase existem:

```text
create-track-upload-url
create-track-playback-url
create-work-upload-url
create-work-playback-url
delete-profile-track
delete-work-file
```

O módulo Storage e outros domínios utilizam funções server-side para controlar
operações sensíveis.

---

## 5. Beat Storage Service

Foi identificado:

```text
beat_storage_service.dart
```

com chamadas:

```text
_supabase.functions.invoke(...)
```

A lista exata de Edge Functions chamadas por esse service deve ser documentada
diretamente do arquivo quando fizermos a auditoria específica.

---

## 6. Supabase Storage Repository

Foi identificado:

```text
supabase_storage_repository.dart
```

e uso de:

```text
_supabase.rpc(...)
```

Isso mostra que o fluxo de storage também depende de lógica PostgreSQL/RPC, e
não apenas de upload de objetos.

---

## 7. Arquivo e metadata

Um arquivo deve ser tratado como duas partes:

```text
Registro
├── identidade
├── owner/projeto
├── hash
├── metadata
├── storage key
└── timestamps

Objeto
└── bytes
```

A consistência entre essas duas partes precisa ser mantida.

---

## 8. Hash

O projeto utiliza hash SHA-256 em fluxos de arquivo.

Hash é útil para:

```text
integridade
identificação
comparação
eventual deduplicação
```

Mas:

```text
hash != criptografia
hash != autorização
hash != confidencialidade
```

Conhecer o hash de um arquivo não deve conceder acesso ao arquivo.

---

## 9. Upload

Arquiteturalmente, o fluxo deve manter autorização fora do cliente:

```text
Flutter
   │
   ▼
solicita upload
   │
   ▼
camada autorizadora
   │
   ▼
URL/operação permitida
   │
   ▼
Storage
```

A implementação exata por categoria de arquivo ainda precisa ser mapeada.

---

## 10. Playback

Existem funções específicas para playback:

```text
create-track-playback-url
create-work-playback-url
```

Esse desenho permite que objetos privados sejam acessados por mecanismos
temporários/controlados.

Ainda precisamos confirmar:

- expiração;
- escopo;
- provider;
- cache;
- reutilização da URL.

---

## 11. Delete

Existem:

```text
delete-profile-track
delete-work-file
```

Delete precisa manter consistência entre:

```text
registro no banco
+
objeto no storage
```

Também deve validar ownership/membership no lado confiável.

---

## 12. Storage de projeto

Foi identificada function:

```text
can_access_project_storage(...)
```

e também:

```text
versin_api/services/project_storage_service.py
```

Isso mostra que o acesso a arquivos de projeto possui regras relacionadas a
membership/autorização.

---

## 13. Networking

Networking utiliza arquivos dentro do contexto de projetos.

Atividades de arquivo também podem alimentar a produção criativa através de:

```text
files_added
```

O registro analítico deve ser idempotente e não depender de rebuild da UI.

---

## 14. Profile

O perfil público possui:

```text
ProfileTrackService
```

e Edge Functions próprias para track.

Portanto, o módulo Storage não deve absorver automaticamente todas as regras
específicas do Profile.

Preferir:

```text
Storage → infraestrutura compartilhada
Profile → regra do track de perfil
Networking → regra do arquivo de projeto
```

---

## 15. Segurança de arquivos

Nunca confiar apenas em:

```text
filename
extensão
MIME do cliente
path
userId
projectId
hash fornecido pelo cliente
```

Dados críticos devem ser validados no lado confiável.

---

## 16. URLs assinadas/temporárias

Quando URLs temporárias forem utilizadas:

- expiração deve ser limitada;
- autorização deve ocorrer antes da emissão;
- path deve ser derivado/validado;
- a URL não deve virar identificador permanente do recurso.

---

## 17. Arquivos órfãos

Dois estados problemáticos precisam ser considerados:

```text
objeto existe
registro não existe
```

e:

```text
registro existe
objeto não existe
```

A estratégia atual de reconciliação/cleanup ainda precisa ser auditada.

---

## 18. Integridade

Se SHA-256 é parte da regra de integridade, precisamos confirmar onde ele é
calculado:

```text
cliente?
servidor?
ambos?
```

Para uma garantia de segurança forte, não basta confiar cegamente em um hash
declarado pelo cliente.

---

## 19. Limites

Ainda precisamos confirmar:

- tamanho máximo;
- tipos permitidos;
- extensão;
- MIME;
- quotas de armazenamento;
- quantidade de arquivos;
- nomes;
- tempo de retenção.

---

## 20. Dependências

```text
Storage
├── Supabase
├── Edge Functions
├── PostgreSQL
├── Profile
├── Networking
├── Versin API
└── provider físico de objetos
```

---

## 21. Documentação relacionada

```text
docs_architecture/architecture/storage.md
docs_architecture/database/storage.md
docs_architecture/security/file-security.md
docs_architecture/flows/project-files.md
docs_architecture/modules/profile.md
docs_architecture/modules/networking.md
```

---

## 22. Pendências

Precisamos auditar:

- todos os services;
- repositories;
- provider real;
- buckets/containers;
- paths;
- signed URLs;
- expiração;
- hash;
- MIME;
- limites;
- RLS/Storage policies;
- limpeza de órfãos;
- atomicidade;
- retries;
- exclusão;
- backup e retenção.
