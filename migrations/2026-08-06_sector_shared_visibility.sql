-- ============================================================
-- Migração — Visibilidade compartilhada por setor (gestores)
-- Data: 2026-08-06
--
-- Faça login no Supabase → SQL Editor → cole este arquivo → Run.
-- É 100% idempotente (pode rodar quantas vezes quiser).
-- ============================================================

-- 1) Função auxiliar: setores do usuário autenticado
--    (une o campo legado 'sector' e o novo array 'sectors')
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

-- 2) records — política de leitura compartilhada por setor
DROP POLICY IF EXISTS "Gestores leem seus registros"        ON public.records;
DROP POLICY IF EXISTS "Gestores leem registros do setor"    ON public.records;

CREATE POLICY "Gestores leem registros do setor"
  ON public.records FOR SELECT TO authenticated
  USING (
    manager_id = auth.uid()
    OR (sector IS NOT NULL AND sector = ANY(public.current_user_sectors()))
  );

-- 3) archived_records — MESMA lógica para o arquivamento.
--    Sem isto, gestores só veem lançamentos que ELES arquivaram; ficariam
--    invisíveis os registros arquivados por outros (ex.: pelo Admin).
DROP POLICY IF EXISTS "Somente admins leem registros arquivados"      ON public.archived_records;
DROP POLICY IF EXISTS "Admins leem registros arquivados"              ON public.archived_records;
DROP POLICY IF EXISTS "Gestores leem seus registros arquivados"       ON public.archived_records;
DROP POLICY IF EXISTS "Gestores leem registros arquivados do setor"   ON public.archived_records;

-- Admin continua vendo tudo
CREATE POLICY "Admins leem registros arquivados"
  ON public.archived_records FOR SELECT TO authenticated
  USING (public.is_admin());

-- Gestor: vê arquivados dos seus setores + os que ele mesmo lançou
CREATE POLICY "Gestores leem registros arquivados do setor"
  ON public.archived_records FOR SELECT TO authenticated
  USING (
    manager_id = auth.uid()
    OR (sector IS NOT NULL AND sector = ANY(public.current_user_sectors()))
  );
