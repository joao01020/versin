# docs/dev/deployment.md

# Deployment

## Objetivo

Definir o fluxo oficial de deploy do Versin.

---

# Ambientes

## Desenvolvimento

```bash
dev
```

## Homologação

```bash
staging
```

## Produção

```bash
main
```

---

# Frontend Flutter

## Build Android

```bash
flutter build apk
```

## Build iOS

```bash
flutter build ios
```

## Build Web

```bash
flutter build web
```

---

# Backend

## Produção

```bash
npm run build
npm run start
```

## Desenvolvimento

```bash
npm run dev
```

---

# IA

## Inicialização

```bash
python main.py
```

---

# Variáveis de Ambiente

Crie:

```bash
.env
```

Exemplo:

```env
SUPABASE_URL=
SUPABASE_KEY=
OPENAI_API_KEY=
DATABASE_URL=
```

---

# Segurança

Antes do deploy:

- revisar credenciais,
- validar logs,
- remover chaves temporárias,
- revisar permissões.

---

# Banco de Dados

## Migrações

```bash
supabase db push
```

---

# Checklist

Antes de publicar:

- testes executados,
- documentação atualizada,
- build validada,
- APIs funcionando,
- variáveis configuradas.

---

# Objetivo Final

Garantir deploy:

- seguro,
- previsível,
- escalável,
- estável.