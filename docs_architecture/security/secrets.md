# Versin — Security: Secrets

> **Status:** Baseline de hardening\
> **Última revisão:** 2026-08-24\
> **Escopo:** Flutter, FastAPI, Supabase, Edge Functions, CI/CD e ambientes
> locais

---

## 1. Objetivo

Secrets são credenciais que concedem privilégios ou acesso.

Exemplos:

```text
service_role
API keys privadas
Redis credentials
provider secrets
database credentials
signing secrets
deploy tokens
```

Eles não devem ser distribuídos no aplicativo Flutter.

---

## 2. Regra central

```text
se o usuário consegue baixar o aplicativo,
não trate um segredo embutido nele como secreto
```

Obfuscação não transforma uma credencial client-side em segredo seguro.

---

## 3. Chaves públicas versus secretas

Nem toda configuração é segredo.

No ecossistema Supabase, a configuração pública necessária ao cliente é
diferente de credenciais administrativas.

Credenciais com privilégio elevado, especialmente `service_role`, nunca devem
ser incluídas no Flutter.

---

## 4. `.env`

O projeto possui arquivos como:

```text
.env
versin_api/.env
versin_api/.env.exemple
versin_api/.envignore
```

A existência de `.env` não garante segurança.

É necessário garantir que arquivos reais com secrets:

```text
não sejam commitados
não sejam incluídos no build público
não sejam enviados em logs
```

---

## 5. Git

Verificar:

```bash
git status
git ls-files | grep -E '(^|/)\.env($|\.)'
```

Se um secret já foi commitado, apenas removê-lo do arquivo atual não é
suficiente.

Ele deve ser considerado comprometido e rotacionado.

---

## 6. `.gitignore`

Arquivos locais sensíveis devem estar ignorados.

Exemplo conceitual:

```gitignore
.env
.env.*
!.env.example
versin_api/.env
```

A regra real deve respeitar os arquivos de exemplo que o projeto deseja
versionar.

---

## 7. Flutter

Não colocar secrets em:

```text
lib/
assets/
dart-define usado como segredo permanente
código compilado
JavaScript web
config pública
```

Qualquer valor necessário para autenticar o próprio backend como serviço
privilegiado deve ficar no servidor.

---

## 8. Flutter Web

No Web, tudo entregue ao navegador é especialmente fácil de inspecionar.

Portanto:

```text
variável no bundle
    ==
valor público para o usuário
```

---

## 9. Backend FastAPI

Secrets do backend devem vir do ambiente/deployment.

O projeto possui:

```text
versin_api/core/config.py
```

Esse é o local arquitetural para centralizar leitura/configuração, evitando
`os.getenv()` espalhado por todo o código.

---

## 10. Render/deployment

O backend já foi observado rodando em domínio Render.

Credenciais de produção devem ser configuradas no ambiente do serviço de
deployment e não commitadas no repositório.

Os nomes exatos das variáveis precisam ser inventariados antes de documentá-los.

---

## 11. Edge Functions

Secrets utilizados por Edge Functions devem ser configurados no ambiente de
Functions.

Nunca colocar credenciais administrativas diretamente no `index.ts` versionado.

---

## 12. Supabase service role

`service_role` ignora várias proteções destinadas ao cliente e possui alto
impacto.

Regra:

```text
Flutter       → nunca
backend seguro → somente quando necessário
Edge Function → somente quando necessário
```

Mesmo no servidor, preferir privilégio mínimo.

---

## 13. API privada do usuário

O Versin possui arquitetura para permitir API privada configurada pelo usuário.

Essas chaves são secrets do próprio usuário.

Não devem:

```text
aparecer em logs
ser enviadas para analytics
ser expostas a outros usuários
ser armazenadas em plaintext sem análise de risco
```

A estratégia real de armazenamento ainda precisa ser auditada.

---

## 14. Redis

Credenciais Redis usadas pelo rate limiter pertencem ao backend.

Nunca devem ser expostas ao Flutter.

---

## 15. Logs

Evitar:

```python
print(api_key)
print(jwt)
print(headers)
print(env)
```

Logging de objetos inteiros pode vazar secrets indiretamente.

---

## 16. Erros

Mensagens retornadas ao cliente não devem incluir:

```text
connection strings
stack trace de produção
paths internos sensíveis
headers
tokens
env vars
```

---

## 17. CI/CD

Pipelines devem consumir secrets do mecanismo seguro da plataforma.

Nunca:

```text
echo SECRET
cat .env
upload de artefato contendo .env
```

---

## 18. Rotação

Todo secret importante deve possuir um caminho de rotação.

Processo:

```text
1. gerar nova credencial
2. atualizar consumidores
3. validar
4. revogar antiga
5. revisar logs/incidente
```

---

## 19. Secret exposto

Se uma credencial real foi:

```text
commitada
colada em issue pública
enviada em build
publicada em log
```

trate-a como comprometida.

Não basta apagar a string.

---

## 20. Histórico Git

Remover um arquivo do último commit não remove necessariamente o secret do
histórico.

Depois da rotação, a limpeza do histórico pode ser necessária dependendo do
caso.

A rotação é a prioridade.

---

## 21. Arquivos de exemplo

Usar:

```text
.env.example
```

com nomes das variáveis e valores falsos.

Exemplo:

```text
REDIS_URL=
AI_PROVIDER_API_KEY=
```

Nunca copiar valores reais.

---

## 22. Permissões locais

Em servidores/estações compartilhadas, secrets locais devem possuir permissões
restritas.

Exemplo:

```bash
chmod 600 .env
```

quando apropriado.

Isso não substitui um secret manager em produção.

---

## 23. Inventário necessário

Precisamos construir uma matriz:

```text
secret
onde nasce
onde é armazenado
quem usa
ambiente
como rotaciona
```

Sem colocar o valor do secret na documentação.

---

## 24. Testes

Adicionar secret scanning ao fluxo de desenvolvimento é recomendável.

Também revisar:

```text
Git history
build artifacts
Flutter assets
Docker images, se houver
CI logs
crash reports
```

---

## 25. Documentação relacionada

```text
docs_architecture/backend/deployment.md
docs_architecture/security/authentication.md
docs_architecture/security/overview.md
```

---

## 26. Pendências

Precisamos auditar:

- `.gitignore`;
- histórico Git;
- variáveis do root `.env`;
- variáveis de `versin_api/.env`;
- secrets das Edge Functions;
- Render;
- Redis;
- provider de IA;
- API privada do usuário;
- CI/CD;
- estratégia de rotação.

A documentação deve registrar nomes/finalidades, nunca valores reais.
