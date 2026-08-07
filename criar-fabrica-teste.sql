-- =====================================================================
-- MÓDULO FÁBRICA — criação do registro no banco de TESTE
-- =====================================================================
--
-- O QUE ESTE ARQUIVO FAZ
--   Cria uma linha nova na tabela app_data, com o identificador
--   'fabrica_teste'. É nela que o módulo Fábrica vai guardar as obras.
--   É o mesmo formato já usado por 'compras_teste' e 'financeiro_teste':
--   um único documento JSON na coluna "data".
--
--   OBSERVAÇÃO SOBRE O NOME: o identificador vai SEM acento e SEM cedilha
--   ('fabrica_teste', não 'fábrica_teste'). O módulo informa o sistema ao
--   Worker por um cabeçalho HTTP, e cabeçalho não aceita caractere
--   acentuado. Na tela o módulo aparece como "Fábrica", com acento.
--
-- POR QUE ELE É OBRIGATÓRIO
--   Testamos gravar pelo Worker sem criar o registro antes: ele respondeu
--   {"ok":true} mas NÃO gravou nada. O Worker só atualiza registro que já
--   existe. Sem rodar este arquivo, o módulo parece salvar e não salva.
--
-- O QUE ELE NÃO FAZ
--   Não cria tabelas novas. Não altera nada que já existe. Não mexe em
--   produção. Se a linha 'fabrica_teste' já existir, não sobrescreve.
--
-- COMO RODAR
--   1. Abra o SQL Editor do Supabase
--   2. Cole este arquivo inteiro
--   3. Clique em Run
--   4. Confira o resultado da última consulta (deve mostrar fabrica_teste)
--
-- =====================================================================


-- PASSO 1 — Backup antes de qualquer coisa.
-- Regra do projeto: nunca alterar o banco sem um ponto de retorno.
SELECT fazer_backup('manual');


-- PASSO 2 — Cria o registro do módulo Fábrica.
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
  'fabrica_teste',
  '{
     "obras": [],
     "criadoEm": "2026-08-07",
     "origem": "modulo-fabrica-fase-1"
   }'::jsonb
)
ON CONFLICT (id) DO NOTHING;


-- PASSO 3 — Confere se deu certo.
-- Deve aparecer uma linha com id = fabrica_teste e total_obras = 0.

SELECT
  id,
  jsonb_array_length(COALESCE(data->'obras','[]'::jsonb)) AS total_obras,
  data->>'origem' AS origem
FROM app_data
WHERE id = 'fabrica_teste';


-- =====================================================================
-- SE PRECISAR DESFAZER
-- =====================================================================
-- Enquanto o módulo estiver vazio, dá para remover o registro sem perda:
--
--   DELETE FROM app_data WHERE id = 'fabrica_teste';
--
-- Depois que houver obras cadastradas, NÃO use o comando acima —
-- use restaurar_backup(id) com o backup do PASSO 1.
-- =====================================================================
