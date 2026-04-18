# Guia do Gestor — Portal QM SAF Botafogo

> **Para:** Gestores de setor · **Acesso:** Somente registros dos seus setores

---

## Sumário

1. [Fazendo login](#1-fazendo-login)
2. [Sua tela inicial](#2-sua-tela-inicial)
3. [Adicionar um registro manualmente](#3-adicionar-um-registro-manualmente)
4. [Importar registros em lote (planilha)](#4-importar-registros-em-lote-planilha)
5. [Ver e filtrar o histórico](#5-ver-e-filtrar-o-histórico)
6. [Exportar o histórico](#6-exportar-o-histórico)
7. [Excluir registros](#7-excluir-registros)
8. [Redefinir sua senha](#8-redefinir-sua-senha)
9. [Entendendo a classificação QM](#9-entendendo-a-classificação-qm)

---

## 1. Fazendo login

1. Abra o portal no navegador.
2. Digite seu **e-mail** e **senha**.
3. Clique em **Entrar**.

Você será direcionado diretamente para o seu painel.

> Caso o login não funcione, clique em **"Esqueceu a senha?"** e siga as instruções enviadas para o seu e-mail.

---

## 2. Sua tela inicial

Após o login, você verá o **Painel do Gestor** com:

| Elemento | O que mostra |
|---|---|
| **Total de Registros** | Todos os registros que você já lançou |
| **Registros do Mês** | Apenas os registros do mês atual |
| **Novo Registro** | Abre o formulário para lançar um registro manualmente |
| **Importar Planilha** | Permite importar vários registros de uma vez via Excel |
| **Ver Histórico** | Abre a lista de todos os seus registros |

---

## 3. Adicionar um registro manualmente

1. Clique no botão **Novo Registro**.
2. Preencha o formulário:

### Campos do formulário

**Tipo de Evento**
Escolha entre:
- `Jogo` — para jogos das categorias do clube
- `Outros` — para outros tipos de evento

---

**Nome do Evento**
Escreva o nome do evento. Exemplos: `Botafogo x Flamengo`, `Treino Sub-20`.

---

**Data do Evento**
Selecione a data em que o evento acontece (não a data de hoje).

---

**Horário do Evento**
Escolha o horário de início do evento. Os horários disponíveis estão em intervalos de **15 minutos** (ex.: 19:00, 19:15, 19:30...).

---

**Categoria do Jogo** *(somente para eventos do tipo "Jogo")*
Selecione a categoria. Opções disponíveis:
- Futebol Masculino Profissional
- Sub-20 Masculino
- Sub-17 Masculino
- Sub-15 Masculino
- Demais Categorias Masculino
- Futebol Profissional Feminino
- Futebol de Base Feminino

---

**Tipo QM**
Selecione `A` ou `B`. O sistema calcula automaticamente a classificação final (A, B, C ou D) e o valor em reais com base no tipo, dia da semana e horário. Veja a [seção 9](#9-entendendo-a-classificação-qm).

---

**Funcionário**
Selecione o nome do funcionário na lista. Caso o funcionário não esteja na lista, selecione `Outros`.

---

**Observações**
- **Obrigatório** quando o Tipo de Evento for `Outros`.
- **Obrigatório** quando o Funcionário for `Outros`.
- Nos demais casos, é opcional.

---

3. Clique em **Salvar Registro**.
4. Uma mensagem de confirmação aparecerá e o registro será listado no histórico.

---

## 4. Importar registros em lote (planilha)

Use essa opção quando precisar lançar vários registros de uma vez.

### Passo 1 — Baixar o modelo

1. Clique em **Importar Planilha**.
2. Clique em **Baixar Modelo** para salvar o arquivo `modelo_quadro_movel.xlsx`.
3. Abra o arquivo no **Excel** ou **Google Planilhas**.

O arquivo tem três abas:
- **Registros** — onde você preenche os dados
- **Listas** — listas de referência (funcionários, horários, categorias, etc.)
- **Tutorial** — explicação de cada coluna

### Passo 2 — Preencher a planilha

Preencha a aba **Registros** a partir da **linha 2**. Não altere ou apague a linha 1 (cabeçalhos).

| Coluna | Obrigatório? | O que preencher |
|---|---|---|
| Tipo de Evento | Sim | `Jogo` ou `Outros` |
| Nome do Evento | Sim | Texto livre |
| Data do Evento | Sim | `DD/MM/AAAA` — ex.: `16/04/2026` |
| Horário do Evento | Sim | `HH:MM` — ex.: `19:00` (múltiplos de 15 min) |
| Categoria do Jogo | Só para Jogo | Deve ser uma das categorias da aba Listas |
| Tipo QM | Sim | Apenas `A` ou `B` |
| Funcionário | Sim | Nome exato do funcionário ou `Outros` |
| Observações | Condicional | Obrigatório se Tipo = "Outros" ou Funcionário = "Outros" |

> **Atenção:**
> - Para eventos do tipo `Outros`, a coluna **Categoria do Jogo deve ficar em branco**.
> - Os nomes dos funcionários devem ser **exatamente iguais** ao cadastro no sistema (use a aba Listas para consultar).

### Passo 3 — Importar

1. Salve o arquivo como `.xlsx`.
2. No portal, clique em **Importar Planilha**.
3. Arraste o arquivo para a área indicada ou clique para selecionar.
4. O sistema verificará cada linha. Se houver erros, eles serão exibidos com o número da linha e o motivo.
5. Corrija os erros na planilha e importe novamente, se necessário.
6. Se houver registros duplicados (mesma data + mesmo funcionário), o sistema avisará — você escolhe se quer importar mesmo assim ou ignorar.

### Erros comuns

| Mensagem de erro | O que causou | Como corrigir |
|---|---|---|
| `Tipo QM inválido` | Coluna com valor diferente de A ou B | Preencha apenas com `A` ou `B` |
| `Formato de data inválido` | Data fora do padrão | Use `DD/MM/AAAA` (ex.: `16/04/2026`) |
| `Categoria obrigatória` | Tipo = Jogo sem categoria | Preencha a Categoria do Jogo |
| `Observações obrigatórias` | Tipo = Outros sem observação | Preencha as Observações |
| `Funcionário não encontrado` | Nome digitado diferente do cadastro | Consulte a aba Listas para o nome exato |
| `Cabeçalho ausente` | Coluna renomeada ou apagada | Use o modelo original sem alterar a linha 1 |

---

## 5. Ver e filtrar o histórico

1. Clique em **Ver Histórico** no painel.
2. Você verá todos os registros do(s) seu(s) setor(es).

### Filtros disponíveis

Use os campos de busca no topo da tabela para filtrar por:
- Nome do evento
- Nome do funcionário
- Categoria do jogo
- Período (data inicial e data final)
- Observações

Os filtros são aplicados automaticamente conforme você digita.

### Informações exibidas na tabela

| Coluna | Descrição |
|---|---|
| Data Criação | Quando o registro foi lançado no sistema |
| Evento | Nome do evento |
| Data Evento | Data em que o evento ocorre |
| Horário | Horário do evento |
| Categoria | Categoria do jogo |
| QM | Classificação calculada (A, B, C ou D) |
| Funcionário | Nome do funcionário |
| Setor | Setor do funcionário |
| Observações | Observações inseridas |

---

## 6. Exportar o histórico

1. Acesse **Ver Histórico**.
2. Aplique filtros se quiser exportar apenas um período ou funcionário específico.
3. Clique em **Exportar CSV** ou **Exportar XLSX**.
4. O arquivo `historico_registros.xlsx` (ou `.csv`) será baixado automaticamente.

> A exportação considera **apenas os registros visíveis** após os filtros aplicados. Para exportar tudo, limpe os filtros antes de exportar.

---

## 7. Excluir registros

### Excluir um registro

Clique no ícone de lixeira ao lado do registro e confirme.

### Excluir vários registros de uma vez

1. Marque as caixas de seleção dos registros que deseja excluir.
2. Clique em **Excluir Selecionados**.
3. Uma janela de confirmação mostrará os registros que serão removidos.
4. Clique em **Confirmar** para concluir.

> **Atenção:** a exclusão é permanente e não pode ser desfeita.

---

## 8. Redefinir sua senha

1. Na tela de login, clique em **"Esqueceu a senha?"**.
2. Informe seu e-mail cadastrado.
3. Clique em **Enviar link de redefinição**.
4. Acesse o e-mail recebido e clique no link.
5. Cadastre sua nova senha.

---

## 9. Entendendo a classificação QM

Ao salvar um registro, o sistema calcula automaticamente a **classificação QM** (A, B, C ou D) e o **valor** correspondente, com base em três fatores:

1. O **Tipo QM** que você informou (A ou B)
2. O **dia da semana** do evento
3. O **horário** do evento

### Tabela de classificação

| Tipo QM | Condição | Resultado | Valor |
|---|---|---|---|
| A | Fim de semana (sáb/dom) **ou** horário ≥ 21:00 | **A** | R$ 400 |
| B | Fim de semana (sáb/dom) **ou** horário ≥ 21:00 | **B** | R$ 200 |
| A | Dia útil (seg–sex) **e** horário < 21:00 | **C** | R$ 200 |
| B | Dia útil (seg–sex) **e** horário < 21:00 | **D** | R$ 100 |

### Exemplos práticos

| Situação | Tipo QM | Resultado |
|---|---|---|
| Sexta-feira, 19:00 | A | C — R$ 200 |
| Sexta-feira, 21:00 | A | A — R$ 400 |
| Sábado, 16:00 | B | B — R$ 200 |
| Quarta-feira, 20:59 | B | D — R$ 100 |
| Domingo, qualquer horário | A | A — R$ 400 |

> O horário **21:00 em ponto** já conta como noturno (≥ 21:00 = classificação mais alta).

---

*Em caso de dúvidas ou problemas de acesso, contate o administrador do sistema.*
