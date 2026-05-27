# 🪷 Flor de Luna — Gestão de Ponto Cruz

O **Flor de Luna** é um aplicativo mobile e web especializado para artesãos e bordadores de ponto cruz. Ele foi projetado para substituir o caderno de papel por uma gestão digital inteligente, unindo o controle de encomendas, cálculo automatizado de materiais/preços e gerenciamento de estoque de meadas em uma única interface delicada e segura.

---

## 🎨 Identidade Visual & Cores
O design do aplicativo foi inspirado na delicadeza do artesanato feito à mão, utilizando uma paleta de cores equilibrada para o ecossistema iOS:
* **Rosa Pétala (`#F39AA5`):** Botões principais e ações de destaque.
* **Verde Floresta (`#3C6246`):** Identidade mística, títulos e status positivos.
* **Creme Pergaminho (`#F9EFE1`):** Fundo das telas (conforto visual que remete ao linho/etamine).
* **Ouro Celestial (`#F4C47C`):** Alertas de estoque e prazos intermediários.

---

## ✨ Funcionalidades Principais

* **Painel de Production Ativa:** Visualização rápida de encomendas organizadas por prazos de entrega e status de produção (`Na Fila`, `Em Produção`, `Concluído`).
* **Calculadora Inteligente de Ponto Cruz:** Calcula automaticamente as dimensões do tecido em centímetros com base na quantidade de pontos (largura x altura) para o tecido Etamine.
* **Precificação Automatizada:** Sugere o preço justo da peça com base no total de pontos do gráfico (estimando a velocidade média de produção por hora) somado ao custo fixo de materiais.
* **Estoque Inteligente de Linhas:** Catálogo para busca rápida de meadas DMC, Anchor ou linhas sem código, com alertas visuais automáticos de `Pouca Linha` ou `Comprar`.
* **Relatório Financeiro & Cobrança:** Exibe o faturamento bruto do mês, valores já recebidos e uma "Lista de Rua" com clientes que pagaram apenas o sinal (entrada de 50%), permitindo disparar mensagens de cobrança direto para o WhatsApp com um clique.
* **Nuvem Segura & Autenticação:** Totalmente integrado ao Firebase Auth e Cloud Firestore para sincronização em tempo real e proteção de dados sigilosos do negócio.

---

## 📂 Estrutura do Projeto (Flutter)

A arquitetura do código segue o padrão de responsabilidade limpa no diretório `lib/`:

```darkmatter
lib/
├── main.dart                  # Inicialização, rotas e configuração do ThemeData global
├── models/
│   ├── linha_model.dart       # Molde de dados para as meadas do inventário
│   └── pedido_model.dart      # Molde de dados do cliente, finanças e pontos
├── screens/
│   ├── home_screen.dart       # Painel de controle e lista de produção reativa
│   ├── cadastro_pedido_screen.dart # Formulário de entrada com lógica de cálculo de tecido
│   ├── editar_pedido_screen.dart   # Atualização de status e observações na nuvem
│   ├── estoque_screen.dart    # Filtro reativo de marcas e pop-up de cadastro de linhas
│   └── financeiro_screen.dart # Balanço de faturamento e fluxo de devedores
└── services/
    ├── auth_service.dart      # Conexão com o Firebase Authentication
    └── firestore_service.dart # Regras de persistência e Streams (tempo real) do Firestore
```

---

## 🛠️ Tecnologias Utilizadas
* Framework Frontend: Flutter (Dart)
* Banco de Dados: Cloud Firestore (NoSQL)
* Autenticação: Firebase Authentication
* Tipografia: Google Fonts (Montserrat e Cormorant Garamond)
* Comunicação: URL Launcher (Integração nativa com a API do WhatsApp)

---

> **Desenvolvido por:** Kassandra Oliveira  
> *Com carinho para organizar a magia do ponto cruz. ✨*
