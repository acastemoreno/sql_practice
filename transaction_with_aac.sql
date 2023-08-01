WITH
  transactions_with_sign AS (
    SELECT
      t.account_id,
      a.balance,
      t.transaction_at,
      t.application_date,
      t.amount,
      t.operation_type,
      CASE
        when t.operation_type = 'debit' THEN t.amount * -1
        else t.amount
      END as amount_signed
    FROM
      transactions AS t
      JOIN accounts AS a ON a.id = t.account_id
    ORDER BY
      t.account_id ASC,
      t.transaction_at ASC
  ),
  transactions_with_acc AS (
    select
      *,
      SUM(tws.amount_signed) over (
        partition by
          tws.account_id
        order by
          tws.application_date DESC,
          tws.transaction_at DESC rows between unbounded preceding
          and current row
      ) as acc
    from
      transactions_with_sign as tws
  )
SELECT
  *,
  (twa.balance - twa.acc) AS balance_before_tx,
  (twa.balance - twa.acc + twa.amount_signed) AS balance_after_tx
FROM
  transactions_with_acc AS twa
WHERE
  date_trunc ('month', twa.transaction_at) = date_trunc ('month', DATE(NOW() - interval '1 month'))
ORDER BY
  twa.account_id ASC,
  twa.application_date ASC,
  twa.transaction_at ASC