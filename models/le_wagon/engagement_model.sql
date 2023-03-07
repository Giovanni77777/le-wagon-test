with
    transaction_data as (
        select
            t.transaction_id,
            t.created_date as transaction_date,
            t.amount_usd,
            t.transactions_type,
            u.user_id,
            u.birth_year,
            u.country,
            u.created_date as user_creation_date,
            u.plan,
            u.num_contacts
        from `le-wagon-test-379821.db.transactions` as t
        left join `le-wagon-test-379821.db.users` as u on u.user_id = t.user_id
        where t.transactions_state = 'COMPLETED'
    ),
    user_transaction_count as (
        select t.user_id, count(t.transaction_id) as user_transaction_count
        from transaction_data as t
        group by t.user_id
    ),
    country_transaction_metrics as (
        select
            t.country,
            avg(t.amount_usd) as avg_amount_usd,
            avg(utc.user_transaction_count) as avg_transaction_count
        from transaction_data t
        left join user_transaction_count utc on utc.user_id = t.user_id
        group by t.country
    )
select
    t.country,
    t.user_id,
    t.plan,
    t.birth_year,
    t.num_contacts,
    count(t.transaction_id) / ctm.avg_transaction_count as transaction_score,
    sum(t.amount_usd) / ctm.avg_amount_usd as amount_score,
    0.5 * (
        (count(t.transaction_id) / ctm.avg_transaction_count)
        + (sum(t.amount_usd) / ctm.avg_amount_usd)
    ) as engagement_score
from transaction_data t
left join country_transaction_metrics ctm on ctm.country = t.country
group by
    t.country,
    t.user_id,
    t.plan,
    t.birth_year,
    t.num_contacts,
    ctm.avg_transaction_count,
    ctm.avg_amount_usd
