ALTER TABLE public.prontuario_patrimonial
    DROP CONSTRAINT prontuario_patrimonial_user_id_fkey;

ALTER TABLE public.prontuario_patrimonial
    ADD CONSTRAINT prontuario_patrimonial_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id)
    ON DELETE RESTRICT;

ALTER TABLE public.diagnosticos
    DROP CONSTRAINT diagnosticos_user_id_fkey;

ALTER TABLE public.diagnosticos
    ADD CONSTRAINT diagnosticos_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id)
    ON DELETE RESTRICT;

ALTER TABLE public.diagnosticos_vida
    DROP CONSTRAINT diagnosticos_vida_user_id_fkey;

ALTER TABLE public.diagnosticos_vida
    ADD CONSTRAINT diagnosticos_vida_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id)
    ON DELETE RESTRICT;