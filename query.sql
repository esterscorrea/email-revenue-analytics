WITH revenue_usd AS (
  SELECT
    s.date,
    SUM(p.price) AS revenue
  FROM `DA.order` AS o
  JOIN `DA.product` AS p
    ON o.item_id = p.item_id
  JOIN `DA.session` AS s
    ON o.ga_session_id = s.ga_session_id
  GROUP BY s.date
),

email_metrics AS (
  SELECT
    DATE_ADD(s.date, INTERVAL ems.sent_date DAY) AS date,
    COUNT(DISTINCT ems.id_message) AS sent_msg,
    COUNT(DISTINCT o.id_message)   AS open_msg,
    COUNT(DISTINCT ev.id_message)  AS click_msg
  FROM `DA.email_sent` AS ems
  JOIN `DA.account_session` AS acs
    ON ems.id_account = acs.account_id
  JOIN `DA.session` AS s
    ON acs.ga_session_id = s.ga_session_id
  LEFT JOIN `DA.email_open` AS o
    ON ems.id_message = o.id_message
  LEFT JOIN `DA.email_visit` AS ev
    ON ems.id_message = ev.id_message
  GROUP BY date
),

combined AS (
  SELECT date, revenue, 0 AS cost, 0 AS sent_msg, 0 AS open_msg, 0 AS click_msg
  FROM revenue_usd
  UNION ALL
  SELECT date, 0 AS revenue, 0 AS cost, sent_msg, open_msg, click_msg
  FROM email_metrics
)

SELECT
  DATE_TRUNC(date, MONTH) AS date,
  SUM(revenue) AS revenue,
  SUM(cost) AS cost,
  SUM(sent_msg) AS emails_sent,
  SUM(open_msg)  / SUM(sent_msg) AS open_rate,
  SUM(click_msg) / SUM(sent_msg) AS click_rate,
  0 AS registrations
FROM combined
GROUP BY DATE_TRUNC(date, MONTH)
ORDER BY date
