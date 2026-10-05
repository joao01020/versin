# Versin — Módulo Match

> **Status:** Parcialmente verificado no código\
> **Última revisão:** 2026-08-24\
> **Escopo:** `lib/modules/match/`

---

## 1. Objetivo

O Match conecta usuários com base em perfil, procura, disponibilidade e
critérios de descoberta.

Um resultado importante do fluxo é a possibilidade de transformar uma conexão
entre usuários em um projeto ativo.

```text
Descoberta
   │
   ▼
Match
   │
   ▼
conexão
   │
   ▼
projeto
```

---

## 2. Estrutura identificada

```text
lib/modules/match/
├── availability/
├── controllers/
├── data/
├── demo/
├── discovery/
├── filters/
├── location/
├── models/
├── profile/
├── search/
├── services/
├── team_expansion/
├── views/
└── widgets/
```

O módulo possui várias subáreas e não deve ser reduzido a uma única tela de
swipe.

---

## 3. Perfil profissional

O Match utiliza informações profissionais do usuário.

Logs confirmaram dados como:

```text
função principal
funções/habilidades
o que procura
```

Exemplo observado:

```text
artist
procura:
- beatmaker
- producer
- artist
- composer
```

Esses dados pertencem ao domínio Profile e são consumidos pelo Match.

---

## 4. Discovery

Diretório:

```text
lib/modules/match/discovery/
```

Responsável pelo fluxo de descoberta de pessoas/candidatos compatíveis.

Os critérios completos de ranking ainda precisam ser auditados antes de serem
documentados como regra oficial.

---

## 5. Filters

Diretório:

```text
lib/modules/match/filters/
```

Mantém filtros utilizados na descoberta.

A lista exata de filtros deve ser extraída do código.

---

## 6. Location

Diretório:

```text
lib/modules/match/location/
```

O Match possui lógica relacionada a localização.

Qualquer uso de localização deve ser revisado também sob:

- consentimento;
- precisão;
- retenção;
- exposição;
- autorização.

---

## 7. Availability

Existe:

```text
lib/modules/match/availability/
```

e o service:

```text
match_availability_service.dart
```

RPCs encontradas:

```text
set_my_available_now
clear_my_available_now
```

Essas operações alteram a disponibilidade do próprio usuário.

---

## 8. Presença e preferência online

Outras RPCs relacionadas ao ecossistema de Match/Profile incluem:

```text
set_my_online_preference
update_my_presence
```

Essas operações ajudam a representar estado/disponibilidade do usuário.

---

## 9. Username

O Match Controller utiliza:

```text
check_username_available
set_my_username
```

Isso mostra integração entre onboarding/perfil e descoberta.

---

## 10. Match → Project

O controller possui lógica para encontrar ou criar projeto.

Foi observado código consultando:

```text
projects
```

com membros:

```text
normalizedMyId
normalizedOtherId
```

Se um projeto já existe, seu ID é reutilizado.

---

## 11. Criação de projeto

Quando não existe projeto correspondente, o Match cria:

```text
title: 'Studio Session'

members:
- usuário atual
- outro usuário

founders:
- usuário atual
- outro usuário

status: 'active'
origin: 'match'
```

e recupera:

```text
id
```

---

## 12. Identificação de projetos Match

Outra parte do código consulta:

```text
projects
```

com:

```text
origin = 'match'
status = 'active'
members contém userId
```

Isso permite separar projetos originados no Match de outros projetos.

---

## 13. Evento após projeto

Após encontrar/criar o projeto, o controller emite um evento de Match associado
ao `projectId`.

Esse mecanismo permite que outras partes da aplicação reajam à criação/conexão
sem duplicar toda a lógica.

---

## 14. Saída de projeto Match

Foi encontrada RPC:

```text
leave_match_project
```

utilizada no módulo Networking.

Isso demonstra que o ciclo iniciado pelo Match continua depois dentro do
projeto/networking.

---

## 15. Team Expansion

Existe:

```text
lib/modules/match/team_expansion/
```

Essa área indica suporte à expansão de equipe além do Match inicial.

O comportamento detalhado ainda precisa ser auditado.

---

## 16. Segurança

O cliente não deve poder:

- criar membership arbitrário;
- adicionar terceiros sem regra;
- assumir identidade de outro usuário;
- alterar disponibilidade de outro usuário;
- aceitar Match em nome de terceiro.

RPCs e policies devem derivar identidade de:

```sql
auth.uid()
```

quando a operação pertence ao usuário atual.

---

## 17. Concorrência

O fluxo de criação de projeto precisa considerar a possibilidade de dois
clientes tentarem criar a mesma relação simultaneamente.

A consulta prévia:

```text
existe projeto?
```

não é, sozinha, uma garantia de unicidade sob concorrência.

A existência de constraint/idempotência server-side para esse caso ainda precisa
ser confirmada.

---

## 18. Dependências

```text
Match
├── Profile
├── Projects
├── Availability
├── Presence
├── Location
├── Supabase
└── Networking
```

---

## 19. Documentação relacionada

```text
docs_architecture/flows/match-to-project.md
docs_architecture/modules/profile.md
docs_architecture/modules/networking.md
docs_architecture/database/rpc.md
docs_architecture/security/authorization.md
```

---

## 20. Pendências

Ainda precisamos documentar:

- algoritmo de descoberta;
- filtros;
- localização;
- critérios de compatibilidade;
- modelo completo de Match;
- prevenção server-side de projetos duplicados;
- Realtime;
- bloqueio/privacidade;
- team expansion;
- testes de autorização.
