# docs/dev/setup.md

# Setup do Ambiente

## Objetivo

Este documento explica como configurar o ambiente de desenvolvimento do Versin.

---

# Requisitos

## Ferramentas

- Git
- Flutter SDK
- Dart SDK
- Python 3.11+
- Node.js
- Supabase CLI

---

# Estrutura Recomendada

```bash
versin/
│
├── frontend/
├── backend/
├── ai/
├── docs/
├── scripts/
└── assets/
```

# Clonando o Projeto

```bash
git clone https://github.com/seuusuario/versin.git
```

```bash
cd versin
```

# Flutter

## Instalar dependências

```bash
flutter pub get
```

## Executar projeto

```bash
flutter run
```

---

# Backend

## Instalar dependências

```bash
npm install
```

## Rodar ambiente local

```bash
npm run dev
```

---

# IA

## Criar ambiente virtual

```bash
python -m venv venv
```

## Ativar ambiente

Linux/macOS:

```bash
source venv/bin/activate
```

Windows:

```bash
venv\Scripts\activate
```

## Instalar dependências

```bash
pip install -r requirements.txt
```

---

# Supabase

## Login

```bash
supabase login
```

## Inicializar

```bash
supabase start
```

---

# Configuração de Ambiente

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

Nunca envie:

- .env
- chaves privadas
- tokens
- credenciais

---

# Objetivo Final

Garantir:

- ambiente padronizado,
- desenvolvimento consistente,
- facilidade de onboarding.