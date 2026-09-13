
REVOKE UPDATE ON TABLE public.users_profile FROM authenticated;
GRANT UPDATE (
  nome_completo, telefone_whatsapp, data_nascimento, profissao,
  estado_civil, numero_dependentes, possui_empresa, possui_imoveis,
  faixa_patrimonio, origin_lead, lgpd_aceito, termos_aceito,
  onboarding_concluido, updated_at
) ON TABLE public.users_profile TO authenticated;

CREATE OR REPLACE FUNCTION public.sync_user_profile_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  UPDATE public.users_profile
     SET email = NEW.email,
         updated_at = now()
   WHERE id = NEW.id
     AND email IS DISTINCT FROM NEW.email;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.sync_user_profile_email() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_user_profile_email() FROM anon;
REVOKE ALL ON FUNCTION public.sync_user_profile_email() FROM authenticated;

DROP TRIGGER IF EXISTS sync_user_profile_email_after_auth_update ON auth.users;
CREATE TRIGGER sync_user_profile_email_after_auth_update
AFTER UPDATE OF email ON auth.users
FOR EACH ROW
WHEN (OLD.email IS DISTINCT FROM NEW.email)
EXECUTE FUNCTION public.sync_user_profile_email();

REVOKE ALL PRIVILEGES ON TABLE public.diagnosticos_vida FROM anon;
REVOKE ALL PRIVILEGES ON TABLE public.diagnosticos_vida FROM authenticated;
GRANT SELECT ON TABLE public.diagnosticos_vida TO authenticated;

DROP POLICY IF EXISTS "usuario ve seus proprios diagnosticos" ON public.diagnosticos_vida;
CREATE POLICY "usuario ve seus proprios diagnosticos"
ON public.diagnosticos_vida
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE INDEX IF NOT EXISTS diagnosticos_vida_user_id_idx
ON public.diagnosticos_vida (user_id);
