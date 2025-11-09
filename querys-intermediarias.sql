--1.
SELECT
	 m.nm_razao_social,
	c.nm_campanha,
	sum(ctr.vl_total) AS VALOR_TOTAL_GASTO
FROM
	tb_marca m
LEFT JOIN th_campanha c
ON
	c.id_marca = m.id_marca
LEFT JOIN rl_contrato ctr
ON
	c.id_campanha = ctr.id_campanha
GROUP BY
	nm_razao_social,
	nm_campanha;

-------------------------------------------------
-- 2.
SELECT 
	i.nm_civil,
	i.nm_artistico,
	ps.cd_url,
	sum(m.nr_seguidores) AS TOTAL_SEGUIDORES
FROM 
	TB_INFLUENCIADOR i
LEFT JOIN tb_perfil_social ps
ON
	i.id_influenciador = ps.id_influenciador
LEFT JOIN th_metrica m
ON
	ps.id_perfil_social = m.id_perfil_social
GROUP BY
	i.nm_civil,
	i.nm_artistico,
	ps.cd_url
;

----------------------
--3.
SELECT 
	sum(ctr.vl_total),
	n.nm_nicho
FROM 
	rl_contrato ctr
LEFT JOIN rl_influenciador_nicho rin
	ON ctr.id_influenciador = rin.id_influenciador
LEFT JOIN tb_nicho n
	ON rin.id_nicho = n.id_nicho
GROUP BY n.nm_nicho;

---------------------
--4.
SELECT
	c.nm_campanha,
	count(ic.*) AS qtd
FROM th_campanha c
LEFT JOIN
rl_contrato ctr
ON c.id_campanha = ctr.id_campanha
LEFT JOIN tb_item_contrato ic
ON ctr.id_contrato = ic.id_contrato
GROUP BY nm_campanha;

--------------------------------------------------------------------
-- 5.
SELECT 
	m.nm_razao_social,
	c.nm_campanha,
	ctr.id_contrato,
	ctr.vl_total,
	sum(ctr.vl_total) OVER (PARTITION BY ctr.id_campanha) AS VALOR_TOTAL_CAMPANHA
FROM rl_contrato ctr
LEFT JOIN th_campanha c ON ctr.id_campanha = c.id_campanha
LEFT JOIN tb_marca m ON c.id_marca = m.id_marca;
--------------------------------
--6.
SELECT i.nm_civil, SUM(c.vl_total), tf.st_status
FROM	tb_influenciador i
JOIN rl_contrato c ON i.id_influenciador = c.id_influenciador
JOIN tb_transacao_financeira tf ON tf.id_contrato = c.id_contrato
WHERE		tf.st_status = 'Pendente'
GROUP BY  i.nm_civil, tf.st_status

------------------------------
--7.
SELECT c.nm_campanha AS "Campanha", count(ic.id_item_contrato) AS "Em Andamento" 
FROM th_campanha c
JOIN	rl_contrato ct ON ct.id_campanha = c.id_campanha
JOIN	tb_item_contrato ic ON ic.id_contrato = ct.id_contrato
WHERE c.st_campanha = 'Ativa'AND ic.st_status = 'Em andamento'
GROUP BY c.nm_campanha

-----------------------------
--8.
SELECT 
    p.nm_plataforma AS "Plataforma",
    COUNT(DISTINCT s.id_perfil_social) AS "Total de Perfis",
    ROUND(AVG(m.nr_seguidores), 2) AS "Média de Seguidores"
FROM tb_plataforma p
LEFT JOIN tb_perfil_social s 
    ON s.id_plataforma = p.id_plataforma
LEFT JOIN th_metrica m 
    ON m.id_perfil_social = s.id_perfil_social
GROUP BY p.nm_plataforma
HAVING AVG(m.nr_seguidores) IS NOT NULL
ORDER BY "Média de Seguidores" DESC;
-----------------------------
--9.
SELECT tm.nm_razao_social AS Campanha, count(rc.id_contrato) AS "Total de contratos", avg(rc.vl_total) AS "Média por contrato"
FROM tb_marca tm
JOIN th_campanha tc ON tc.id_marca = tm.id_marca 
JOIN rl_contrato rc ON rc.id_campanha = tc.id_campanha
WHERE tc.st_campanha = 'Ativa'
GROUP BY tm.nm_razao_social
ORDER BY "Média por contrato" DESC;
-----------------------------
--10.
SELECT ti.nm_civil AS "Influênciador", count(DISTINCT n.id_nicho) AS "Qtd de Nichos"
FROM tb_influenciador ti
LEFT JOIN rl_influenciador_nicho rin ON rin.id_influenciador = ti.id_influenciador
LEFT JOIN tb_nicho n ON n.id_nicho = rin.id_nicho 
GROUP BY ti.nm_civil;

