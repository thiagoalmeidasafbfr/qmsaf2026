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
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text        NOT NULL,
  registration text,
  sector       text        DEFAULT '',     -- campo legado (single sector)
  sectors      text[]      DEFAULT '{}',   -- múltiplos departamentos
  created_at   timestamptz DEFAULT now(),
  created_by   uuid        REFERENCES auth.users(id)
);

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
  created_at        timestamptz DEFAULT now()
);

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
CREATE POLICY "Gestores leem seus registros"
  ON public.records FOR SELECT TO authenticated
  USING (manager_id = auth.uid());

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

ALTER PUBLICATION supabase_realtime ADD TABLE public.sectors;
ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.employees;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rules;
ALTER PUBLICATION supabase_realtime ADD TABLE public.records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users_profile;

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
  created_at        timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_archived_records_batch       ON public.archived_records(archive_batch_id);
CREATE INDEX IF NOT EXISTS idx_archived_records_archived_at ON public.archived_records(archived_at DESC);

ALTER TABLE public.archived_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Somente admins leem registros arquivados" ON public.archived_records;
CREATE POLICY "Somente admins leem registros arquivados"
  ON public.archived_records FOR SELECT TO authenticated
  USING (is_admin());

DROP POLICY IF EXISTS "Somente admins inserem registros arquivados" ON public.archived_records;
CREATE POLICY "Somente admins inserem registros arquivados"
  ON public.archived_records FOR INSERT TO authenticated
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Somente admins excluem registros arquivados" ON public.archived_records;
CREATE POLICY "Somente admins excluem registros arquivados"
  ON public.archived_records FOR DELETE TO authenticated
  USING (is_admin());
