# Manual do Usuário — Portal QM SAF Botafogo

> **Versão:** 2026 · **Público:** Gestores e Administradores

---

## Sumário

1. [Acesso ao Sistema](#1-acesso-ao-sistema)
2. [Perfis de Usuário](#2-perfis-de-usuário)
3. [Painel do Gestor](#3-painel-do-gestor)
4. [Adicionar Registro Manualmente](#4-adicionar-registro-manualmente)
5. [Importar Registros via Planilha (XLSX)](#5-importar-registros-via-planilha-xlsx)
6. [Exportar Histórico](#6-exportar-histórico)
7. [Consultar e Filtrar Histórico](#7-consultar-e-filtrar-histórico)
8. [Painel do Administrador](#8-painel-do-administrador)
9. [Gestão de Setores](#9-gestão-de-setores)
10. [Gestão de Categorias](#10-gestão-de-categorias)
11. [Gestão de Funcionários](#11-gestão-de-funcionários)
12. [Gestão de Usuários (Gestores)](#12-gestão-de-usuários-gestores)
13. [Regras de Validação](#13-regras-de-validação)
14. [Lógica de Classificação QM](#14-lógica-de-classificação-qm)
15. [Dúvidas Frequentes](#15-dúvidas-frequentes)

---

## 1. Acesso ao Sistema

### Login

1. Acesse a URL do portal no seu navegador.
2. Informe seu **e-mail** e **senha** cadastrados.
3. Clique em **Entrar**.

### Esqueci minha senha

1. Na tela de login, clique em **"Esqueceu a senha?"**.
2. Digite seu e-mail e clique em **Enviar link de redefinição**.
3. Acesse o link enviado para o seu e-mail e cadastre uma nova senha.

### Primeiro acesso ao sistema (apenas administrador)

Na primeira vez que o sistema é aberto, é exibida uma tela de **configuração inicial** para criar o administrador principal. Após isso, essa tela não aparece mais.

---

## 2. Perfis de Usuário

| Perfil | O que pode fazer |
|---|---|
| **Administrador** | Acesso total: gerencia setores, categorias, funcionários, usuários, regras, e vê todos os registros |
| **Gestor** | Adiciona e visualiza registros dos seus setores; importa e exporta planilhas do seu setor |

---

## 3. Painel do Gestor

Ao fazer login como **Gestor**, você verá:

- **Total de Registros** — quantidade total de registros lançados por você.
- **Registros do Mês** — registros do mês atual.
- Três botões de ação rápida:
  - **Novo Registro** — adicionar um registro manualmente.
  - **Importar Planilha** — importar vários registros via arquivo XLSX.
  - **Ver Histórico** — consultar todos os registros já lançados.

---

## 4. Adicionar Registro Manualmente

1. Clique em **Novo Registro** no painel.
2. Preencha os campos:

| Campo | Descrição |
|---|---|
| **Tipo de Evento** | "Jogo" ou "Outros" |
| **Nome do Evento** | Nome do evento (ex.: "Botafogo x Flamengo") |
| **Data do Evento** | Data em que o evento ocorre |
| **Horário do Evento** | Horário de início (intervalos de 15 minutos) |
| **Categoria do Jogo** | Obrigatório se Tipo = "Jogo" (ex.: Futebol Masculino Profissional) |
| **Tipo QM** | "A" ou "B" — define a classificação QM |
| **Funcionário** | Selecione o funcionário ou "Outros" |
| **Observações** | Obrigatório se Tipo = "Outros" ou Funcionário = "Outros" |

3. Clique em **Salvar**. O sistema calculará automaticamente a **classificação QM** (A, B, C ou D) e o **valor** correspondente.

> **Dica:** A classificação QM é determinada pelo tipo (A/B), dia da semana e horário. Veja a [seção 14](#14-lógica-de-classificação-qm) para entender a lógica.

---

## 5. Importar Registros via Planilha (XLSX)

A importação permite lançar vários registros de uma só vez a partir de uma planilha Excel.

### Passo 1 — Baixar o modelo

1. Clique em **Importar Planilha** no painel.
2. Clique em **Baixar Modelo** para obter o arquivo `modelo_quadro_movel.xlsx`.
3. Abra o arquivo no Excel ou Google Planilhas.

O arquivo modelo contém **3 abas**:

| Aba | Conteúdo |
|---|---|
| **Registros** | Aqui você preenche os dados |
| **Listas** | Listas de referência (funcionários, categorias, horários, etc.) |
| **Tutorial** | Instruções detalhadas para cada coluna |

### Passo 2 — Preencher a planilha

Preencha a aba **Registros** a partir da linha 2 (linha 1 contém os cabeçalhos — **não apague**).

| Coluna | Obrigatório | Valores aceitos |
|---|---|---|
| **Tipo de Evento** | Sim | `Jogo` ou `Outros` |
| **Nome do Evento** | Sim | Texto livre |
| **Data do Evento** | Sim | `DD/MM/AAAA` ou `AAAA-MM-DD` |
| **Horário do Evento** | Sim | `HH:MM` (ex.: `19:00`, `21:30`) em intervalos de 15 min |
| **Categoria do Jogo** | Só para Jogo | Ver lista abaixo |
| **Tipo QM** | Sim | Apenas `A` ou `B` |
| **Funcionário** | Sim | Nome exato do funcionário ou `Outros` |
| **Observações** | Condicional | Obrigatório se Tipo = "Outros" ou Funcionário = "Outros" |

**Categorias de Jogo disponíveis:**
- Futebol Masculino Profissional
- Sub-20 Masculino
- Sub-17 Masculino
- Sub-15 Masculino
- Demais Categorias Masculino
- Futebol Profissional Feminino
- Futebol de Base Feminino

> **Atenção:** Para linhas do tipo "Outros", a coluna **Categoria do Jogo deve ficar em branco**.

### Passo 3 — Importar o arquivo

1. Salve o arquivo no formato `.xlsx`.
2. No portal, clique em **Importar Planilha**.
3. Arraste o arquivo para a área indicada ou clique para selecionar.
4. O sistema validará cada linha. Erros serão exibidos com a linha e o motivo.
5. Se houver registros **duplicados** (mesma data + funcionário), o sistema irá avisar — você pode optar por ignorá-los ou importar mesmo assim.
6. Ao final, uma mensagem confirmará quantos registros foram importados com sucesso.

### Erros comuns na importação

| Erro | Causa provável |
|---|---|
| `Tipo QM inválido` | Valor diferente de "A" ou "B" (ex.: "C", em branco) |
| `Formato de data inválido` | Data fora do padrão DD/MM/AAAA ou AAAA-MM-DD |
| `Categoria obrigatória` | Tipo = "Jogo" mas Categoria do Jogo está em branco |
| `Observações obrigatórias` | Tipo = "Outros" ou Funcionário = "Outros" sem observação |
| `Funcionário não encontrado` | Nome digitado difere do cadastro no sistema |
| `Cabeçalho ausente` | A linha de cabeçalho foi apagada ou uma coluna renomeada |

---

## 6. Exportar Histórico

1. Acesse **Ver Histórico** no painel.
2. Aplique filtros se desejar (ver seção 7).
3. Clique em **Exportar CSV** ou **Exportar XLSX**.
4. O arquivo `historico_registros.xlsx` (ou `.csv`) será baixado automaticamente.

**Colunas exportadas:**

| Coluna | Descrição |
|---|---|
| Data Criação | Data e hora em que o registro foi inserido |
| Evento | Nome do evento |
| Data Evento | Data do evento |
| Horário | Horário do evento |
| Cat. Jogo | Categoria do jogo |
| QM | Classificação calculada (A, B, C ou D) |
| Chapa | Matrícula do funcionário |
| Funcionário | Nome do funcionário |
| Setor | Setor do funcionário |
| Gestor Lançador | Nome do gestor que registrou |
| Observações | Observações do registro |

---

## 7. Consultar e Filtrar Histórico

Na tela de histórico, você pode filtrar os registros por:

- **Nome do Evento**
- **Funcionário**
- **Categoria do Jogo**
- **Data inicial / Data final**
- **Observações**
- **Setor** (apenas administradores)
- **Gestor** (apenas administradores)

Para **excluir registros**:
1. Marque as caixas de seleção dos registros desejados.
2. Clique em **Excluir Selecionados**.
3. Confirme a exclusão na janela de aviso.

---

## 8. Painel do Administrador

O administrador possui acesso a tudo que o gestor vê, mais:

- **Histórico Completo** — todos os registros de todos os gestores e setores.
- **Gerenciamento** de Setores, Categorias, Funcionários, Usuários e Regras.

---

## 9. Gestão de Setores

**Caminho:** Painel Admin → Setores

- **Adicionar:** clique em **Novo Setor**, informe o nome e salve.
- **Editar:** clique no ícone de edição ao lado do setor.
- **Excluir:** clique no ícone de lixeira (requer confirmação).
- **Exportar:** baixa a lista de setores em XLSX.
- **Importar:** sobe um arquivo XLSX com novos setores em lote.

---

## 10. Gestão de Categorias

**Caminho:** Painel Admin → Categorias

- Funciona da mesma forma que Setores.
- Categorias são usadas no campo **Categoria do Jogo** dos registros.

---

## 11. Gestão de Funcionários

**Caminho:** Painel Admin → Funcionários

- **Adicionar:** informe nome, matrícula (chapa) e selecione um ou mais setores.
- **Editar / Excluir:** ícones ao lado de cada funcionário.
- **Filtrar:** pesquise por nome, matrícula ou setor.
- **Exportar / Importar:** igual às outras seções.

> Funcionários podem ser associados a **múltiplos setores**.

---

## 12. Gestão de Usuários (Gestores)

**Caminho:** Painel Admin → Usuários

### Criar novo gestor

1. Clique em **Novo Usuário**.
2. Preencha nome, e-mail e senha.
3. Selecione o perfil (**Gestor**) e os setores que ele gerenciará.
4. Clique em **Salvar**.

O usuário receberá um e-mail de confirmação e poderá fazer login com as credenciais cadastradas.

### Editar usuário

- Clique no ícone de edição para alterar nome, setores ou perfil.
- **Não é possível alterar o e-mail** após o cadastro.

### Excluir usuário

- Clique no ícone de lixeira.
- O usuário será removido e não poderá mais fazer login.

---

## 13. Regras de Validação

**Caminho:** Painel Admin → Regras

Regras controlam restrições de data nos registros.

| Tipo de Regra | Efeito |
|---|---|
| `notWeekend` | Data do evento **não pode** ser sábado ou domingo |
| `weekendOnly` | Data do evento **deve ser** sábado ou domingo |
| `min3DaysAhead` | Data deve ser **no mínimo 3 dias** após o lançamento |
| `maxDaysAhead` | Data tem um **limite máximo de dias** a partir do lançamento |

Cada regra possui uma **mensagem de erro** customizável exibida ao gestor quando a regra é violada.

---

## 14. Lógica de Classificação QM

O sistema calcula automaticamente a classificação e o valor QM com base em três fatores:

1. **Tipo QM** (A ou B) — informado no registro
2. **Dia da semana** do evento
3. **Horário** do evento

### Tabela de classificação

| Tipo QM | Condição | Classificação | Valor |
|---|---|---|---|
| A | Final de semana (sáb/dom) **ou** horário ≥ 21:00 | **A** | R$ 400 |
| B | Final de semana (sáb/dom) **ou** horário ≥ 21:00 | **B** | R$ 200 |
| A | Dia útil (seg–sex) **e** horário < 21:00 | **C** | R$ 200 |
| B | Dia útil (seg–sex) **e** horário < 21:00 | **D** | R$ 100 |

> **Exemplo:** Evento na sexta-feira às 19:00 com Tipo QM = A → **Classificação C, R$ 200**
> **Exemplo:** Evento no sábado às 16:00 com Tipo QM = B → **Classificação B, R$ 200**
> **Exemplo:** Evento na quarta-feira às 21:00 com Tipo QM = A → **Classificação A, R$ 400** (21:00 inclusive conta como noturno)

---

## 15. Dúvidas Frequentes

**O sistema não deixa eu fazer login. O que faço?**
Verifique se o e-mail e a senha estão corretos. Use "Esqueceu a senha?" para redefinir. Se o problema persistir, contate o administrador.

**Importei a planilha e alguns registros não foram aceitos. Por quê?**
O sistema exibe a linha e o motivo de cada erro. As causas mais comuns são: data no formato errado, Tipo QM diferente de A ou B, nome de funcionário não encontrado no cadastro, ou Categoria ausente para eventos do tipo "Jogo".

**Por que o Tipo QM do meu registro ficou C ou D se eu coloquei A ou B?**
A classificação final (A/B/C/D) é calculada pelo sistema com base no tipo informado + dia da semana + horário. Leia a [seção 14](#14-lógica-de-classificação-qm) para entender.

**Adicionei um funcionário mas ele não aparece na planilha modelo.**
Baixe o modelo novamente após cadastrar o funcionário — a aba "Listas" é gerada com os dados atuais do sistema no momento do download.

**Posso usar o Google Planilhas para preencher o modelo?**
Sim. Preencha a aba "Registros" e exporte como `.xlsx` antes de importar no portal.

**Não consigo excluir um setor. Por quê?**
Setores que possuem funcionários ou registros vinculados podem estar protegidos. Remova as associações antes de excluir.

---

*Em caso de problemas técnicos, contate o administrador do sistema.*
