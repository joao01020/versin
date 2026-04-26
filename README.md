# Versin - Inteligência Artificial a Serviço do Lyricist 🎤

> "Transformando rimas soltas em composições estruturadas."

O **Versin** nasceu da intersecção entre a tecnologia e a engenharia de áudio. Mais do que um simples assistente de texto, ele foi projetado para ser o parceiro de composição definitivo para artistas de **Trap, Rap e Phonk**.

---

## 🔥 O Propósito: Por que o Versin existe?

No processo de criação de uma letra de Rap, o artista muitas vezes enfrenta dois grandes obstáculos:
1. **O Bloqueio da Próxima Linha:** A dificuldade de encontrar a rima perfeita que mantenha o sentido e a sonoridade.
2. **A Quebra de Fluxo:** Ter que sair do estado criativo para pesquisar dicionários de rimas ou sinônimos em abas separadas.

O Versin resolve isso centralizando o fluxo criativo. Ele utiliza IA para entender o contexto da sua letra e sugerir rimas que não apenas "combinam no final", mas que respeitam a métrica e a estética do gênero.

---

## 💡 A Visão do Desenvolvedor & Produtor

Como produtor musical (FL Studio) e desenvolvedor, projetei o Versin para funcionar como um **"Plugin de Composição"**. 

* **Foco no Workflow:** Menos distrações, mais rimas.
* **Contexto Musical:** Diferente de IAs genéricas, o Versin é treinado para entender gírias, fonéticas e o "feeling" necessário para letras de rua e beats pesados.
* **Agilidade:** Interface limpa, organizada e rápida (rodando nativamente em Linux/Apolo).

---

## 🛠️ O Que o Versin Entrega?

### 🧩 Brainstorming Assistido
O chat não apenas responde, ele colabora. Ao digitar um verso, o Versin analisa a terminação e sugere variações baseadas em:
* **Rimas Perfeitas (Consoantes):** Ex: *Coração / Visão*
* **Rimas Imperfeitas (Assonantes):** Ex: *Pista / Brisa* (focadas na vogal tônica, essenciais no Trap).

### ⚙️ Ajuste de "Nível de Rima"
Através do Drawer de configurações, o usuário pode definir quão complexas ou raras devem ser as sugestões da IA, adaptando-se desde um Freestyle rápido até uma letra de Storytelling densa.

### 📦 Estrutura Profissional (Clean Arch)
Para garantir que o app seja escalável e robusto, utilizei **Clean Architecture**. Isso separa a lógica de rimas (Domain) das chamadas de API (Data) e da interface (Presentation), permitindo que o Versin cresça sem perder a performance.

---

## 🚀 O Futuro do Projeto
O Versin é um ecossistema em evolução. O roadmap inclui:
- **Vitrine de Beats:** Onde produtores poderão expor seus beats para os artistas.
- **Dicionário Fonético Próprio:** Uma engine de busca de rimas otimizada para o português brasileiro.
- **Exportação Direta:** Enviar a letra estruturada para PDF ou formatos compatíveis com DAWs.
## 📂 Organização de Pastas

```text
lib/
 └── features/
      └── rhymes/
           ├── data/          # Implementações de repositórios e fontes de dados
           ├── domain/        # Entidades e Casos de Uso (Usecases)
           └── presentation/  # UI (Pages, Widgets e Components)
                ├── pages/    # ChatPage, SettingsPage, etc.
                └── widgets/  # Componentes reutilizáveis (Drawer, Bubbles, Cards)
---






[x] Estruturação da Clean Architecture.

[x] Migração e organização de widgets por componentes.

[ ] Implementação total da integração com Supabase.

[ ] Refinamento do algoritmo de rimas em português.

[ ] Lançamento da Vitrine de Beats integrada.


O Diferencial: Inteligência Fonética e Ecossistema Colaborativo

O Versin vai além de um simples chat. Ele foi projetado para aprender com o fluxo real dos artistas e criar pontes entre os diferentes agentes da cena musical.
1. Banco de Dados Customizado de Rimas

O projeto utiliza uma estrutura de dados robusta (Supabase) que permite:

    Alimentação Dinâmica: O usuário pode adicionar suas próprias rimas e variações fonéticas ao banco de dados pessoal ou global.

    Sugestão Inteligente: Diferente de algoritmos estáticos, o motor do Versin consulta o banco de dados para sugerir rimas baseadas na frequência de uso, estilo do artista e métrica do verso, garantindo que a sugestão faça sentido dentro da "estética" do gênero escolhido.

    Personalização de Vocabulário: Quanto mais você escreve, mais a IA entende seu vocabulário preferido, gírias e as conexões fonéticas que você costuma usar.

2. Sincronização e Cloud (Storage)

Através da integração com o Supabase Storage, o Versin permite que o artista:

    Suba seus Arquivos: Armazene rascunhos, arquivos de áudio (vozes guias) e arquivos de texto em um ambiente seguro e acessível de qualquer lugar.

    Versionamento de Letras: Nunca perca uma ideia. O sistema mantém o histórico de alterações das composições, permitindo voltar a versões anteriores de uma rima.

3. Conexão entre Artistas, Compositores e Beatmakers

O Versin funciona como um hub criativo:

    Compartilhamento de Letras: Envie suas composições diretamente para outros artistas ou compositores dentro da plataforma para co-escrita em tempo real.

    Integração com Beatmakers: O app conta com uma seção dedicada onde beatmakers podem subir seus instrumentais. O letrista pode ouvir o beat enquanto escreve, garantindo que o flow e a métrica estejam em perfeita harmonia com o instrumental.

    Networking Orgânico: O ambiente facilita o encontro de talentos, permitindo que um letrista encontre o beat ideal para sua nova composição e vice-versa.

🛠️ Especificações Técnicas das Funcionalidades

    Database Schema: Modelagem relacional focada em performance para buscas fonéticas rápidas.

    Storage API: Implementação eficiente para upload e download de assets multimídia.

    Real-time Collaboration: Uso de WebSockets ou Realtime do Supabase para permitir a escrita conjunta entre dois usuários.





----------------


🧠 Knowledge Graph & Estruturação de Rimas (O "Obsidian Musical")

Inspirado na metodologia Zettelkasten e em ferramentas de pensamento como o Obsidian, o Versin introduz uma abordagem científica para a composição. O objetivo não é apenas escrever letras, mas construir um corpo de conhecimento fonético que cresce com o artista.
🚀 Do Caos à Estrutura

Diferente de editores de texto lineares, o Versin permite que o usuário crie uma rede interconectada de ideias:

    Links Bidirecionais: Cada rima, metáfora ou punchline pode ser transformada em uma "nota". Se você usar uma referência em uma letra, o Versin cria automaticamente um link de volta para todas as outras composições onde aquela ideia apareceu.

    Aprendizado Ativo: Ao estruturar suas rimas em um grafo de conexões, o letrista ganha consciência sobre seus próprios padrões, vícios de linguagem e evolução técnica, acelerando o domínio sobre sua métrica e vocabulário.

    Mapeamento de Flow: O usuário pode categorizar e conectar diferentes estilos de flow a instrumentais e letras específicas, criando um mapa visual de sua versatilidade artística.

🛠️ Implementação Técnica (Graph Architecture)

Para viabilizar essa "ponte de conhecimento", o projeto utiliza:

    Arquitetura de Grafos no Backend: Implementação de relacionamentos complexos no banco de dados para rastrear conexões entre letras, tags fonéticas e referências temáticas.

    Suporte a Markdown: Escrita técnica utilizando sintaxe Markdown, permitindo formatação rápida e links internos entre rimas e notas de produção.

    Visualização de Dados: Integração de visualização em grafo para que o artista veja, de forma macro, como suas ideias se ramificam e quais temas dominam sua obra.

🎯 O Propósito Educativo

O Versin força o artista a ser um arquiteto da própria música. Ao "conectar as bolinhas", o compositor não apenas termina uma música, mas alimenta um ecossistema de rimas que serve de base para todas as suas criações futuras.
Como isso valoriza o seu repositório:

    Explica o "Porquê": Você mostra que entende a psicologia por trás da organização de ideias (o conceito de Personal Knowledge Management).

    Destaque Técnico: Mencionar "Arquitetura de Grafos" e "Links Bidirecionais" mostra que você sabe lidar com estruturas de dados que vão além do simples CRUD (Create, Read, Update, Delete).

    Inovação: Você posiciona o Versin como algo único: um "Obsidian para o Rap".



## 👨‍💻 Sobre o Autor

**João Vitor**
*Engenheiro de Áudio & Desenvolvedor Júnior*

Unindo o conhecimento técnico de mixagem e produção no FL Studio com a precisão do desenvolvimento em Flutter e Python para criar ferramentas que fazem a diferença na mão do artista.

---
"Código é arte, rima é algoritmo."