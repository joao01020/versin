# docs/dev/coding-standards.md

# Coding Standards

## Objetivo

Padronizar o desenvolvimento do Versin para manter:

- organização,
- escalabilidade,
- legibilidade,
- manutenção simples.

---

# Padrões Gerais

## Nomes

Utilize nomes claros e objetivos.

Bom:

```dart
AudioSyncService
```

Ruim:

```dart
Service1
```

---

# Responsabilidade Única

Cada arquivo deve possuir apenas uma responsabilidade principal.

---

# Modularização

Evite:

- arquivos gigantes,
- lógica duplicada,
- dependências desnecessárias.

---

# Organização Flutter

```bash
features/
│
├── authentication/
│   ├── data/
│   ├── domain/
│   ├── presentation/
│   └── widgets/
```

---

# Organização Backend

```bash
backend/
│
├── controllers/
├── services/
├── repositories/
├── middleware/
├── routes/
└── utils/
```

---

# Organização IA

```bash
ai/
│
├── embeddings/
├── moderation/
├── ranking/
├── matching/
└── vector-search/
```

---

# Convenções

## Classes

```dart
PascalCase
```

## Variáveis

```dart
camelCase
```

## Constantes

```dart
UPPER_CASE
```

---

# Comentários

Comente apenas:

- regras complexas,
- lógica crítica,
- decisões importantes.

Evite comentários óbvios.

---

# Segurança

Nunca deixar:

- tokens hardcoded,
- segredos no código,
- credenciais públicas.

---

# Performance

Priorize:

- componentes reutilizáveis,
- cache,
- lazy loading,
- baixo consumo de memória.

---

# Objetivo Final

Criar um código:

- previsível,
- organizado,
- profissional,
- fácil de expandir.