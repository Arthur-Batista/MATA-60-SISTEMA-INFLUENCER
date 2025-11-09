--------------------------------
----- CONSULTAS AVANÇADAS ------
--------------------------------

-- 1. Calcula o balanço financeiro e o total de contratos para cada campanha de cada marca.
SELECT * FROM (
SELECT 	
	c.nm_campanha AS CAMPANHA,
	m.nm_razao_social AS MARCA,
	sum(ctr.vl_total) OVER (PARTITION BY ctr.id_campanha) AS BALANCO_FINANCEIRO,
	count(ctr.*) OVER (PARTITION BY ctr.id_campanha) AS TOTAL_CONTRATOS
FROM rl_contrato ctr
LEFT JOIN th_campanha c ON ctr.id_campanha = c.id_campanha
LEFT JOIN tb_marca m ON c.id_marca = m.id_marca
)
GROUP BY CAMPANHA, MARCA, BALANCO_FINANCEIRO, TOTAL_CONTRATOS;
	

-- 2. Lista os 5 influenciadores do nicho "Games" que mais geraram faturamento.
SELECT 
    i.nm_civil,
    i.nm_artistico,
    SUM(ctr.vl_total) AS FATURAMENTO,
    COUNT(ctr.id_contrato) AS TOTAL_CONTRATOS, 
    n.nm_nicho
FROM tb_influenciador i
LEFT JOIN rl_contrato ctr ON i.id_influenciador = ctr.id_influenciador
LEFT JOIN rl_influenciador_nicho rin ON i.id_influenciador = rin.id_influenciador 
LEFT JOIN tb_nicho n ON rin.id_nicho = n.id_nicho
WHERE n.nm_nicho = 'Games'
GROUP BY i.nm_civil, n.nm_nicho, i.nm_artistico
ORDER BY FATURAMENTO DESC
LIMIT 5;

-- 3. Cria um ranking de campanhas com base no "custo médio por item de contrato".
WITH CUSTO_MEDIO AS (
	SELECT *, (faturamento / qtd) AS custo_medio FROM (
	SELECT 
		id_contrato,
		sum(vl_total) OVER (PARTITION BY id_contrato) AS faturamento,
		count(*) OVER (PARTITION BY id_contrato) AS qtd
		FROM  (
		SELECT 
			ctr.id_contrato,
			ctr.vl_total
		FROM rl_contrato ctr
		LEFT JOIN tb_item_contrato tic ON ctr.id_contrato = tic.id_contrato
	)) GROUP BY faturamento, qtd, id_contrato
),
campanhas_e_marcas AS (
SELECT 
	c.nm_campanha AS CAMPANHA,
	m.nm_razao_social AS MARCA,
	ctr.id_contrato
FROM th_campanha c
LEFT JOIN tb_marca m ON c.id_marca = m.id_marca
LEFT JOIN rl_contrato ctr ON c.id_campanha = ctr.id_campanha)
SELECT
	cem.campanha,
	cem.marca,
	cm.custo_medio,
	rank() OVER (ORDER BY cm.custo_medio desc)
	FROM custo_medio cm
LEFT JOIN campanhas_e_marcas cem ON cm.id_contrato = cem.id_contrato
;

-- 4. Lista o percentual de participação de cada contrato no valor total da campanha.
SELECT
    c.nm_campanha,
    i.nm_civil,
    ctr.vl_total,
    ROUND((ctr.vl_total / SUM(ctr.vl_total) OVER (PARTITION BY ctr.id_campanha)) * 100, 2) || '%' AS percentual_participacao,
    COUNT(ctr.id_contrato) OVER (PARTITION BY ctr.id_campanha) AS QTD_CONTRATOS_CAMPANHA
FROM th_campanha c
LEFT JOIN rl_contrato ctr ON ctr.id_campanha = c.id_campanha
LEFT JOIN tb_influenciador i ON ctr.id_influenciador = i.id_influenciador
ORDER BY c.nm_campanha;

-- 5. Encontra o influenciador com mais seguidores (métrica mais recente) em cada plataforma.
WITH ranking AS (
    SELECT 
        p.nm_plataforma,
        i.nm_civil,
        tm.nr_seguidores,
        ROW_NUMBER() OVER (PARTITION BY p.nm_plataforma ORDER BY tm.nr_seguidores DESC) AS posicao
    FROM th_metrica tm
    LEFT JOIN tb_perfil_social ps ON tm.id_perfil_social = ps.id_perfil_social
    LEFT JOIN tb_plataforma p ON ps.id_plataforma = p.id_plataforma
    LEFT JOIN tb_influenciador i ON ps.id_influenciador = i.id_influenciador
)
SELECT 
    nm_plataforma,
    nm_civil,
    nr_seguidores
FROM ranking
WHERE posicao = 1;

-- 6. Mostra o crescimento de seguidores mês a mês, comparando com a coleta anterior.
WITH DADOS_CRESCIMENTO AS (
    SELECT 
        ps.id_perfil_social,
        p.nm_plataforma,
        tm.dt_coleta,
        tm.nr_seguidores,
        LAG(tm.nr_seguidores, 1, 0) OVER (
            PARTITION BY ps.id_perfil_social, p.nm_plataforma
            ORDER BY tm.dt_coleta
        ) AS seguidores_mes_anterior
    FROM 
        tb_perfil_social ps
    LEFT JOIN
        th_metrica tm ON ps.id_perfil_social = tm.id_perfil_social
    LEFT JOIN 
        tb_plataforma p ON ps.id_plataforma = p.id_plataforma
)
SELECT 
    id_perfil_social,
    nm_plataforma,
    to_char(dt_coleta, 'dd-mm-yyyy') AS data_coleta,
    nr_seguidores,
    seguidores_mes_anterior,
    (nr_seguidores - seguidores_mes_anterior) AS crescimento
FROM 
    DADOS_CRESCIMENTO
ORDER BY 
    id_perfil_social, nm_plataforma, dt_coleta;

-- 7. Lista campanhas "Ativas" que têm cláusula de exclusividade e conta seus influenciadores.
SELECT 
	c.nm_campanha,
	COUNT(DISTINCT i.id_influenciador) AS qtd_influenciadores
FROM th_campanha c
LEFT JOIN rl_contrato ctr ON c.id_campanha = ctr.id_campanha
LEFT JOIN tb_influenciador i ON i.id_influenciador = ctr.id_influenciador
WHERE c.st_campanha = 'Ativa'
  AND c.id_campanha IN (
      SELECT id_campanha 
      FROM rl_contrato
      WHERE ds_clausula_exclusividade IS NOT NULL
  )
GROUP BY c.nm_campanha;

-- 8. Identifica campanhas "problemáticas" com itens de contrato ainda pendentes.
SELECT 
	c.nm_campanha,
	m.nm_razao_social,
	COUNT(*) FILTER (WHERE ic.st_status <> 'Concluido') AS qtd_pendentes
FROM th_campanha c
LEFT JOIN rl_contrato ctr ON c.id_campanha = ctr.id_campanha
LEFT JOIN tb_item_contrato ic ON ctr.id_contrato = ic.id_contrato
LEFT JOIN tb_marca m ON m.id_marca = c.id_marca
GROUP BY c.nm_campanha, m.nm_razao_social;

-- 9. Para cada nicho, encontra a campanha e o influenciador que representam o maior gasto.
SELECT 
	nm_nicho AS NICHO,
	nm_campanha AS CAMPANHA,
	nm_civil AS INFLUENCIADOR,
	valor_total
FROM (
	SELECT 
		n.nm_nicho,
		c.nm_campanha,
		sum(c.vl_orcamento) AS valor_total,
		i.nm_civil,
		RANK() OVER (PARTITION BY n.nm_nicho ORDER BY ctr.vl_total)
	FROM tb_nicho n
	LEFT JOIN rl_influenciador_nicho rin ON n.id_nicho = rin.id_nicho
	LEFT JOIN tb_influenciador i ON rin.id_influenciador = i.id_influenciador
	LEFT JOIN rl_contrato ctr ON i.id_influenciador = ctr.id_influenciador 
	LEFT JOIN th_campanha c ON ctr.id_campanha = c.id_campanha
	GROUP BY n.nm_nicho, c.nm_campanha, ctr.vl_total, i.nm_civil
) WHERE RANK = 1;

-- 10. Lista influenciadores com alto volume de contratos (mais de 5).
SELECT
    i.NM_ARTISTICO,
    COUNT(ctr.ID_CONTRATO) AS TOTAL_CONTRATOS,
    COUNT(DISTINCT ctr.ID_CAMPANHA) AS TOTAL_CAMPANHAS_UNICAS
FROM TB_INFLUENCIADOR i
JOIN RL_CONTRATO ctr ON i.ID_INFLUENCIADOR = ctr.ID_INFLUENCIADOR
JOIN TH_CAMPANHA c ON ctr.ID_CAMPANHA = c.ID_CAMPANHA
GROUP BY i.NM_ARTISTICO
HAVING COUNT(ctr.ID_CONTRATO) > 5;

-- 11. Lista campanhas com orçamento acima da média geral.
SELECT
    m.NM_RAZAO_SOCIAL,
    c.NM_CAMPANHA,
    c.VL_ORCAMENTO,
    COUNT(ctr.ID_CONTRATO) AS QTD_CONTRATOS
FROM TH_CAMPANHA c
JOIN TB_MARCA m ON c.ID_MARCA = m.ID_MARCA
LEFT JOIN RL_CONTRATO ctr ON c.ID_CAMPANHA = ctr.ID_CAMPANHA
WHERE c.VL_ORCAMENTO > (
    SELECT AVG(VL_ORCAMENTO) FROM TH_CAMPANHA
)
GROUP BY m.NM_RAZAO_SOCIAL, c.NM_CAMPANHA, c.VL_ORCAMENTO;

-- 12. Mostra o total de entregáveis (itens) por campanha e marca.
SELECT
    m.NM_RAZAO_SOCIAL,
    c.NM_CAMPANHA,
    COUNT(tic.ID_ITEM_CONTRATO) AS TOTAL_ITENS
FROM TB_MARCA m
JOIN TH_CAMPANHA c ON m.ID_MARCA = c.ID_MARCA
LEFT JOIN RL_CONTRATO ctr ON c.ID_CAMPANHA = ctr.ID_CAMPANHA
LEFT JOIN TB_ITEM_CONTRATO tic ON ctr.ID_CONTRATO = tic.ID_CONTRATO
GROUP BY m.NM_RAZAO_SOCIAL, c.NM_CAMPANHA;

-- 13. Mostra detalhes do contrato e o total de contratos do influenciador na mesma linha.
SELECT
    i.NM_ARTISTICO,
    c.NM_CAMPANHA,
    ctr.ID_CONTRATO,
    COUNT(ctr.ID_CONTRATO) OVER (PARTITION BY i.ID_INFLUENCIADOR) AS TOTAL_CONTRATOS_INFLUENCIADOR
FROM TB_INFLUENCIADOR i
JOIN RL_CONTRATO ctr ON i.ID_INFLUENCIADOR = ctr.ID_INFLUENCIADOR
JOIN TH_CAMPANHA c ON ctr.ID_CAMPANHA = c.ID_CAMPANHA
ORDER BY i.NM_ARTISTICO;

-- 14. Lista campanhas com alto volume de comunicação (mais de 3 logs).
SELECT
    c.NM_CAMPANHA,
    m.NM_RAZAO_SOCIAL,
    COUNT(trc.ID_REGISTRO_COMUNICACAO) AS QTD_LOGS
FROM TH_CAMPANHA c
JOIN TB_MARCA m ON c.ID_MARCA = m.ID_MARCA
JOIN TL_REGISTRO_COMUNICACAO trc ON c.ID_CAMPANHA = trc.ID_CAMPANHA
GROUP BY c.NM_CAMPANHA, m.NM_RAZAO_SOCIAL
HAVING COUNT(trc.ID_REGISTRO_COMUNICACAO) > 3;

-- 15. Agrupa o valor total e a contagem de transações por modelo de pagamento e campanha.
SELECT
    ctr.DS_MODELO_PAGAMENTO,
    c.NM_CAMPANHA,
    SUM(tf.VL_VALOR) AS VALOR_TOTAL,
    COUNT(tf.ID_TRANSACAO_FINANCEIRA) AS QTD_TRANSACOES
FROM TB_TRANSACAO_FINANCEIRA tf
JOIN RL_CONTRATO ctr ON tf.ID_CONTRATO = ctr.ID_CONTRATO
JOIN TH_CAMPANHA c ON ctr.ID_CAMPANHA = c.ID_CAMPANHA
GROUP BY ctr.DS_MODELO_PAGAMENTO, c.NM_CAMPANHA;

-- 16. Balanço Financeiro por Marca
-- Descrição: Mostra para cada influencer, o número total de campanhas, o total recebido e o seu maior contrato
SELECT 
    i.nm_civil AS influenciador,
    COUNT(DISTINCT c.id_campanha) AS total_campanhas,
    SUM(ctr.vl_total) AS total_recebido,
    MAX(ctr.vl_total) AS maior_contrato
FROM tb_influenciador i
JOIN rl_contrato ctr 
    ON i.id_influenciador = ctr.id_influenciador
JOIN th_campanha c 
    ON ctr.id_campanha = c.id_campanha
GROUP BY i.nm_civil
ORDER BY total_recebido DESC;


-- 17. Mostra o valor do contrato e a média de faturamento daquele nicho na mesma linha.
SELECT
    i.NM_CIVIL,
    n.NM_NICHO,
    ctr.VL_TOTAL,
    AVG(ctr.VL_TOTAL) OVER (PARTITION BY n.ID_NICHO) AS MEDIA_FATURAMENTO_NICHO
FROM TB_INFLUENCIADOR i
JOIN RL_CONTRATO ctr ON i.ID_INFLUENCIADOR = ctr.ID_INFLUENCIADOR
JOIN RL_INFLUENCIADOR_NICHO rin ON i.ID_INFLUENCIADOR = rin.ID_INFLUENCIADOR
JOIN TB_NICHO n ON rin.ID_NICHO = n.ID_NICHO
GROUP BY i.NM_CIVIL, n.NM_NICHO, ctr.VL_TOTAL, n.ID_NICHO;

-- 18. Calcula a média de seguidores (da métrica mais recente) por plataforma.
WITH RankingMetricas AS (
    SELECT
        ps.ID_PERFIL_SOCIAL,
        ps.ID_PLATAFORMA,
        tm.NR_SEGUIDORES,
        ROW_NUMBER() OVER(PARTITION BY ps.ID_PERFIL_SOCIAL ORDER BY tm.DT_COLETA DESC) as rn
    FROM TB_PERFIL_SOCIAL ps
    JOIN TH_METRICA tm ON ps.ID_PERFIL_SOCIAL = tm.ID_PERFIL_SOCIAL
),
MetricasRecentes AS (
    SELECT ID_PLATAFORMA, ID_PERFIL_SOCIAL, NR_SEGUIDORES
    FROM RankingMetricas WHERE rn = 1
)
SELECT
    p.NM_PLATAFORMA,
    COUNT(mr.ID_PERFIL_SOCIAL) AS QTD_PERFIS,
    AVG(mr.NR_SEGUIDORES)::INT AS MEDIA_SEGUIDORES
FROM TB_PLATAFORMA p
JOIN MetricasRecentes mr ON p.ID_PLATAFORMA = mr.ID_PLATAFORMA
GROUP BY p.NM_PLATAFORMA;

-- 19. Gera um relatório financeiro para a marca com mais campanhas.
WITH MarcaMaisAtiva AS (
    SELECT
        ID_MARCA
    FROM TH_CAMPANHA
    GROUP BY ID_MARCA
    ORDER BY COUNT(ID_CAMPANHA) DESC
    LIMIT 1
)
SELECT
    m.NM_RAZAO_SOCIAL,
    c.NM_CAMPANHA,
    COUNT(ctr.ID_CONTRATO) AS QTD_CONTRATOS,
    SUM(ctr.VL_TOTAL) AS VALOR_TOTAL_FATURADO
FROM TH_CAMPANHA c
JOIN TB_MARCA m ON c.ID_MARCA = m.ID_MARCA
LEFT JOIN RL_CONTRATO ctr ON c.ID_CAMPANHA = ctr.ID_CAMPANHA
WHERE c.ID_MARCA = (SELECT ID_MARCA FROM MarcaMaisAtiva)
GROUP BY m.NM_RAZAO_SOCIAL, c.NM_CAMPANHA;

-- 20. Conta quantos influenciadores únicos estão em campanhas ativas E com cláusula de exclusividade.
SELECT
    COUNT(DISTINCT i.ID_INFLUENCIADOR) AS QTD_INFLUENCIADORES_EXCLUSIVOS
FROM TB_INFLUENCIADOR i
JOIN RL_CONTRATO ctr ON i.ID_INFLUENCIADOR = ctr.ID_INFLUENCIADOR
JOIN TH_CAMPANHA c ON ctr.ID_CAMPANHA = c.ID_CAMPANHA
WHERE c.ST_CAMPANHA = 'Ativa'
  AND ctr.DS_CLAUSULA_EXCLUSIVIDADE IS NOT NULL;