# Versin — Security: File Security

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** tracks, works, arquivos de projeto, hashes e Storage

---

## 1. Objetivo

Arquivos do Versin podem conter propriedade criativa do usuário.

O objetivo é proteger:

```text
confidencialidade
integridade
autorização
disponibilidade
consistência
```

---

## 2. Hash não é proteção de acesso

O Versin utiliza SHA-256 em fluxos de arquivo.

SHA-256 pode ajudar a responder:

```text
este conteúdo mudou?
este arquivo é igual a outro?
qual é a identidade do conteúdo?
```

Mas não responde:

```text
quem pode abrir?
quem pode baixar?
quem pode apagar?
```

---

## 3. Hash não é criptografia

```text
arquivo
   │
   ▼
SHA-256
   │
   ▼
digest
```

Não existe operação inversa prática para recuperar o arquivo a partir do digest,
mas o arquivo original continua sem confidencialidade se estiver
armazenado/publicado de forma insegura.

---

## 4. Fronteira de acesso

O acesso deve depender de autorização.

```text
usuário
  │
  ▼
sessão
  │
  ▼
owner / project membership
  │
  ▼
permissão
  │
  ▼
arquivo
```

---

## 5. Funções identificadas

```text
create-track-upload-url
create-track-playback-url
create-work-upload-url
create-work-playback-url
delete-profile-track
delete-work-file
```

Essas Edge Functions devem ser tratadas como pontos críticos de segurança.

---

## 6. Upload

Antes de autorizar upload:

- validar JWT;
- validar destino;
- validar ownership/membership;
- limitar path;
- validar tamanho/tipo conforme regra;
- impedir overwrite indevido.

Os detalhes atuais ainda precisam ser confirmados em cada function.

---

## 7. Playback

Antes de gerar acesso:

```text
1. validar sessão
2. localizar recurso
3. validar owner/membership/visibilidade
4. gerar acesso limitado
```

Uma URL temporária vazada deve ter impacto limitado pelo tempo.

---

## 8. Delete

Delete precisa validar:

```text
quem solicitou
qual arquivo
a qual recurso pertence
qual permissão o usuário possui
```

Nunca permitir delete apenas porque o cliente conhece o storage path.

---

## 9. Path traversal / object key

Paths fornecidos pelo cliente devem ser tratados como entrada não confiável.

Evitar construir paths privilegiados por concatenação sem validação.

Preferir derivar o path server-side a partir de IDs autorizados.

---

## 10. MIME e extensão

Não confiar apenas em:

```text
arquivo.mp3
Content-Type: audio/mpeg
```

Extensão e MIME enviados pelo cliente podem ser falsificados.

Quando o risco justificar, validar assinatura/conteúdo no lado confiável.

---

## 11. Tamanho

Uploads precisam de limite.

Sem limite, um atacante pode causar:

```text
consumo de storage
custos
DoS
uso de banda
```

Os limites atuais ainda precisam ser inventariados.

---

## 12. Nome de arquivo

O nome original pode ser mantido como metadata para UI, mas não precisa ser
usado como chave física.

Preferir storage keys controladas pelo sistema.

---

## 13. SHA-256

Se o hash é usado como garantia de integridade, precisamos confirmar onde ele é
calculado.

```text
cliente
servidor
ambos
```

Um hash enviado pelo cliente não é prova confiável contra um cliente malicioso.

---

## 14. Deduplicação

Se o sistema futuramente usar hash para deduplicar, cuidado com vazamento de
existência:

```text
"este hash já existe"
```

pode revelar que determinado conteúdo está armazenado.

A deduplicação entre usuários deve ser analisada antes de ser implementada.

---

## 15. Arquivos privados

A configuração preferível para conteúdo de projeto é:

```text
privado por padrão
```

e acesso concedido após autorização.

Conteúdo explicitamente público pode seguir regras próprias.

---

## 16. Signed URLs

URLs assinadas/temporárias devem:

- expirar;
- ser emitidas após autorização;
- não ser persistidas como identificador principal;
- não aparecer em logs desnecessários.

---

## 17. Revogação

Uma URL já emitida pode continuar válida até expirar.

Por isso, o TTL deve considerar a sensibilidade do arquivo.

A duração atual ainda precisa ser confirmada.

---

## 18. Membership revogado

Quando alguém sai de um projeto:

```text
novas solicitações
    → devem ser negadas
```

URLs temporárias já emitidas podem continuar válidas até expiração, dependendo
do provider.

---

## 19. Consistência banco × objeto

Precisamos impedir/recuperar:

```text
registro sem objeto
objeto sem registro
delete parcial
upload abandonado
```

---

## 20. Malware e conteúdo ativo

Se arquivos enviados puderem ser posteriormente executados ou interpretados, o
risco aumenta.

Mesmo arquivos de mídia podem carregar conteúdo malformado.

A necessidade de scanning depende dos formatos e da superfície de consumo e
ainda precisa ser definida.

---

## 21. Conteúdo servido no Web

Se uploads forem servidos em contexto web, atenção a:

```text
Content-Type
Content-Disposition
X-Content-Type-Options
origem/domínio
conteúdo HTML/SVG
```

para evitar transformar uploads em conteúdo ativo confiável.

---

## 22. Logs

Nunca registrar:

```text
signed URL completa
token de upload
credencial do provider
conteúdo do arquivo
```

Preferir:

```text
file_id
project_id
operação
status
erro sanitizado
```

---

## 23. Quotas

Storage precisa considerar limites por:

```text
usuário
projeto
arquivo
período
```

A implementação atual ainda precisa ser levantada.

---

## 24. Backup e recuperação

Segurança também inclui disponibilidade.

Precisamos documentar:

```text
backup
retenção
restore
soft delete, se houver
recovery de metadata
```

---

## 25. Testes mínimos

```text
A acessa arquivo próprio → permitido
A acessa arquivo de B → negar
membro acessa arquivo permitido do projeto → permitido
ex-membro solicita nova URL → negar
anon solicita arquivo privado → negar
path adulterado → negar
delete de arquivo alheio → negar
upload acima do limite → negar
tipo proibido → negar
```

---

## 26. Documentação relacionada

```text
docs_architecture/architecture/storage.md
docs_architecture/database/storage.md
docs_architecture/flows/project-files.md
docs_architecture/modules/storage.md
docs_architecture/security/authorization.md
```

---

## 27. Pendências

Precisamos confirmar:

- buckets;
- provider;
- private/public;
- storage paths;
- TTL;
- MIME permitidos;
- tamanho máximo;
- cálculo de SHA-256;
- quotas;
- Storage policies;
- CORS;
- scanning;
- cleanup;
- backup;
- retenção.
