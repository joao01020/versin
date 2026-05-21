# Chat Components Module

## Português
Este diretório contém os componentes de interface (UI) responsáveis pela experiência de conversação do módulo de Chat. A organização segue o princípio de separação por responsabilidade funcional:

- **/list**: Contém os componentes responsáveis pela **leitura** e exibição das mensagens (`chat_list_view` e `chat_message_bubble`).
- **/input**: Contém os componentes responsáveis pela **escrita** e interação do usuário (`chat_bottom_bar` e `chat_input_area`).

Esta estrutura facilita a manutenção do layout e garante que as regras de negócio de visualização não se misturem com as regras de entrada de dados.

---

## English
This directory contains the UI components responsible for the conversation experience within the Chat module. The organization follows the principle of separation of concerns:

- **/list**: Contains components responsible for **reading** and displaying messages (`chat_list_view` and `chat_message_bubble`).
- **/input**: Contains components responsible for **writing** and user interaction (`chat_bottom_bar` and `chat_input_area`).

This structure facilitates layout maintenance and ensures that display business rules do not interfere with input data rules.