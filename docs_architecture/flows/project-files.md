# Versin — Fluxo Project Files

> **Status:** Parcialmente verificado na arquitetura e nos componentes de
> storage\
> **Última revisão:** 2026-08-24\
> **Escopo:** arquivos associados a projetos

---

## 1. Objetivo

Este fluxo descreve como arquivos de projeto devem atravessar o Versin com
separação entre:

```text
autorização
metadata
upload/download
integridade
storage
delete
```

Arquivos são uma das superfícies mais sensíveis do sistema porque combinam
conteúdo privado com referências controladas pelo cliente.

---

## 2. Componentes conhecidos

Foram identificados:

```text
lib/modules/storage/
versin_api/services/project_storage_service.py
supabase/functions/create-work-upload-url/
supabase/functions/create-work-playback-url/
supabase/functions/delete-work-file/
```

Também existe helper SQL:

```text
can_access_project_storage(...)
```

---

## 3. Visão geral

```text
Usuário
  │
  ▼
Projeto
  │
  ▼
solicita operação de arquivo
  │
  ▼
valida membership/permissão
  │
  ├── negar
  │
  └── permitir
         │
         ▼
     upload/playback/delete
         │
         ▼
       Storage
```

---

## 4. Regra central

Conhecer:

```text
projectId
fileId
path
hash
```

não deve ser suficiente para acessar o conteúdo.

A autorização deve verificar a relação real entre usuário e projeto/recurso.

---

## 5. Membership

Foi identificado helper:

```text
can_access_project_storage(...)
```

Esse tipo de função deve ser usado para centralizar regra de acesso ao storage
de projeto.

A implementação exata precisa continuar auditada junto às policies/functions.

---

## 6. Upload

Existe Edge Function:

```text
create-work-upload-url
```

O desenho sugere fluxo de autorização antes de disponibilizar a operação de
upload.

Conceitualmente:

```text
Flutter
  │
  ▼
create-work-upload-url
  │
  ├── valida sessão
  ├── valida projeto/permissão
  └── cria autorização temporária
         │
         ▼
       upload
```

Não devemos afirmar detalhes específicos de provider/expiração sem inspecionar a
function.

---

## 7. Metadata

O banco deve manter informação suficiente para relacionar o objeto ao domínio.

Conceitualmente:

```text
file
├── id
├── project_id
├── owner/uploader
├── storage key
├── hash
├── metadata
└── timestamps
```

Os nomes reais das colunas devem ser copiados do schema.

---

## 8. Hash

O projeto já utiliza SHA-256 em fluxos de arquivo.

Ele pode servir para:

```text
integridade
identificação
comparação
deduplicação, se houver regra
```

Mas:

```text
SHA-256 não criptografa o arquivo
SHA-256 não substitui RLS
SHA-256 não substitui autorização
```

---

## 9. Quem calcula o hash

A garantia muda dependendo da origem:

```text
cliente calcula
    → útil, mas cliente pode mentir

servidor calcula
    → evidência mais confiável

ambos calculam
    → permite comparação
```

O fluxo atual precisa ser auditado para confirmar onde o hash é calculado.

---

## 10. Validação de arquivo

Nunca confiar apenas em:

```text
nome
extensão
MIME declarado
tamanho declarado
hash declarado
```

Quando necessário, validar no lado confiável.

---

## 11. Playback

Existe:

```text
create-work-playback-url
```

O objetivo é permitir acesso controlado a conteúdo que não precisa ser
publicamente acessível.

Fluxo:

```text
usuário solicita reprodução
        │
        ▼
valida acesso ao projeto
        │
        ▼
gera autorização/URL temporária
        │
        ▼
cliente reproduz
```

---

## 12. URLs temporárias

Uma URL temporária não deve virar o identificador permanente do arquivo.

O registro permanente deve utilizar:

```text
file id
storage key/path interno
```

e emitir acesso quando necessário.

---

## 13. Delete

Existe:

```text
delete-work-file
```

Delete deve validar:

```text
sessão
membership
papel/permissão
arquivo pertence ao projeto
```

e manter banco/storage consistentes.

---

## 14. Ordem de exclusão

Excluir metadata e objeto em operações independentes pode produzir
inconsistência.

Estados possíveis:

```text
DB removido / objeto ficou
DB ficou / objeto removido
```

A implementação deve ter estratégia explícita para falhas parciais.

---

## 15. Arquivos órfãos

Precisamos prever limpeza/reconciliação de:

```text
objetos sem registro
registros sem objeto
uploads iniciados e abandonados
```

A estratégia atual ainda precisa ser confirmada.

---

## 16. Produção criativa

Adicionar arquivo pode alimentar:

```text
files_added
```

no Creative Production.

Esse evento só deve ser registrado depois que a operação considerada válida pelo
domínio foi concluída.

---

## 17. Idempotência do evento

Para produção criativa, o arquivo pode fornecer um `source_id` estável.

Exemplo conceitual:

```text
file:<file-id>
```

Assim, retries não incrementam a produção repetidamente.

---

## 18. Privacidade

Arquivos de projeto devem ser tratados como privados por padrão quando o produto
não declarar explicitamente o contrário.

Uma pessoa fora do projeto não deve obter conteúdo apenas conhecendo um path.

---

## 19. Backend próprio

Existe:

```text
versin_api/services/project_storage_service.py
```

Esse service indica que parte da autorização/orquestração de arquivos pode
passar pelo backend Versin.

A fronteira exata entre FastAPI e Edge Functions ainda precisa ser documentada.

---

## 20. Supabase Storage

O projeto possui estrutura Supabase para funções relacionadas a arquivos.

Policies de Storage devem ser auditadas separadamente das policies das tabelas
PostgreSQL.

```text
database RLS
    !=
storage policies
```

Ambas podem ser necessárias.

---

## 21. Falhas

Tratar:

```text
upload interrompido
URL expirada
arquivo grande demais
MIME inválido
hash divergente
membership removido
delete parcial
registro duplicado
objeto inexistente
```

---

## 22. Logs

Logs úteis:

```text
file id
project id
operação
resultado
tempo
erro técnico
```

Evitar:

```text
signed URL completa
token
JWT
credenciais
conteúdo do arquivo
```

---

## 23. Fluxo resumido de upload

```text
1. usuário seleciona arquivo
2. cliente coleta metadata
3. solicita autorização de upload
4. servidor valida sessão/projeto
5. operação temporária é emitida
6. bytes são enviados
7. metadata é persistida/confirmada
8. integridade é validada conforme implementação
9. evento files_added pode ser registrado
10. UI recebe estado final
```

A ordem real entre passos 6 e 7 precisa ser confirmada no código.

---

## 24. Fluxo resumido de playback

```text
1. usuário solicita arquivo
2. servidor valida acesso atual
3. cria acesso temporário
4. Flutter recebe autorização
5. arquivo é consumido
```

---

## 25. Fluxo resumido de delete

```text
1. usuário solicita delete
2. identidade é validada
3. permissão é validada
4. vínculo arquivo/projeto é validado
5. objeto/registro são removidos
6. inconsistências parciais são tratadas
7. UI é atualizada
```

---

## 26. Documentação relacionada

```text
docs_architecture/modules/storage.md
docs_architecture/modules/networking.md
docs_architecture/architecture/storage.md
docs_architecture/database/storage.md
docs_architecture/security/file-security.md
```

---

## 27. Pendências

Precisamos confirmar:

- tabelas e colunas;
- buckets;
- provider físico;
- formato do path;
- quem calcula SHA-256;
- tamanho máximo;
- MIME permitido;
- expiração das URLs;
- policies;
- owner versus member permissions;
- atomicidade;
- cleanup;
- retries;
- evento `files_added`.
