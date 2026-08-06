-- =====================================================================
-- MÓDULO DE PRODUÇÃO — criação do registro no banco de TESTE
-- =====================================================================
--
-- O QUE ESTE ARQUIVO FAZ
--   Cria uma linha nova na tabela app_data, com o identificador
--   'producao_teste'. É nela que o módulo de Produção vai guardar as obras.
--   É o mesmo formato já usado por 'compras_teste' e 'financeiro_teste':
--   um único documento JSON na coluna "data".
--
-- O QUE ELE NÃO FAZ
--   Não cria tabelas novas. Não altera nada que já existe. Não mexe em
--   produção. Se a linha 'producao_teste' já existir, ele não sobrescreve.
--
-- COMO RODAR
--   1. Abra o SQL Editor do Supabase
--   2. Cole este arquivo inteiro
--   3. Clique em Run
--   4. Confira o resultado da última consulta (deve mostrar producao_teste)
--
-- =====================================================================


-- PASSO 1 — Backup antes de qualquer coisa.
-- Regra do projeto: nunca alterar o banco sem um ponto de retorno.
SELECT fazer_backup('manual');


-- PASSO 2 — Cria o registro do módulo de Produção.
--
-- Sobre o conteúdo inicial: o registro NÃO nasce vazio. Ele já vem com a
-- estrutura { "obras": [] } e uma marcação de origem. Isso é proposital —
-- existe uma trava no banco que impede gravar dados vazios por cima de
-- registros com conteúdo, e um registro nascer vazio poderia confundi-la.
--
-- O ON CONFLICT garante que, se você rodar este arquivo duas vezes por
-- engano, nada é sobrescrito e nenhuma obra é perdida.

INSERT INTO app_data (id, data)
VALUES (
  'producao_teste',
  '{
     "obras": [],
     "criadoEm": "2026-08-06",
     "origem": "modulo-producao-fase-1"
   }'::jsonb
)
ON CONFLICT (id) DO NOTHING;


-- PASSO 3 — Confere se deu certo.
-- Deve aparecer uma linha com id = producao_teste e total_obras = 0.

SELECT
  id,
  jsonb_array_length(COALESCE(data->'obras','[]'::jsonb)) AS total_obras,
  data->>'origem' AS origem
FROM app_data
WHERE id = 'producao_teste';


-- =====================================================================
-- SE PRECISAR DESFAZER
-- =====================================================================
-- Enquanto o módulo estiver vazio, dá para remover o registro sem perda:
--
--   DELETE FROM app_data WHERE id = 'producao_teste';
--
-- Depois que houver obras cadastradas, NÃO use o comando acima —
-- use restaurar_backup(id) com o backup do PASSO 1.
-- =====================================================================
