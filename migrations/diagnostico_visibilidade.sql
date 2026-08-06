-- ============================================================
-- Diagnóstico — Por que o gestor de teste não vê os arquivados?
-- Rode cada bloco separado no SQL Editor do Supabase.
-- ============================================================

-- 1) A função current_user_sectors existe?
--    Deve retornar 1 linha.
SELECT proname, prosecdef
FROM pg_proc
WHERE proname = 'current_user_sectors';

-- 2) Quais políticas estão ativas em archived_records?
--    Confira se aparece "Gestores leem registros arquivados do setor".
SELECT policyname, cmd, roles, qual
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'archived_records';

-- 3) Perfil do usuário de teste (substitua o email)
SELECT id, name, email, sector, sectors, is_manager, is_admin
FROM public.users_profile
WHERE email = 'EMAIL_DO_GESTOR_DE_TESTE@safbfr.com.br';

-- 4) Registros arquivados do setor esperado
--    (troque 'Futebol Feminino' pelo NOME EXATO — case-sensitive, com/sem acento)
SELECT sector, count(*)
FROM public.archived_records
GROUP BY sector
ORDER BY 2 DESC;

-- 5) Simulação: o que a política enxerga PARA o usuário de teste?
--    Substitua o UUID pelo id da linha do passo 3.
--    Se retornar 0, o problema é o NOME do setor não bater.
WITH s AS (
  SELECT
    CASE
      WHEN sectors IS NOT NULL AND array_length(sectors,1) > 0 THEN sectors
      WHEN sector IS NOT NULL AND sector <> '' THEN ARRAY[sector]
      ELSE ARRAY[]::text[]
    END AS setores
  FROM public.users_profile
  WHERE id = 'UUID_DO_GESTOR_DE_TESTE'
)
SELECT ar.sector, count(*)
FROM public.archived_records ar, s
WHERE ar.sector = ANY(s.setores)
   OR ar.manager_id = 'UUID_DO_GESTOR_DE_TESTE'
GROUP BY ar.sector;
