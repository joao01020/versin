# Versin — Módulo Profile

> **Status:** Parcialmente verificado no código e em execução\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/profile/`

---

## 1. Objetivo

Profile representa a identidade pública e profissional do usuário dentro do
Versin.

É utilizado por vários outros domínios, principalmente:

```text
Dashboard
Match
Networking
Public Profile
```

O módulo não deve ser confundido com autenticação. Auth responde "quem é a
sessão"; Profile responde "como esse usuário é representado no produto".

---

## 2. Estrutura identificada

```text
lib/modules/profile/
├── controllers/
├── data/
├── models/
├── public_profile/
├── repositories/
├── services/
├── views/
└── widgets/
```

---

## 3. Responsabilidades

O módulo concentra dados como:

- identidade pública;
- informações profissionais;
- username;
- habilidades/funções;
- interesses de colaboração;
- preferências públicas;
- presença;
- preferência online;
- conteúdo do perfil público.

A lista exata de campos deve ser mantida alinhada ao modelo real.

---

## 4. Perfil profissional

Logs confirmaram carregamento de informações como:

```text
função principal
funções
habilidades
o que procura
```

Exemplo observado em execução:

```text
Função principal: artist
Funções: [artist]
Procura: [beatmaker, producer, artist, composer]
```

O Profile Controller recebe esses dados da camada remota e os disponibiliza para
a aplicação.

---

## 5. Nome público

O Dashboard também carrega o nome público do usuário.

Foi observado uso de cache local para nomes:

```text
[PROFILE NAME CACHE]
```

Cache é otimização de experiência.

A fonte persistente deve continuar sendo o backend/banco.

---

## 6. Public Profile

Existe uma subestrutura dedicada:

```text
lib/modules/profile/public_profile/
```

Dentro dela foram identificados, entre outros:

```text
services/profile_track_service.dart
data/datasources/public_profile_remote_datasource.dart
```

Isso mostra que o perfil público possui responsabilidades próprias, incluindo
conteúdo associado ao perfil.

---

## 7. Tracks do perfil

O service:

```text
profile_track_service.dart
```

utiliza Supabase Edge Functions.

Na estrutura do projeto foram identificadas:

```text
create-track-upload-url
create-track-playback-url
delete-profile-track
```

Fluxo arquitetural:

```text
Profile
  │
  ▼
ProfileTrackService
  │
  ▼
Edge Function
  │
  ▼
autorização / storage
```

---

## 8. Upload de track

Existe Edge Function:

```text
create-track-upload-url
```

O objetivo arquitetural é evitar que o Flutter precise possuir credenciais
privilegiadas do storage.

A implementação exata da validação ainda deve ser auditada antes de documentar
garantias específicas.

---

## 9. Playback de track

Existe:

```text
create-track-playback-url
```

Isso permite controlar acesso ao conteúdo de reprodução através de uma operação
server-side.

A duração/expiração exata das URLs ainda precisa ser confirmada.

---

## 10. Delete de track

Existe:

```text
delete-profile-track
```

Delete deve validar server-side que o usuário pode remover aquele recurso.

Não confiar somente em:

```text
trackId
path
userId
```

fornecidos pelo cliente.

---

## 11. Username

O ecossistema Profile/Match utiliza RPCs:

```text
check_username_available
set_my_username
```

A disponibilidade é verificada server-side antes da alteração.

A unicidade definitiva deve ser garantida no banco, e não apenas por uma
consulta anterior no Flutter.

---

## 12. Preferência online

Foi identificada RPC:

```text
set_my_online_preference
```

em:

```text
public_profile_remote_datasource.dart
```

A operação deve alterar somente a preferência do usuário autenticado.

---

## 13. Presença

Foi identificada:

```text
update_my_presence
```

também chamada pelo datasource de perfil público.

Conceitualmente:

```text
sessão autenticada
      │
      ▼
update_my_presence
      │
      ▼
estado de presença
```

Presença é informação dinâmica e não deve ser confundida com dados permanentes
do perfil.

---

## 14. Match

O Match depende fortemente do Profile.

```text
Profile
  │
  ├── função
  ├── habilidades
  ├── procura
  ├── disponibilidade
  └── presença
        │
        ▼
      Match
```

Alterações no modelo profissional precisam ser revisadas também no Match.

---

## 15. Dashboard

O Dashboard consome:

- nome público;
- perfil profissional;
- informações resumidas da conta.

A lógica de carregamento e persistência deve continuar pertencendo ao Profile,
evitando duplicação no Dashboard.

---

## 16. Identidade versus `user_id`

Operações "meu perfil" devem preferencialmente derivar identidade de:

```sql
auth.uid()
```

no lado confiável.

O cliente pode informar o recurso desejado, mas não deve poder escolher
livremente a identidade que será modificada.

---

## 17. Privacidade

Nem todo dado de perfil precisa necessariamente ser público.

A documentação final deve classificar cada campo como:

```text
público
somente usuário
membros/conexões
interno
```

Essa classificação ainda precisa ser extraída das policies e modelos.

---

## 18. RLS

As tabelas de Profile expostas diretamente ao Flutter precisam de RLS coerente
com:

- leitura pública permitida;
- dados privados;
- edição somente pelo proprietário;
- campos que não podem ser alterados pelo cliente.

A auditoria completa das policies ainda está pendente.

---

## 19. Segurança de username

Além da verificação de disponibilidade, revisar:

- normalização;
- case sensitivity;
- tamanho;
- caracteres;
- palavras reservadas;
- corrida entre dois usuários;
- constraint única.

---

## 20. Dependências

```text
Profile
├── Supabase Auth
├── Supabase Database
├── Edge Functions
├── Storage
├── Dashboard
├── Match
└── Networking
```

---

## 21. Documentação relacionada

```text
docs_architecture/modules/match.md
docs_architecture/modules/dashboard.md
docs_architecture/architecture/authentication.md
docs_architecture/architecture/storage.md
docs_architecture/security/authorization.md
docs_architecture/security/file-security.md
```

---

## 22. Pendências

Ainda precisamos fechar:

- modelos completos;
- tabelas exatas;
- campos públicos/privados;
- RLS;
- repositories;
- cache;
- atualização de avatar, se existente;
- lifecycle de presença;
- regras de username;
- tracks;
- limites de upload;
- visibilidade de conteúdo.
