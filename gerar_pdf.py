"""
Gera MANUAL_GESTOR.pdf usando ReportLab.
"""
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable
)
from reportlab.lib.colors import HexColor

OUTPUT = "MANUAL_GESTOR.pdf"
PAGE_W, PAGE_H = A4

# ── Colors ────────────────────────────────────────────────────────────────────
C_NAVY   = HexColor("#00224E")
C_AMBER  = HexColor("#F59E0B")
C_WHITE  = colors.white
C_LIGHT  = HexColor("#EFF6FF")
C_ALT    = HexColor("#F8FAFC")
C_BORDER = HexColor("#CBD5E1")
C_NOTE   = HexColor("#DBEAFE")
C_TEXT   = HexColor("#1E293B")

# ── Styles ────────────────────────────────────────────────────────────────────
BASE_FONT = "Helvetica"
BASE_BOLD = "Helvetica-Bold"

def make_styles():
    s = {}

    s["cover_title"] = ParagraphStyle("cover_title",
        fontName=BASE_BOLD, fontSize=28, leading=34,
        textColor=C_WHITE, alignment=TA_CENTER, spaceAfter=6)

    s["cover_sub"] = ParagraphStyle("cover_sub",
        fontName=BASE_FONT, fontSize=14, leading=20,
        textColor=HexColor("#CBD5E1"), alignment=TA_CENTER)

    s["h1"] = ParagraphStyle("h1",
        fontName=BASE_BOLD, fontSize=16, leading=22,
        textColor=C_NAVY, spaceBefore=18, spaceAfter=8,
        borderPad=0)

    s["h2"] = ParagraphStyle("h2",
        fontName=BASE_BOLD, fontSize=12, leading=16,
        textColor=C_NAVY, spaceBefore=12, spaceAfter=4)

    s["body"] = ParagraphStyle("body",
        fontName=BASE_FONT, fontSize=10, leading=15,
        textColor=C_TEXT, spaceAfter=6, alignment=TA_JUSTIFY)

    s["bullet"] = ParagraphStyle("bullet",
        fontName=BASE_FONT, fontSize=10, leading=14,
        textColor=C_TEXT, spaceAfter=3,
        leftIndent=14, firstLineIndent=-10)

    s["numbered"] = ParagraphStyle("numbered",
        fontName=BASE_FONT, fontSize=10, leading=14,
        textColor=C_TEXT, spaceAfter=3,
        leftIndent=18, firstLineIndent=-14)

    s["note"] = ParagraphStyle("note",
        fontName=BASE_FONT, fontSize=9.5, leading=14,
        textColor=HexColor("#1E40AF"), spaceAfter=6,
        leftIndent=10)

    s["code"] = ParagraphStyle("code",
        fontName="Courier", fontSize=9, leading=13,
        textColor=HexColor("#BE185D"), spaceAfter=2)

    s["toc_title"] = ParagraphStyle("toc_title",
        fontName=BASE_BOLD, fontSize=14, leading=20,
        textColor=C_NAVY, alignment=TA_CENTER, spaceAfter=14)

    s["toc_item"] = ParagraphStyle("toc_item",
        fontName=BASE_FONT, fontSize=10, leading=16,
        textColor=C_TEXT, leftIndent=10)

    return s


def cover_page(styles):
    elems = []
    # Navy block via a 1-row table spanning full width
    cover_data = [[Paragraph(
        '<font name="Helvetica-Bold" size="28" color="#FFFFFF">Guia do Gestor</font><br/>'
        '<font name="Helvetica" size="13" color="#CBD5E1">Portal QM SAF Botafogo</font>',
        ParagraphStyle("c", alignment=TA_CENTER, leading=36))]]
    t = Table(cover_data, colWidths=[PAGE_W - 4*cm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), C_NAVY),
        ("TOPPADDING", (0,0), (-1,-1), 40),
        ("BOTTOMPADDING", (0,0), (-1,-1), 40),
        ("LEFTPADDING", (0,0), (-1,-1), 20),
        ("RIGHTPADDING", (0,0), (-1,-1), 20),
        ("ROUNDEDCORNERS", [8,8,8,8]),
    ]))
    elems.append(Spacer(1, 2*cm))
    elems.append(t)
    elems.append(Spacer(1, 1.2*cm))

    amber_bar = Table([[""]], colWidths=[PAGE_W - 4*cm], rowHeights=[4])
    amber_bar.setStyle(TableStyle([("BACKGROUND", (0,0), (-1,-1), C_AMBER)]))
    elems.append(amber_bar)
    elems.append(Spacer(1, 0.8*cm))

    elems.append(Paragraph(
        '<font name="Helvetica" size="11" color="#475569">'
        'Para uso exclusivo dos Gestores de Setor · Acesso restrito'
        '</font>',
        ParagraphStyle("ctr", alignment=TA_CENTER, leading=16)))
    elems.append(Spacer(1, 0.4*cm))
    elems.append(Paragraph(
        '<font name="Helvetica" size="10" color="#94A3B8">Versão 2026</font>',
        ParagraphStyle("ctr2", alignment=TA_CENTER, leading=14)))
    elems.append(PageBreak())
    return elems


def toc_page(styles):
    items = [
        "1. Fazendo login",
        "2. Sua tela inicial",
        "3. Adicionar um registro manualmente",
        "4. Importar registros em lote (planilha)",
        "5. Ver e filtrar o histórico",
        "6. Exportar o histórico",
        "7. Excluir registros",
        "8. Redefinir sua senha",
        "9. Entendendo a classificação QM",
    ]
    elems = []
    elems.append(Paragraph("Sumário", styles["toc_title"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=10))
    for item in items:
        elems.append(Paragraph(item, styles["toc_item"]))
    elems.append(PageBreak())
    return elems


def note_box(text, styles):
    p = Paragraph(f'<b>Atenção:</b> {text}', styles["note"])
    t = Table([[p]], colWidths=[PAGE_W - 4*cm - 20])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), C_NOTE),
        ("LEFTPADDING", (0,0), (-1,-1), 10),
        ("RIGHTPADDING", (0,0), (-1,-1), 10),
        ("TOPPADDING", (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
        ("LINEBEFORE", (0,0), (0,-1), 3, HexColor("#2563EB")),
    ]))
    return t


def make_table(headers, rows, col_widths, styles):
    data = []
    header_row = [Paragraph(f'<b><font color="white">{h}</font></b>',
                             ParagraphStyle("th", fontName=BASE_BOLD, fontSize=9,
                                            textColor=C_WHITE, alignment=TA_CENTER, leading=13))
                  for h in headers]
    data.append(header_row)
    for i, row in enumerate(rows):
        bg = C_ALT if i % 2 == 1 else C_WHITE
        data.append([Paragraph(str(cell), ParagraphStyle("td", fontName=BASE_FONT,
                                fontSize=9, leading=13, textColor=C_TEXT))
                     for cell in row])

    style = TableStyle([
        ("BACKGROUND", (0,0), (-1,0), C_NAVY),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [C_WHITE, C_ALT]),
        ("GRID", (0,0), (-1,-1), 0.5, C_BORDER),
        ("TOPPADDING", (0,0), (-1,-1), 5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 5),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING", (0,0), (-1,-1), 6),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
    ])
    t = Table(data, colWidths=col_widths)
    t.setStyle(style)
    return t


def build_content(styles):
    S = styles
    W = PAGE_W - 4*cm  # usable width
    elems = []

    # ── Section 1 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("1. Fazendo login", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    for n, txt in enumerate([
        "Abra o portal no navegador.",
        "Digite seu <b>e-mail</b> e <b>senha</b>.",
        "Clique em <b>Entrar</b>.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 4))
    elems.append(note_box(
        'Caso o login não funcione, clique em <b>"Esqueceu a senha?"</b> e siga as instruções '
        'enviadas para o seu e-mail.', S))
    elems.append(Spacer(1, 10))

    # ── Section 2 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("2. Sua tela inicial", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    elems.append(Paragraph(
        "Após o login, você verá o <b>Painel do Gestor</b> com:", S["body"]))
    elems.append(make_table(
        ["Elemento", "O que mostra"],
        [
            ["Total de Registros", "Todos os registros que você já lançou"],
            ["Registros do Mês", "Apenas os registros do mês atual"],
            ["Novo Registro", "Abre o formulário para lançar um registro manualmente"],
            ["Importar Planilha", "Permite importar vários registros de uma vez via Excel"],
            ["Ver Histórico", "Abre a lista de todos os seus registros"],
        ],
        [5*cm, W - 5*cm], S))
    elems.append(Spacer(1, 10))

    # ── Section 3 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("3. Adicionar um registro manualmente", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    for n, txt in enumerate([
        "Clique no botão <b>Novo Registro</b>.",
        "Preencha o formulário (campos descritos abaixo).",
        "Clique em <b>Salvar Registro</b>.",
        "Uma mensagem de confirmação aparecerá e o registro será listado no histórico.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 6))
    elems.append(Paragraph("Campos do formulário", S["h2"]))

    fields = [
        ("Tipo de Evento", 'Escolha "Jogo" (para jogos das categorias do clube) ou "Outros" (para outros tipos de evento).'),
        ("Nome do Evento", "Escreva o nome do evento. Exemplos: Botafogo x Flamengo, Treino Sub-20."),
        ("Data do Evento", "Selecione a data em que o evento acontece (não a data de hoje)."),
        ("Horário do Evento", "Escolha o horário de início. Os horários disponíveis estão em intervalos de 15 minutos (ex.: 19:00, 19:15, 19:30...)."),
        ("Categoria do Jogo", 'Somente para eventos do tipo "Jogo". Selecione uma das categorias disponíveis.'),
        ("Tipo QM", "Selecione A ou B. O sistema calcula automaticamente a classificação final (A, B, C ou D) e o valor em reais."),
        ("Funcionário", 'Selecione o nome do funcionário na lista. Caso não esteja na lista, selecione "Outros".'),
        ("Observações", 'Obrigatório quando o Tipo de Evento for "Outros" ou quando o Funcionário for "Outros". Nos demais casos, é opcional.'),
    ]
    elems.append(make_table(
        ["Campo", "Descrição"],
        fields,
        [4*cm, W - 4*cm], S))
    elems.append(Spacer(1, 6))
    elems.append(Paragraph("Categorias de Jogo disponíveis:", S["body"]))
    for cat in ["Futebol Masculino Profissional", "Sub-20 Masculino", "Sub-17 Masculino",
                "Sub-15 Masculino", "Demais Categorias Masculino",
                "Futebol Profissional Feminino", "Futebol de Base Feminino"]:
        elems.append(Paragraph(f"• {cat}", S["bullet"]))
    elems.append(Spacer(1, 10))

    # ── Section 4 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("4. Importar registros em lote (planilha)", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    elems.append(Paragraph(
        "Use essa opção quando precisar lançar vários registros de uma vez.", S["body"]))

    elems.append(Paragraph("Passo 1 — Baixar o modelo", S["h2"]))
    for n, txt in enumerate([
        "Clique em <b>Importar Planilha</b>.",
        "Clique em <b>Baixar Modelo</b> para salvar o arquivo <b>modelo_quadro_movel.xlsx</b>.",
        "Abra o arquivo no <b>Excel</b> ou <b>Google Planilhas</b>.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Paragraph("O arquivo tem três abas:", S["body"]))
    for tab, desc in [("Registros", "onde você preenche os dados"),
                      ("Listas", "listas de referência (funcionários, horários, categorias, etc.)"),
                      ("Tutorial", "explicação de cada coluna")]:
        elems.append(Paragraph(f"• <b>{tab}</b> — {desc}", S["bullet"]))
    elems.append(Spacer(1, 6))

    elems.append(Paragraph("Passo 2 — Preencher a planilha", S["h2"]))
    elems.append(Paragraph(
        "Preencha a aba <b>Registros</b> a partir da <b>linha 2</b>. "
        "Não altere ou apague a linha 1 (cabeçalhos).", S["body"]))
    elems.append(make_table(
        ["Coluna", "Obrigatório?", "O que preencher"],
        [
            ["Tipo de Evento", "Sim", 'Jogo ou Outros'],
            ["Nome do Evento", "Sim", "Texto livre"],
            ["Data do Evento", "Sim", "DD/MM/AAAA — ex.: 16/04/2026"],
            ["Horário do Evento", "Sim", "HH:MM — ex.: 19:00 (múltiplos de 15 min)"],
            ["Categoria do Jogo", "Só para Jogo", "Deve ser uma das categorias da aba Listas"],
            ["Tipo QM", "Sim", "Apenas A ou B"],
            ["Funcionário", "Sim", 'Nome exato do funcionário ou "Outros"'],
            ["Observações", "Condicional", 'Obrigatório se Tipo = "Outros" ou Funcionário = "Outros"'],
        ],
        [3.5*cm, 2.5*cm, W - 6*cm], S))
    elems.append(Spacer(1, 4))
    elems.append(note_box(
        'Para eventos do tipo "Outros", a coluna <b>Categoria do Jogo deve ficar em branco</b>. '
        'Os nomes dos funcionários devem ser <b>exatamente iguais</b> ao cadastro '
        '(use a aba Listas para consultar).', S))
    elems.append(Spacer(1, 6))

    elems.append(Paragraph("Passo 3 — Importar", S["h2"]))
    for n, txt in enumerate([
        "Salve o arquivo como <b>.xlsx</b>.",
        "No portal, clique em <b>Importar Planilha</b>.",
        "Arraste o arquivo para a área indicada ou clique para selecionar.",
        "O sistema verificará cada linha. Se houver erros, eles serão exibidos com o número da linha e o motivo.",
        "Corrija os erros na planilha e importe novamente, se necessário.",
        "Se houver registros duplicados (mesma data + mesmo funcionário), o sistema avisará — você escolhe se quer importar mesmo assim ou ignorar.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 6))

    elems.append(Paragraph("Erros comuns", S["h2"]))
    elems.append(make_table(
        ["Mensagem de erro", "O que causou", "Como corrigir"],
        [
            ["Tipo QM inválido", "Coluna com valor diferente de A ou B", "Preencha apenas com A ou B"],
            ["Formato de data inválido", "Data fora do padrão", "Use DD/MM/AAAA (ex.: 16/04/2026)"],
            ["Categoria obrigatória", "Tipo = Jogo sem categoria", "Preencha a Categoria do Jogo"],
            ["Observações obrigatórias", "Tipo = Outros sem observação", "Preencha as Observações"],
            ["Funcionário não encontrado", "Nome digitado diferente do cadastro", "Consulte a aba Listas para o nome exato"],
            ["Cabeçalho ausente", "Coluna renomeada ou apagada", "Use o modelo original sem alterar a linha 1"],
        ],
        [3.5*cm, 4.5*cm, W - 8*cm], S))
    elems.append(Spacer(1, 10))

    # ── Section 5 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("5. Ver e filtrar o histórico", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    for n, txt in enumerate([
        "Clique em <b>Ver Histórico</b> no painel.",
        "Você verá todos os registros do(s) seu(s) setor(es).",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 4))
    elems.append(Paragraph("Filtros disponíveis:", S["h2"]))
    for f in ["Nome do evento", "Nome do funcionário", "Categoria do jogo",
              "Período (data inicial e data final)", "Observações"]:
        elems.append(Paragraph(f"• {f}", S["bullet"]))
    elems.append(Paragraph("Os filtros são aplicados automaticamente conforme você digita.", S["body"]))
    elems.append(Spacer(1, 4))
    elems.append(Paragraph("Informações exibidas na tabela:", S["h2"]))
    elems.append(make_table(
        ["Coluna", "Descrição"],
        [
            ["Data Criação", "Quando o registro foi lançado no sistema"],
            ["Evento", "Nome do evento"],
            ["Data Evento", "Data em que o evento ocorre"],
            ["Horário", "Horário do evento"],
            ["Categoria", "Categoria do jogo"],
            ["QM", "Classificação calculada (A, B, C ou D)"],
            ["Funcionário", "Nome do funcionário"],
            ["Setor", "Setor do funcionário"],
            ["Observações", "Observações inseridas"],
        ],
        [3.5*cm, W - 3.5*cm], S))
    elems.append(Spacer(1, 10))

    # ── Section 6 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("6. Exportar o histórico", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    for n, txt in enumerate([
        "Acesse <b>Ver Histórico</b>.",
        "Aplique filtros se quiser exportar apenas um período ou funcionário específico.",
        "Clique em <b>Exportar CSV</b> ou <b>Exportar XLSX</b>.",
        "O arquivo <b>historico_registros.xlsx</b> (ou .csv) será baixado automaticamente.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 4))
    elems.append(note_box(
        "A exportação considera <b>apenas os registros visíveis</b> após os filtros aplicados. "
        "Para exportar tudo, limpe os filtros antes de exportar.", S))
    elems.append(Spacer(1, 10))

    # ── Section 7 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("7. Excluir registros", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    elems.append(Paragraph("<b>Excluir um registro:</b>", S["body"]))
    elems.append(Paragraph("Clique no ícone de lixeira ao lado do registro e confirme.", S["bullet"]))
    elems.append(Spacer(1, 4))
    elems.append(Paragraph("<b>Excluir vários registros de uma vez:</b>", S["body"]))
    for n, txt in enumerate([
        "Marque as caixas de seleção dos registros que deseja excluir.",
        "Clique em <b>Excluir Selecionados</b>.",
        "Uma janela de confirmação mostrará os registros que serão removidos.",
        "Clique em <b>Confirmar</b> para concluir.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 4))
    elems.append(note_box("A exclusão é <b>permanente</b> e não pode ser desfeita.", S))
    elems.append(Spacer(1, 10))

    # ── Section 8 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("8. Redefinir sua senha", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    for n, txt in enumerate([
        'Na tela de login, clique em <b>"Esqueceu a senha?"</b>.',
        "Informe seu e-mail cadastrado.",
        "Clique em <b>Enviar link de redefinição</b>.",
        "Acesse o e-mail recebido e clique no link.",
        "Cadastre sua nova senha.",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 10))

    # ── Section 9 ──────────────────────────────────────────────────────────────
    elems.append(Paragraph("9. Entendendo a classificação QM", S["h1"]))
    elems.append(HRFlowable(width="100%", thickness=1, color=C_AMBER, spaceAfter=8))
    elems.append(Paragraph(
        "Ao salvar um registro, o sistema calcula automaticamente a <b>classificação QM</b> "
        "(A, B, C ou D) e o <b>valor</b> correspondente, com base em três fatores:", S["body"]))
    for n, txt in enumerate([
        "O <b>Tipo QM</b> que você informou (A ou B)",
        "O <b>dia da semana</b> do evento",
        "O <b>horário</b> do evento",
    ], 1):
        elems.append(Paragraph(f"{n}. {txt}", S["numbered"]))
    elems.append(Spacer(1, 6))
    elems.append(Paragraph("Tabela de classificação", S["h2"]))
    elems.append(make_table(
        ["Tipo QM", "Condição", "Resultado", "Valor"],
        [
            ["A", "Fim de semana (sáb/dom) OU horário ≥ 21:00", "A", "R$ 400"],
            ["B", "Fim de semana (sáb/dom) OU horário ≥ 21:00", "B", "R$ 200"],
            ["A", "Dia útil (seg–sex) E horário < 21:00", "C", "R$ 200"],
            ["B", "Dia útil (seg–sex) E horário < 21:00", "D", "R$ 100"],
        ],
        [2*cm, 9*cm, 2*cm, 2.5*cm], S))
    elems.append(Spacer(1, 6))
    elems.append(Paragraph("Exemplos práticos", S["h2"]))
    elems.append(make_table(
        ["Situação", "Tipo QM", "Resultado"],
        [
            ["Sexta-feira, 19:00", "A", "C — R$ 200"],
            ["Sexta-feira, 21:00", "A", "A — R$ 400"],
            ["Sábado, 16:00", "B", "B — R$ 200"],
            ["Quarta-feira, 20:59", "B", "D — R$ 100"],
            ["Domingo, qualquer horário", "A", "A — R$ 400"],
        ],
        [6*cm, 2.5*cm, W - 8.5*cm], S))
    elems.append(Spacer(1, 6))
    elems.append(note_box(
        "O horário <b>21:00 em ponto</b> já conta como noturno "
        "(≥ 21:00 = classificação mais alta).", S))
    elems.append(Spacer(1, 14))
    elems.append(HRFlowable(width="100%", thickness=0.5, color=C_BORDER, spaceAfter=6))
    elems.append(Paragraph(
        '<font color="#64748B" size="9">Em caso de dúvidas ou problemas de acesso, '
        'contate o administrador do sistema.</font>',
        ParagraphStyle("footer", alignment=TA_CENTER, leading=14)))

    return elems


def main():
    styles = make_styles()
    doc = SimpleDocTemplate(
        OUTPUT,
        pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm,
        topMargin=2*cm, bottomMargin=2*cm,
        title="Guia do Gestor — Portal QM SAF Botafogo",
        author="SAF Botafogo",
    )
    story = []
    story += cover_page(styles)
    story += toc_page(styles)
    story += build_content(styles)
    doc.build(story)
    print(f"✓ {OUTPUT} gerado com sucesso.")


if __name__ == "__main__":
    main()
