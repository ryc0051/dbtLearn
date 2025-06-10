with
orders as  (
    select * from {{ ref('stg_jaffle_shop__orders') }}

),
customers as (
    select * from {{ ref('stg_jaffle_shop_customers') }}
),
payment as (
    select * from {{ ref('stg__stripe_payment') }}
    where payment_status != 'fail'
),
order_totals as (
    select
    order_id,
    payment_status as payment_order_status, -- Renamed for clarity, assuming payment_status from 'payment' is what you want
    sum(payment_amount) as order_value_dollars
    from payment
    group by 1, 2 -- Grouping by payment_status as well if it's in the select
),

order_values_joined as (
    Select
    orders.*,
    order_totals.order_value_dollars,
    order_totals.payment_order_status
    from orders
    INNER JOIN order_totals
    on orders.order_id = order_totals.order_id
),


customer_order_history as (
    select
        customers.customer_id,
        customers.full_name,
        customers.surname,
        customers.givenname,
        min(a.order_date) as first_order_date,
        min(
            case
                when
                    a.order_status not in ('returned', 'return_pending')
                    then a.order_date
            end
        ) as first_non_returned_order_date,
        max(
            case
                when
                    a.order_status not in ('returned', 'return_pending')
                    then a.order_date
            end
        ) as most_recent_non_returned_order_date,
        coalesce(max(a.user_order_seq), 0) as order_count,
        coalesce(
            count(case when a.order_status != 'returned' then 1 end), 0
        ) as non_returned_order_count,
        sum(
            case
                when a.order_status not in ('returned', 'return_pending')
                    then round(c.payment_amount / 100.0, 2)
                else 0
            end
        ) as total_lifetime_value,
        sum(
            case
                when a.order_status not in ('returned', 'return_pending')
                    then round(c.payment_amount / 100.0, 2)
                else 0
            end
        ) / nullif(
            count(
                case
                    when a.order_status not in ('returned', 'return_pending') then 1
                end
            ),
            0
        ) as avg_non_returned_order_value,
        array_agg(distinct a.order_id) as order_ids
    from orders as a
    inner join customers as customers on a.customer_id = customers.customer_id
    left outer join payment as c on a.order_id = c.order_id
    group by         
        customers.customer_id,
        customers.full_name,
        customers.surname,
        customers.givenname
)

select
    orders.order_id as order_id,
    orders.customer_id as customer_id,
    ch.surname,
    ch.givenname,
    first_order_date,
    order_count,
    total_lifetime_value,
    orders.order_status as order_order_status,
    payment.payment_status as payment_order_status,
    round(payment_amount / 100.0, 2) as order_value_dollars
from orders 
inner join customers AS c on orders.customer_id = c.customer_id
inner join
    customer_order_history AS ch
    on orders.customer_id = ch.customer_id
left outer join
     payment
    on orders.order_id = payment.order_id
