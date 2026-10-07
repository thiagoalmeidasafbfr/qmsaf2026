-- ============================================================
-- Portal QM SAF Botafogo — Supabase Schema
-- Execute este script no SQL Editor do Supabase
-- ============================================================

-- 1. Funções auxiliares (criadas antes das tabelas e policies)
--    SECURITY DEFINER: executam como owner, bypassando RLS

CREATE OR REPLACE FUNCTION public.check_admin_exists()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.users_profile WHERE is_admin = true);
END;
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users_profile
    WHERE id = auth.uid() AND is_admin = true
  );
END;
$$;

-- Permite que usuários não autenticados (anon) verifiquem se admin existe
-- Necessário para a tela de setup inicial
GRANT EXECUTE ON FUNCTION public.check_admin_exists TO anon;
GRANT EXECUTE ON FUNCTION public.check_admin_exists TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin TO authenticated;

-- Exclui um usuário do auth.users (cascateia para users_profile).
-- Só admins podem chamar. SECURITY DEFINER permite acesso ao schema auth.
CREATE OR REPLACE FUNCTION public.delete_auth_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Acesso negado: apenas administradores podem excluir usuários';
  END IF;
  DELETE FROM auth.users WHERE id = user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_auth_user TO authenticated;

-- Retorna os setores do usuário autenticado (unindo campo legado 'sector' e novo array 'sectors').
-- Usado nas políticas RLS para permitir que gestores do mesmo setor vejam os mesmos dados.
CREATE OR REPLACE FUNCTION public.current_user_sectors()
RETURNS text[]
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT COALESCE(
           (SELECT
              CASE
                WHEN sectors IS NOT NULL AND array_length(sectors, 1) > 0 THEN sectors
                WHEN sector IS NOT NULL AND sector <> '' THEN ARRAY[sector]
                ELSE ARRAY[]::text[]
              END
            FROM public.users_profile WHERE id = auth.uid()),
           ARRAY[]::text[]
         );
$$;

GRANT EXECUTE ON FUNCTION public.current_user_sectors TO authenticated;

-- ============================================================
-- 2. Tabelas
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sectors (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  created_at  timestamptz DEFAULT now(),
  created_by  uuid        REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.categories (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  description text,
  created_at  timestamptz DEFAULT now(),
  created_by  uuid        REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.employees (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text        NOT NULL,
  registration     text,
  sector           text        DEFAULT '',     -- campo legado (single sector)
  sectors          text[]      DEFAULT '{}',   -- múltiplos departamentos
  can_use_grade_a  boolean     DEFAULT false,  -- habilita seleção de Grau A; senão só Grau B
  created_at       timestamptz DEFAULT now(),
  created_by       uuid        REFERENCES auth.users(id)
);

-- Migração idempotente para bancos já existentes
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS can_use_grade_a boolean DEFAULT false;

CREATE TABLE IF NOT EXISTS public.rules (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text        NOT NULL,
  description  text,
  sector       text,
  field        text,
  type         text,
  limit_days   text,
  working_days text,
  message      text,
  created_at   timestamptz DEFAULT now(),
  created_by   uuid        REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.records (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name        text        NOT NULL,
  event_date        text        NOT NULL,  -- armazenado como YYYY-MM-DD string
  game_time         text        NOT NULL,
  event_type        text        NOT NULL DEFAULT 'jogo',
  game_category     text,
  qm_classification text,
  qm_value          integer,
  employee_id       text,                  -- uuid ou 'OUTROS'
  employee_name     text,
  notes             text,
  sector            text,
  manager_id        uuid        REFERENCES auth.users(id),
  manager_name      text,
  created_at        timestamptz DEFAULT now(),
  -- Log do lançamento: original do gestor × resultado das regras
  qm_type_input            text,     -- Tipo QM informado pelo gestor (A/B; NULL = em branco na planilha)
  qm_type_applied          text,     -- Grau usado no cálculo, após checar a habilitação do funcionário
  qm_rule                  text,     -- 'Fim de semana' | 'Após 21h' | 'Dia útil antes das 21h'
  employee_grade_a_enabled boolean,  -- funcionário habilitado para Grau A no momento do lançamento
  input_source             text      -- 'manual' | 'importacao'
);

-- Migração idempotente para bancos já existentes
ALTER TABLE public.records
  ADD COLUMN IF NOT EXISTS qm_type_input            text,
  ADD COLUMN IF NOT EXISTS qm_type_applied          text,
  ADD COLUMN IF NOT EXISTS qm_rule                  text,
  ADD COLUMN IF NOT EXISTS employee_grade_a_enabled boolean,
  ADD COLUMN IF NOT EXISTS input_source             text;

CREATE TABLE IF NOT EXISTS public.users_profile (
  id          uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  email       text        NOT NULL,
  sector      text        DEFAULT '',     -- campo legado
  sectors     text[]      DEFAULT '{}',   -- múltiplos setores
  is_manager  boolean     DEFAULT false,
  is_admin    boolean     DEFAULT false,
  uid         text,                       -- compatibilidade (igual ao id)
  created_at  timestamptz DEFAULT now()
);

-- ============================================================
-- 3. Índices
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_records_manager_id  ON public.records(manager_id);
CREATE INDEX IF NOT EXISTS idx_records_event_date  ON public.records(event_date);
CREATE INDEX IF NOT EXISTS idx_records_created_at  ON public.records(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_employees_name      ON public.employees(name);
CREATE INDEX IF NOT EXISTS idx_users_is_admin      ON public.users_profile(is_admin);

-- ============================================================
-- 4. Row Level Security (RLS)
-- ============================================================

ALTER TABLE public.sectors       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.records       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;

-- ---- sectors ----
DROP POLICY IF EXISTS "Autenticados leem setores" ON public.sectors;
CREATE POLICY "Autenticados leem setores"
  ON public.sectors FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins escrevem setores" ON public.sectors;
CREATE POLICY "Admins escrevem setores"
  ON public.sectors FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());

-- ---- categories ----
DROP POLICY IF EXISTS "Autenticados leem categorias" ON public.categories;
CREATE POLICY "Autenticados leem categorias"
  ON public.categories FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins escrevem categorias" ON public.categories;
CREATE POLICY "Admins escrevem categorias"
  ON public.categories FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());

-- ---- employees ----
DROP POLICY IF EXISTS "Autenticados leem funcionários" ON public.employees;
CREATE POLICY "Autenticados leem funcionários"
  ON public.employees FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins escrevem funcionários" ON public.employees;
CREATE POLICY "Admins escrevem funcionários"
  ON public.employees FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());

-- ---- rules ----
DROP POLICY IF EXISTS "Autenticados leem regras" ON public.rules;
CREATE POLICY "Autenticados leem regras"
  ON public.rules FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins escrevem regras" ON public.rules;
CREATE POLICY "Admins escrevem regras"
  ON public.rules FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());

-- ---- records ----
DROP POLICY IF EXISTS "Admins leem todos os registros" ON public.records;
CREATE POLICY "Admins leem todos os registros"
  ON public.records FOR SELECT TO authenticated
  USING (is_admin());

DROP POLICY IF EXISTS "Gestores leem seus registros" ON public.records;
-- Gestores enxergam TODOS os registros dos setores em que estão vinculados
-- (permite que 2+ gestores do mesmo setor compartilhem a visualização).
CREATE POLICY "Gestores leem registros do setor"
  ON public.records FOR SELECT TO authenticated
  USING (
    manager_id = auth.uid()
    OR (sector IS NOT NULL AND sector = ANY(public.current_user_sectors()))
  );

DROP POLICY IF EXISTS "Gestores e admins inserem registros" ON public.records;
CREATE POLICY "Gestores e admins inserem registros"
  ON public.records FOR INSERT TO authenticated
  WITH CHECK (manager_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Admins excluem qualquer registro" ON public.records;
CREATE POLICY "Admins excluem qualquer registro"
  ON public.records FOR DELETE TO authenticated
  USING (is_admin());

DROP POLICY IF EXISTS "Gestores excluem seus registros" ON public.records;
CREATE POLICY "Gestores excluem seus registros"
  ON public.records FOR DELETE TO authenticated
  USING (manager_id = auth.uid());

-- ---- users_profile ----
DROP POLICY IF EXISTS "Admins leem todos os perfis" ON public.users_profile;
CREATE POLICY "Admins leem todos os perfis"
  ON public.users_profile FOR SELECT TO authenticated
  USING (is_admin());

DROP POLICY IF EXISTS "Usuário lê seu próprio perfil" ON public.users_profile;
CREATE POLICY "Usuário lê seu próprio perfil"
  ON public.users_profile FOR SELECT TO authenticated
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Admins escrevem todos os perfis" ON public.users_profile;
CREATE POLICY "Admins escrevem todos os perfis"
  ON public.users_profile FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());

-- Permite criar o primeiro perfil admin quando nenhum admin existe ainda
DROP POLICY IF EXISTS "Setup inicial: inserir próprio perfil sem admin" ON public.users_profile;
CREATE POLICY "Setup inicial: inserir próprio perfil sem admin"
  ON public.users_profile FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() AND NOT check_admin_exists());

-- ============================================================
-- 5. Habilitar real-time para todas as tabelas
-- ============================================================

DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['sectors','categories','employees','rules','records','users_profile']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = tbl
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
    END IF;
  END LOOP;
END;
$$;

-- ============================================================
-- 6. Tabela de registros arquivados (somente admin)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.archived_records (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  original_id       uuid,                    -- ID original em public.records
  archive_batch_id  uuid        NOT NULL,    -- agrupa registros do mesmo "Guardar Dados"
  archived_at       timestamptz NOT NULL DEFAULT now(),
  archived_by       uuid        REFERENCES auth.users(id),
  -- campos espelhados de records:
  event_name        text        NOT NULL,
  event_date        text        NOT NULL,
  game_time         text        NOT NULL,
  event_type        text        NOT NULL DEFAULT 'jogo',
  game_category     text,
  qm_classification text,
  qm_value          integer,
  employee_id       text,
  employee_name     text,
  notes             text,
  sector            text,
  manager_id        uuid        REFERENCES auth.users(id),
  manager_name      text,
  created_at        timestamptz DEFAULT now(),
  -- Log do lançamento (mesmas colunas de records)
  qm_type_input            text,
  qm_type_applied          text,
  qm_rule                  text,
  employee_grade_a_enabled boolean,
  input_source             text
);

ALTER TABLE public.archived_records
  ADD COLUMN IF NOT EXISTS qm_type_input            text,
  ADD COLUMN IF NOT EXISTS qm_type_applied          text,
  ADD COLUMN IF NOT EXISTS qm_rule                  text,
  ADD COLUMN IF NOT EXISTS employee_grade_a_enabled boolean,
  ADD COLUMN IF NOT EXISTS input_source             text;

CREATE INDEX IF NOT EXISTS idx_archived_records_batch       ON public.archived_records(archive_batch_id);
CREATE INDEX IF NOT EXISTS idx_archived_records_archived_at ON public.archived_records(archived_at DESC);

ALTER TABLE public.archived_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Somente admins leem registros arquivados" ON public.archived_records;
CREATE POLICY "Admins leem registros arquivados"
  ON public.archived_records FOR SELECT TO authenticated
  USING (is_admin());

-- Gestores enxergam os registros arquivados dos seus setores (mesma lógica de records).
-- Continuam sem permissão de inserir/excluir.
DROP POLICY IF EXISTS "Gestores leem seus registros arquivados" ON public.archived_records;
CREATE POLICY "Gestores leem registros arquivados do setor"
  ON public.archived_records FOR SELECT TO authenticated
  USING (
    manager_id = auth.uid()
    OR (sector IS NOT NULL AND sector = ANY(public.current_user_sectors()))
  );

DROP POLICY IF EXISTS "Somente admins inserem registros arquivados" ON public.archived_records;
CREATE POLICY "Somente admins inserem registros arquivados"
  ON public.archived_records FOR INSERT TO authenticated
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Somente admins excluem registros arquivados" ON public.archived_records;
CREATE POLICY "Somente admins excluem registros arquivados"
  ON public.archived_records FOR DELETE TO authenticated
  USING (is_admin());

-- ============================================================
-- 7. Log de Auditoria (mesmo conteúdo de migrations/2026-10-07_audit_log.sql)
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
