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
        where
            t.transactions_state = 'COMPLETED'
            and extract(year from t.created_date) = 2018
    ),
    yearly_transactions_per_user as (
        select
            t.country,
            count(t.transaction_id) as transaction_count,
            count(distinct(t.user_id)) as user_count,
            count(t.transaction_id)
            / count(distinct(t.user_id)) as yearly_transactions_per_user
        from transaction_data t
        group by t.country
    )
select
    extract(month from t.transaction_date) as month,
    t.user_id,
    count(t.transaction_id) as monthly_transactions,
    yt.yearly_transactions_per_user,
    case
        when count(t.transaction_id) < 0.5 * yt.yearly_transactions_per_user
        then 'inactive'
        else 'active'
    end as is_active
from transaction_data t
left join yearly_transactions_per_user yt on yt.country = t.country
group by
    extract(month from t.transaction_date), t.user_id, yt.yearly_transactions_per_user
