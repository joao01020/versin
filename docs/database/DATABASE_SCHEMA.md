# DATABASE_SCHEMA.md

# Versin Database Schema — Produção (V2.8)

> Estrutura principal do banco de dados do ecossistema Versin.
>
> Foco em:
>
> - automação de perfis,
> - segurança,
> - memória contextual,
> - histórico criativo,
> - escalabilidade.

---

# Objetivo

O schema do Versin foi projetado para:

- manter rastreabilidade criativa,
- automatizar criação de perfis,
- preservar segurança com RLS,
- suportar memória contextual,
- permitir expansão futura do sistema cognitivo.

---

# Estrutura Principal

## Tabelas Base

```text
profiles
lyrics_history
```

---

# Fluxo Geral

```text
Novo usuário
    ↓
auth.users
    ↓
Trigger automática
    ↓
Criação de profile
    ↓
Uso da plataforma
    ↓
Registro de letras
    ↓
Memória contextual
```

---

# Profiles

Tabela principal de usuários.

Responsável por:

- identidade do usuário,
- configurações,
- memória contextual,
- wallet,
- perfil artístico.

---

## Estrutura

```sql
CREATE TABLE IF NOT EXISTS public.profiles (

id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,

username TEXT UNIQUE,

wallet_address TEXT UNIQUE,

ia_memory TEXT,

settings JSONB DEFAULT '{"mode": "Rhyme"}'::jsonb,

created_at TIMESTAMP WITH TIME ZONE DEFAULT now()

);
```

---

# Campos

| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID | ID do usuário |
| username | TEXT | Nome único |
| wallet_address | TEXT | Wallet do usuário |
| ia_memory | TEXT | Memória contextual |
| settings | JSONB | Configurações da IA |
| created_at | TIMESTAMP | Data de criação |

---

# Lyrics History

Tabela responsável pelo histórico criativo.

Armazena:

- letras,
- contexto musical,
- vibe,
- BPM,
- estrutura,
- hashes.

---

## Estrutura

```sql
CREATE TABLE IF NOT EXISTS public.lyrics_history (

id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

content TEXT DEFAULT '',

hash_signature TEXT DEFAULT '',

bpm INT DEFAULT 120,

structure TEXT,

vibe TEXT,

theme TEXT,

vocal_technique TEXT,

created_at TIMESTAMP WITH TIME ZONE DEFAULT now()

);
```

---

# Campos Criativos

| Campo | Objetivo |
|---|---|
| content | Letra armazenada |
| hash_signature | Assinatura criptográfica |
| bpm | BPM da composição |
| structure | Estrutura da música |
| vibe | Atmosfera emocional |
| theme | Tema principal |
| vocal_technique | Técnica vocal |

---

# Automação de Perfis

O sistema cria automaticamente um profile após registro no auth.users.

---

# Trigger Function

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()

RETURNS trigger AS $$

BEGIN

INSERT INTO public.profiles (id, username)

VALUES (

new.id,

split_part(new.email, '@', 1)

);

RETURN new;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

# Objetivo

Automatizar:

- criação de perfil,
- username inicial,
- integração com auth.

---

# Trigger

```sql
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created

AFTER INSERT ON auth.users

FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

# Segurança — RLS

O Versin utiliza Row Level Security para garantir privacidade.

---

# Ativação

```sql
ALTER TABLE public.lyrics_history ENABLE ROW LEVEL SECURITY;
```

---

# Política de Visualização

```sql
CREATE POLICY "Usuários podem ver suas próprias letras"

ON public.lyrics_history

FOR SELECT TO authenticated

USING (auth.uid() = user_id);
```

---

# Política de Inserção

```sql
CREATE POLICY "Usuários podem inserir suas próprias letras"

ON public.lyrics_history

FOR INSERT TO authenticated

WITH CHECK (auth.uid() = user_id);
```

---

# Segurança do Sistema

As políticas garantem:

- isolamento de dados,
- privacidade,
- proteção contra acesso indevido.

---

# Correção Estrutural

O sistema também corrige automaticamente versões antigas do schema.

---

# Migração

```sql
DO $$

BEGIN

IF EXISTS (

SELECT 1

FROM information_schema.columns

WHERE table_name='lyrics_history'

AND column_name='profile_id'

)

THEN

ALTER TABLE public.lyrics_history

RENAME COLUMN profile_id TO user_id;

END IF;

END $$;
```

---

# Objetivo Futuro

O schema foi preparado para futura expansão incluindo:

- memória vetorial,
- embeddings,
- projetos colaborativos,
- hashes evolutivas,
- sistema jurídico,
- matchmaking,
- reputação,
- contexto semântico.

---

# Filosofia Técnica

O banco do Versin não existe apenas para armazenar dados.

Ele existe para preservar:

- identidade artística,
- contexto criativo,
- continuidade musical,
- evolução cognitiva do usuário.

---

# Estrutura Futuramente Planejada

```text
profiles
lyrics_history
semantic_memory
creative_embeddings
projects
collaborators
contracts
hash_registry
reputation_system
notifications
cognitive_context
```

---

# Objetivo Final

Construir uma infraestrutura:

- segura,
- modular,
- cognitiva,
- contextual,
- escalável,
- preparada para evolução artística contínua.