with 

source as (
    select * from {{ source('stripe', 'payment') }}
),

transformed as (
    select 
    id as payment_id,
    orderid as order_id,
    status as payment_status,
    {{cents_to_dollars('amount',2)}} as payment_amount,
    PAYMENTMETHOD as payment_method

    from source
)
SELECT * FROM transformed