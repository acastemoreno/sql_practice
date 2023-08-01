select
  temp.account_id,
	(temp.balance + temp.sum_debit_junio_julio - temp.sum_credit_junio_julio) as saldo_inicio_junio,
  (temp.sum_credit_junio_julio - temp.sum_credit_julio) as credit_junio,
  (temp.sum_debit_junio_julio - temp.sum_debit_julio) as debit_junio,
  (temp.balance + temp.sum_debit_julio - temp.sum_credit_julio) as saldo_final_junio,
  temp.balance
from
  (
    select
      a.id as account_id,
      a.balance,
      coalesce(
        sum(t.amount) filter (
          where
            t.operation_type = 'credit'
        ),
        0
      ) as sum_credit_junio_julio,
      coalesce(
        sum(t.amount) filter (
          where
            t.operation_type = 'credit' and date_trunc ('month', t.transaction_at) = date_trunc ('month', NOW())
        ),
        0
      ) as sum_credit_julio,
      coalesce(
        sum(t.amount) filter (
          where
            t.operation_type = 'debit'
        ),
        0
      ) as sum_debit_junio_julio,
    	coalesce(
        sum(t.amount) filter (
          where
            t.operation_type = 'debit' and date_trunc ('month', t.transaction_at) = date_trunc ('month', NOW())
        ),
        0
      ) as sum_debit_julio,
      sum(t.amount) as sum_without_operation_type
    from
      accounts as a
      join transactions as t on a.id = t.account_id
      and date_trunc ('month', t.transaction_at) >= date_trunc ('month', DATE(NOW() - interval '1 month'))
    group by
      a.id
    order by
      a.id
  ) as temp