# Versin — Security: Authorization

> **Status:** Auditoria em andamento\
> **Última revisão:** 2026-08-24\
> **Escopo:** PostgreSQL RLS, RPC, projetos, arquivos, Edge Functions e backend

---

## 1. Objetivo

Autorização responde:

```text
este usuário autenticado pode executar esta operação neste recurso?
```

Ela deve ser aplicada no lado confiável.

---

## 2. Modelo

```text
identidade
   +
recurso
   +
ação
   +
contexto
   │
   ▼
decisão
   │
   ├── allow
   └── deny
```

---

## 3. Default deny

Quando não existe regra explícita permitindo uma operação, o comportamento
desejado é negar.

Isso reduz o impacto de features novas ou tabelas esquecidas.

---

## 4. RLS

Como o Flutter acessa Supabase diretamente, RLS é uma camada essencial.

Policies devem ser avaliadas por operação:

```text
SELECT
INSERT
UPDATE
DELETE
```

Uma policy de leitura não deve implicitamente ser considerada suficiente para
escrita.

---

## 5. `USING` e `WITH CHECK`

Conceitualmente:

```text
USING
  → quais linhas existentes podem ser vistas/alteradas

WITH CHECK
  → quais valores podem ser inseridos/produzidos
```

Policies de UPDATE/INSERT precisam ser revisadas para impedir troca de ownership
ou associação.

---

## 6. `auth.uid()`

Operações de propriedade devem relacionar o recurso à identidade autenticada.

Exemplo conceitual:

```sql
owner_id = auth.uid()
```

Para projetos, ownership pode não ser suficiente; membership e role também podem
ser necessárias.

---

## 7. Projetos

Networking depende de autorização contextual.

Helpers identificados:

```text
is_project_member(...)
can_access_project_storage(...)
is_recruitment_project_member(...)
```

Esses helpers centralizam parte das regras.

Precisamos auditar suas implementações e grants.

---

## 8. Membership

Não confiar em:

```text
projectId
memberId
members enviados pelo Flutter
```

sem verificar o estado persistido.

---

## 9. Match → Project

Foi observado que o Flutter cria projeto com:

```text
members
founders
origin = match
status = active
```

A camada server-side deve impedir que um cliente modificado coloque usuários
arbitrários em `members` ou `founders`.

A proteção atual precisa ser confirmada nas policies/functions.

---

## 10. Convites

RPCs:

```text
accept_project_invitation
reject_project_invitation
```

precisam validar que:

```text
o convite existe
o destinatário é o usuário autenticado
o estado permite a transição
```

---

## 11. Recruitment

RPC:

```text
approve_project_recruitment_candidate
```

precisa validar que quem aprova possui permissão naquele projeto.

Não confiar somente no `project_id` e `candidate_id` recebidos.

---

## 12. Profile

Operações:

```text
set_my_username
set_my_online_preference
update_my_presence
```

devem modificar somente o próprio usuário.

Leitura pública e escrita privada precisam ser políticas separadas.

---

## 13. Notifications

Um usuário não deve ler ou alterar notificações privadas de outro.

Realtime deve respeitar as mesmas restrições.

---

## 14. Creative Activity

Eventos devem pertencer ao usuário autenticado.

O cliente não deve conseguir aumentar a produção de outro usuário alterando
`user_id`.

Também existe unicidade:

```text
(user_id, event_type, source_id)
```

que protege duplicidade lógica, mas não substitui autorização.

---

## 15. Storage

Antes de upload/playback/delete:

```text
validar identidade
validar projeto/owner
validar recurso
validar ação
```

Conhecer um path não é autorização.

---

## 16. SECURITY DEFINER

Foram identificadas:

```text
34 funções public SECURITY DEFINER
```

Essas funções exigem revisão prioritária.

Riscos:

```text
bypass de RLS
privilégio do owner
search_path inseguro
argumentos usados sem autorização
grants amplos
```

---

## 17. `search_path`

Funções `SECURITY DEFINER` devem evitar resolução ambígua de objetos.

Uma prática segura é configurar `search_path` explicitamente e/ou qualificar
objetos.

A auditoria mostrou `function_config` para funções, mas cada função precisa ser
revisada individualmente.

---

## 18. EXECUTE

Mesmo uma função segura pode estar exposta a roles desnecessárias.

Revisar:

```text
anon
authenticated
PUBLIC
service_role
```

e conceder somente o necessário.

---

## 19. IDOR

Um dos principais riscos do Versin é IDOR/BOLA:

```text
/profile/{id}
/project/{id}
/file/{id}
/invitation/{id}
/notification/{id}
```

Trocar um ID no cliente não pode conceder acesso a outro usuário.

---

## 20. Mass assignment

Objetos enviados pelo Flutter não devem permitir alteração irrestrita de campos
sensíveis.

Exemplo:

```text
cliente deveria alterar:
title

mas também envia:
owner_id
members
role
status administrativo
```

O servidor/banco deve restringir os campos efetivamente permitidos.

---

## 21. Transições de estado

Estados sensíveis devem ter transições válidas.

Exemplo:

```text
pending → accepted
pending → rejected
```

e não qualquer estado arbitrário enviado pelo cliente.

RPCs são úteis quando a transição precisa ser atômica e autorizada.

---

## 22. Testes negativos

Para cada recurso:

```text
owner
membro autorizado
membro sem permissão
usuário externo
anon
```

testar:

```text
SELECT
INSERT
UPDATE
DELETE
RPC
Realtime
Storage
```

---

## 23. Documentação relacionada

```text
docs_architecture/database/rls.md
docs_architecture/database/rpc.md
docs_architecture/modules/networking.md
docs_architecture/security/authentication.md
docs_architecture/security/file-security.md
```

---

## 24. Pendências

Precisamos concluir:

- inventário de todas as policies;
- matriz role × operação;
- 34 `SECURITY DEFINER`;
- grants;
- helpers de membership;
- autorização de criação de projetos;
- royalties;
- calls;
- tasks;
- notifications;
- Storage;
- Edge Functions;
- testes automatizados de IDOR.
