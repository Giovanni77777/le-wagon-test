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
        where extract(year from t.created_date) = 2018
    ),
    new_user_transactions as (
        select
            extract(month from t.transaction_date) as month,
            t.user_id,
            t.user_creation_date,
            count(t.transaction_id) as transactions,
            case
                when
                    extract(month from t.user_creation_date)
                    = extract(month from t.transaction_date)
                then 'new'
                else 'existing'
            end as user_type
        from transaction_data t
        group by
            extract(month from t.transaction_date),
            extract(month from t.user_creation_date),
            t.transaction_date,
            t.user_creation_date,
            t.user_id

    ),
    monthly_users as (
        select
            nut.month,
            nut.user_type,
            count(distinct(nut.user_id)) as users,
            sum(nut.transactions) as transactions
        from new_user_transactions nut
        group by nut.month, nut.user_type
    ),
    retention as (
        select
            mu.month,
            mu.user_type,
            mu.users,
            lag(mu.users, 1) over (
                partition by mu.user_type order by month
            ) as previous_users
        from monthly_users mu
    )
select r.month, r.user_type, r.users, r.previous_users
from retention r
