-- ============================================================
-- Migração — Log de Auditoria (quem fez o quê e quando)
-- Data: 2026-10-07
--
-- Faça login no Supabase → SQL Editor → cole este arquivo → Run.
-- É 100% idempotente (pode rodar quantas vezes quiser).
-- Rode também migrations/2026-10-07_qm_input_log.sql (log do Tipo QM).
--
-- O que faz:
--   1) Cria public.audit_log: trilha imutável de alterações (só admin lê;
--      ninguém edita nem apaga pela aplicação).
--   2) Gatilhos no banco gravam TODA inclusão/alteração/exclusão em
--      funcionários, lançamentos, arquivamento, usuários, setores,
--      categorias e regras — com o usuário logado que fez a ação e os
--      valores antes/depois. Por ser no banco, vale para qualquer tela
--      ou importação e não depende do navegador.
--   3) Reconstrói o histórico que já existe (source = 'reconstruido'):
--      quem criou cada funcionário/setor/categoria/regra, quem lançou cada
--      QM (inclusive arquivados) e quem arquivou. Alterações feitas ANTES
--      desta migração (ex.: quem marcou "Pode Grau A") não ficaram gravadas
--      em lugar nenhum do banco e não podem ser reconstruídas.
-- ============================================================

-- 1) Tabela -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_log (
  id              bigserial   PRIMARY KEY,
  occurred_at     timestamptz NOT NULL DEFAULT now(),
  actor_id        uuid,                 -- usuário logado (auth.uid()); sem FK p/ sobreviver à exclusão do usuário
  actor_name      text,
  actor_email     text,
  table_name      text        NOT NULL, -- records, archived_records, employees, users_profile, sectors, categories, rules
  action          text        NOT NULL, -- INSERT, UPDATE, DELETE, ARCHIVE, UNARCHIVE
  row_id          text,
  old_data        jsonb,                -- linha antes da alteração
  new_data        jsonb,                -- linha depois da alteração
  changed_fields  text[],               -- colunas alteradas (UPDATE)
  source          text        NOT NULL DEFAULT 'trigger'  -- 'trigger' | 'reconstruido'
);

CREATE INDEX IF NOT EXISTS idx_audit_log_occurred_at ON public.audit_log(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_row         ON public.audit_log(table_name, row_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor       ON public.audit_log(actor_id);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins leem log de auditoria" ON public.audit_log;
CREATE POLICY "Admins leem log de auditoria"
  ON public.audit_log FOR SELECT TO authenticated
  USING (public.is_admin());

-- Sem políticas de INSERT/UPDATE/DELETE: só os gatilhos (SECURITY DEFINER) gravam.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.audit_log FROM anon, authenticated;

-- 2) Gatilho ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.audit_log_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor   uuid := auth.uid();
  v_name    text;
  v_email   text;
  v_old     jsonb;
  v_new     jsonb;
  v_action  text := TG_OP;
  v_changed text[];
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN v_old := to_jsonb(OLD); END IF;
  IF TG_OP IN ('INSERT', 'UPDATE') THEN v_new := to_jsonb(NEW); END IF;

  IF TG_OP = 'UPDATE' THEN
    SELECT array_agg(k ORDER BY k) INTO v_changed
      FROM jsonb_object_keys(v_new) AS k
     WHERE v_new -> k IS DISTINCT FROM v_old -> k;
    IF v_changed IS NULL THEN RETURN NULL; END IF;  -- update sem mudança real
  END IF;

  -- Arquivar = INSERT em archived_records + DELETE em records (nessa ordem);
  -- Desarquivar = INSERT em records + DELETE em archived_records.
  -- Registra cada movimento uma única vez, como ARCHIVE / UNARCHIVE.
  IF TG_TABLE_NAME = 'archived_records' THEN
    IF TG_OP = 'INSERT' THEN RETURN NULL; END IF;
    IF TG_OP = 'DELETE' AND EXISTS (
      SELECT 1 FROM public.records WHERE id::text = v_old ->> 'original_id'
    ) THEN RETURN NULL; END IF;
  ELSIF TG_TABLE_NAME = 'records' THEN
    IF TG_OP = 'DELETE' AND EXISTS (
      SELECT 1 FROM public.archived_records WHERE original_id::text = v_old ->> 'id'
    ) THEN v_action := 'ARCHIVE'; END IF;
    IF TG_OP = 'INSERT' AND EXISTS (
      SELECT 1 FROM public.archived_records WHERE original_id::text = v_new ->> 'id'
    ) THEN v_action := 'UNARCHIVE'; END IF;
  END IF;

  IF v_actor IS NOT NULL THEN
    SELECT name, email INTO v_name, v_email FROM public.users_profile WHERE id = v_actor;
  END IF;

  INSERT INTO public.audit_log
    (actor_id, actor_name, actor_email, table_name, action, row_id, old_data, new_data, changed_fields, source)
  VALUES
    (v_actor, v_name, v_email, TG_TABLE_NAME, v_action,
     COALESCE(v_new ->> 'id', v_old ->> 'id'), v_old, v_new, v_changed, 'trigger');

  RETURN NULL;
END;
$$;

DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['records','archived_records','employees','users_profile','sectors','categories','rules']
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS audit_%1$s ON public.%1$I', tbl);
    EXECUTE format('CREATE TRIGGER audit_%1$s AFTER INSERT OR UPDATE OR DELETE ON public.%1$I
                    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger()', tbl);
  END LOOP;
END;
$$;

-- 3) Reconstrução do histórico existente --------------------------------
-- Cada bloco só insere o evento se ele ainda não estiver no log
-- (nem reconstruído antes, nem gravado pelo gatilho).

-- Funcionários: quem cadastrou e quando (dados = estado ATUAL do cadastro)
INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, new_data, source)
SELECT COALESCE(e.created_at, now()), e.created_by, up.name, up.email, 'employees', 'INSERT', e.id::text, to_jsonb(e), 'reconstruido'
  FROM public.employees e
  LEFT JOIN public.users_profile up ON up.id = e.created_by
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'employees' AND a.row_id = e.id::text AND a.action = 'INSERT');

-- Setores, categorias e regras
INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, new_data, source)
SELECT COALESCE(s.created_at, now()), s.created_by, up.name, up.email, 'sectors', 'INSERT', s.id::text, to_jsonb(s), 'reconstruido'
  FROM public.sectors s
  LEFT JOIN public.users_profile up ON up.id = s.created_by
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'sectors' AND a.row_id = s.id::text AND a.action = 'INSERT');

INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, new_data, source)
SELECT COALESCE(c.created_at, now()), c.created_by, up.name, up.email, 'categories', 'INSERT', c.id::text, to_jsonb(c), 'reconstruido'
  FROM public.categories c
  LEFT JOIN public.users_profile up ON up.id = c.created_by
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'categories' AND a.row_id = c.id::text AND a.action = 'INSERT');

INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, new_data, source)
SELECT COALESCE(r.created_at, now()), r.created_by, up.name, up.email, 'rules', 'INSERT', r.id::text, to_jsonb(r), 'reconstruido'
  FROM public.rules r
  LEFT JOIN public.users_profile up ON up.id = r.created_by
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'rules' AND a.row_id = r.id::text AND a.action = 'INSERT');

-- Usuários (quem criou o usuário não era gravado)
INSERT INTO public.audit_log (occurred_at, table_name, action, row_id, new_data, source)
SELECT COALESCE(u.created_at, now()), 'users_profile', 'INSERT', u.id::text, to_jsonb(u), 'reconstruido'
  FROM public.users_profile u
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'users_profile' AND a.row_id = u.id::text AND a.action = 'INSERT');

-- Lançamentos de QM ativos: gestor que lançou e quando
INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, new_data, source)
SELECT COALESCE(r.created_at, now()), r.manager_id, COALESCE(up.name, r.manager_name), up.email,
       'records', 'INSERT', r.id::text, to_jsonb(r), 'reconstruido'
  FROM public.records r
  LEFT JOIN public.users_profile up ON up.id = r.manager_id
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'records' AND a.row_id = r.id::text AND a.action = 'INSERT');

-- Lançamentos já arquivados: o lançamento original...
INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, new_data, source)
SELECT COALESCE(ar.created_at, now()), ar.manager_id, COALESCE(up.name, ar.manager_name), up.email,
       'records', 'INSERT', COALESCE(ar.original_id, ar.id)::text, to_jsonb(ar), 'reconstruido'
  FROM public.archived_records ar
  LEFT JOIN public.users_profile up ON up.id = ar.manager_id
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'records' AND a.row_id = COALESCE(ar.original_id, ar.id)::text AND a.action = 'INSERT');

-- ...e o arquivamento (quem arquivou e quando)
INSERT INTO public.audit_log (occurred_at, actor_id, actor_name, actor_email, table_name, action, row_id, old_data, source)
SELECT ar.archived_at, ar.archived_by, up.name, up.email,
       'records', 'ARCHIVE', COALESCE(ar.original_id, ar.id)::text, to_jsonb(ar), 'reconstruido'
  FROM public.archived_records ar
  LEFT JOIN public.users_profile up ON up.id = ar.archived_by
 WHERE NOT EXISTS (SELECT 1 FROM public.audit_log a
                    WHERE a.table_name = 'records' AND a.row_id = COALESCE(ar.original_id, ar.id)::text AND a.action = 'ARCHIVE');
