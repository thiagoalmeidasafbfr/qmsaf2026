-- ============================================================
-- Migração — Log do lançamento de QM (original do gestor × resultado das regras)
-- Data: 2026-10-07
--
-- Faça login no Supabase → SQL Editor → cole este arquivo → Run.
-- É 100% idempotente (pode rodar quantas vezes quiser).
--
-- Cada lançamento passa a guardar, além da classificação final (qm_classification):
--   qm_type_input            → Tipo QM informado pelo gestor (A/B; NULL = em branco na planilha)
--   qm_type_applied          → Grau usado no cálculo, após checar a habilitação do funcionário
--   qm_rule                  → regra que definiu a classificação ('Fim de semana', 'Após 21h',
--                              'Dia útil antes das 21h')
--   employee_grade_a_enabled → se o funcionário podia usar Grau A no momento do lançamento
--   input_source             → 'manual' ou 'importacao'
--
-- Registros anteriores a esta migração ficam com as colunas vazias ("Sem log").
-- ============================================================

ALTER TABLE public.records
  ADD COLUMN IF NOT EXISTS qm_type_input            text,
  ADD COLUMN IF NOT EXISTS qm_type_applied          text,
  ADD COLUMN IF NOT EXISTS qm_rule                  text,
  ADD COLUMN IF NOT EXISTS employee_grade_a_enabled boolean,
  ADD COLUMN IF NOT EXISTS input_source             text;

-- Mesmas colunas no arquivamento, para o log acompanhar o registro ao arquivar/desarquivar
ALTER TABLE public.archived_records
  ADD COLUMN IF NOT EXISTS qm_type_input            text,
  ADD COLUMN IF NOT EXISTS qm_type_applied          text,
  ADD COLUMN IF NOT EXISTS qm_rule                  text,
  ADD COLUMN IF NOT EXISTS employee_grade_a_enabled boolean,
  ADD COLUMN IF NOT EXISTS input_source             text;

-- Recarrega o cache de schema do PostgREST para as colunas novas ficarem visíveis na API
NOTIFY pgrst, 'reload schema';
