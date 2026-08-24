# Versin — Security: Authentication

> **Status:** Parcialmente verificado\
> **Última revisão:** 2026-08-24\
> **Escopo:** Supabase Auth, Flutter e backend Versin

---

## 1. Objetivo

Autenticação estabelece a identidade da sessão.

Ela não determina, sozinha, quais recursos o usuário pode acessar.

```text
credencial
   │
   ▼
Supabase Auth
   │
   ▼
sessão / JWT
   │
   ├── Flutter
   └── backend
```

---

## 2. Fonte de identidade

No banco, operações do usuário atual devem preferir:

```sql
auth.uid()
```

No backend:

```text
Authorization: Bearer <JWT>
        │
        ▼
validação do token
        │
        ▼
identidade confiável
```

---

## 3. Backend

Foi identificado:

```text
versin_api/services/supabase_auth_service.py
```

Esse service participa da validação de autenticação no backend próprio.

---

## 4. Regra fundamental

Nunca usar apenas:

```json
{
    "user_id": "..."
}
```

como prova de identidade.

Um cliente modificado pode trocar esse valor.

A operação deve comparar/derivar identidade a partir da sessão validada.

---

## 5. Flutter

O Flutter mantém a sessão necessária para acessar recursos autenticados.

Como o aplicativo roda no dispositivo do usuário, ele deve ser considerado
ambiente não confiável.

Portanto:

```text
checagem Flutter
+
checagem server-side
```

e não:

```text
checagem Flutter apenas
```

---

## 6. JWT

O JWT permite ao backend verificar a identidade da sessão.

O backend precisa validar o token de acordo com a configuração do Supabase.

Não registrar o token completo em logs.

---

## 7. Sessão expirada

O aplicativo deve distinguir:

```text
sessão válida
sessão expirada
usuário deslogado
erro temporário de rede
```

Uma sessão inválida não deve ser tratada como simples falha genérica de
servidor.

---

## 8. Logout

Logout precisa invalidar/remover o estado de sessão local apropriado e levar a
aplicação para estado não autenticado.

A interface pode disponibilizar um botão de sair, mas a segurança vem do
encerramento efetivo da sessão, não da navegação visual.

---

## 9. Banco

Policies podem utilizar:

```sql
auth.uid()
```

para relacionar a sessão com:

```text
owner
member
recipient
profile
```

Essa é uma das principais fronteiras contra IDOR em acesso direto ao Supabase.

---

## 10. RPCs

Funções do tipo:

```text
set_my_...
update_my_...
```

devem obter a identidade do usuário autenticado internamente sempre que
possível.

Exemplos encontrados:

```text
set_my_available_now
clear_my_available_now
set_my_online_preference
set_my_username
update_my_presence
```

---

## 11. Edge Functions

Edge Functions que criam URLs ou removem arquivos devem validar a sessão antes
da operação.

Funções conhecidas:

```text
create-track-upload-url
create-track-playback-url
create-work-upload-url
create-work-playback-url
delete-profile-track
delete-work-file
```

---

## 12. Backend de IA

O fluxo da IA utiliza autenticação antes de confiar na identidade do usuário.

Logs confirmaram chamadas com:

```text
Autenticação JWT: true
```

Isso é evidência de uso de JWT no fluxo, não prova de que todos os endpoints
estão corretamente protegidos.

---

## 13. Endpoint de quota

Foi observado:

```text
GET /chat/quota/{user_id}
```

Como o ID aparece na URL, o backend precisa garantir que um usuário não consulte
dados privados de outro apenas alterando o path.

Essa autorização deve ser confirmada diretamente no código/testes.

---

## 14. `auth.users`

Foi identificado o fluxo de criação de usuário com trigger:

```text
on_auth_user_created
```

associado à função:

```text
handle_new_user
```

Esse fluxo deve ser tratado como parte do provisioning pós-cadastro.

---

## 15. Trigger de novo usuário

Triggers ligados a `auth.users` executam em uma área crítica.

A função deve ser:

- determinística;
- mínima;
- segura contra metadata inesperada;
- tolerante a campos opcionais;
- sem privilégios desnecessários.

---

## 16. Login e Profile

Autenticação e Profile devem permanecer separados:

```text
Auth
  → identidade da conta

Profile
  → representação no produto
```

Falha ao carregar Profile não significa necessariamente falha de autenticação.

---

## 17. Proteção contra enumeração

Fluxos como:

```text
recuperação de senha
username
login
```

devem evitar revelar informação desnecessária sobre contas existentes.

A implementação específica de recovery ainda precisa ser auditada.

---

## 18. Armazenamento de sessão

A estratégia exata de armazenamento de tokens por:

```text
Linux
Windows
Android
iOS
Web
```

ainda precisa ser auditada.

Tokens persistentes não devem ser gravados em arquivos de projeto, logs ou
repositório Git.

---

## 19. Reautenticação

Operações altamente sensíveis podem exigir reautenticação dependendo do risco.

Ainda não foi confirmado se o Versin possui esse mecanismo.

---

## 20. Testes mínimos

```text
sem JWT → endpoint protegido nega
JWT inválido → nega
JWT expirado → nega/renova conforme fluxo
JWT de A + user_id de B → nega
JWT de A + recurso de B → nega
anon → não acessa recurso privado
logout → sessão deixa de autorizar
```

---

## 21. Documentação relacionada

```text
docs_architecture/architecture/authentication.md
docs_architecture/backend/authentication.md
docs_architecture/security/authorization.md
docs_architecture/security/secrets.md
```

---

## 22. Pendências

Precisamos confirmar:

- providers de login;
- refresh de token;
- armazenamento seguro por plataforma;
- recovery;
- verificação de email;
- MFA, se existente;
- revogação;
- timeout de sessão;
- CORS;
- proteção exata do endpoint de quota;
- testes de autenticação do backend.
