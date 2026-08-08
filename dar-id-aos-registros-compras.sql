-- =====================================================================
-- COMPRAS — dar um identificador (id) a cada registro que ainda não tem
-- =====================================================================
--
-- POR QUE ISTO É NECESSÁRIO
--   Os registros do Compras não têm identificador próprio. Sem ele, quando
--   duas pessoas gravam ao mesmo tempo, o sistema não consegue saber se um
--   registro alterado é "o mesmo de antes, editado" ou "um registro novo".
--   Resultado: ele não consegue juntar as duas alterações com segurança e
--   precisa perguntar, mesmo quando juntar seria óbvio.
--
--   Com o id, o Compras passa a se comportar como o Financeiro, que já tem
--   identificador em cada lançamento.
--
-- O QUE ESTE ARQUIVO FAZ
--   Percorre as listas de registros (urgente, importante, pago, manutencao,
--   historico) e acrescenta um campo "id" em cada registro que ainda não
--   tenha um. Quem já tem id é deixado como está.
--
-- O QUE ELE NÃO FAZ
--   Não apaga nada. Não altera nenhum outro campo. Não mexe em usuários.
--   Não mexe em produção — este arquivo trata apenas de 'compras_teste'.
--
-- IMPORTANTE: RODAR UMA VEZ SÓ
--   Rodar de novo é inofensivo (quem já tem id é ignorado), mas a migração
--   precisa ser feita AQUI, no banco, e não pelo navegador. Se dois
--   navegadores gerassem ids por conta própria, cada um inventaria um id
--   diferente para o mesmo registro — e aí a comparação passaria a mentir,
--   o que é pior do que não ter id nenhum.
--
-- COMO RODAR
--   1. Abra o SQL Editor do Supabase
--   2. Cole este arquivo inteiro
--   3. Clique em Run
--   4. Confira as duas consultas do fim: a de ANTES mostra quantos estavam
--      sem id; a de DEPOIS deve mostrar zero.
--
-- =====================================================================


-- PASSO 1 — Backup. Sempre.
SELECT fazer_backup('antes-de-dar-id-aos-registros');


-- PASSO 2 — Quantos registros estão sem id hoje? (guarde este número)
SELECT
  'ANTES' AS momento,
  lista,
  count(*) FILTER (WHERE reg->>'id' IS NULL) AS sem_id,
  count(*)                                    AS total
FROM app_data,
     LATERAL (VALUES ('urgente'),('importante'),('pago'),('manutencao'),('historico')) AS l(lista),
     LATERAL jsonb_array_elements(COALESCE(data->l.lista,'[]'::jsonb)) AS reg
WHERE id = 'compras_teste'
GROUP BY lista
ORDER BY lista;


-- PASSO 3 — Acrescenta o id onde falta.
--
-- Como funciona: para cada lista, desmonta o vetor em registros, acrescenta
-- o campo "id" apenas em quem não tem, e remonta o vetor NA MESMA ORDEM
-- (por isso o ORDER BY ord). A ordem importa: é ela que a tela usa hoje.

UPDATE app_data
SET data = data
  || jsonb_build_object('urgente',    (SELECT COALESCE(jsonb_agg(CASE WHEN reg ? 'id' THEN reg ELSE reg || jsonb_build_object('id', gen_random_uuid()::text) END ORDER BY ord),'[]'::jsonb)
                                       FROM jsonb_array_elements(COALESCE(data->'urgente','[]'::jsonb))    WITH ORDINALITY AS t(reg,ord)))
  || jsonb_build_object('importante', (SELECT COALESCE(jsonb_agg(CASE WHEN reg ? 'id' THEN reg ELSE reg || jsonb_build_object('id', gen_random_uuid()::text) END ORDER BY ord),'[]'::jsonb)
                                       FROM jsonb_array_elements(COALESCE(data->'importante','[]'::jsonb)) WITH ORDINALITY AS t(reg,ord)))
  || jsonb_build_object('pago',       (SELECT COALESCE(jsonb_agg(CASE WHEN reg ? 'id' THEN reg ELSE reg || jsonb_build_object('id', gen_random_uuid()::text) END ORDER BY ord),'[]'::jsonb)
                                       FROM jsonb_array_elements(COALESCE(data->'pago','[]'::jsonb))       WITH ORDINALITY AS t(reg,ord)))
  || jsonb_build_object('manutencao', (SELECT COALESCE(jsonb_agg(CASE WHEN reg ? 'id' THEN reg ELSE reg || jsonb_build_object('id', gen_random_uuid()::text) END ORDER BY ord),'[]'::jsonb)
                                       FROM jsonb_array_elements(COALESCE(data->'manutencao','[]'::jsonb)) WITH ORDINALITY AS t(reg,ord)))
  || jsonb_build_object('historico',  (SELECT COALESCE(jsonb_agg(CASE WHEN reg ? 'id' THEN reg ELSE reg || jsonb_build_object('id', gen_random_uuid()::text) END ORDER BY ord),'[]'::jsonb)
                                       FROM jsonb_array_elements(COALESCE(data->'historico','[]'::jsonb))  WITH ORDINALITY AS t(reg,ord)))
WHERE id = 'compras_teste';


-- PASSO 4 — Confere. A coluna sem_id deve ser 0 em todas as listas,
-- e o total tem de bater com o do PASSO 2 (nenhum registro sumiu).
SELECT
  'DEPOIS' AS momento,
  lista,
  count(*) FILTER (WHERE reg->>'id' IS NULL) AS sem_id,
  count(*)                                    AS total
FROM app_data,
     LATERAL (VALUES ('urgente'),('importante'),('pago'),('manutencao'),('historico')) AS l(lista),
     LATERAL jsonb_array_elements(COALESCE(data->l.lista,'[]'::jsonb)) AS reg
WHERE id = 'compras_teste'
GROUP BY lista
ORDER BY lista;


-- =====================================================================
-- SE ALGO SAIR ERRADO
-- =====================================================================
-- Use o backup do PASSO 1:
--
--   SELECT id, origem, created_at FROM app_backups
--   WHERE sistema = 'compras_teste' ORDER BY created_at DESC LIMIT 5;
--
--   SELECT restaurar_backup(<id do backup>);
--
-- =====================================================================
-- DEPOIS DE VALIDAR NO TESTE
-- =====================================================================
-- Para produção, é este mesmo arquivo trocando 'compras_teste' por
-- 'compras' nos quatro lugares onde aparece. Não faça isso antes de
-- conferir o resultado aqui.
-- =====================================================================
