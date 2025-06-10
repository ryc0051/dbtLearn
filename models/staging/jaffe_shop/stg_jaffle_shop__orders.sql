with 
source as (
    SELECT * from {{ source('jaffle_shop', 'orders') }}
),

transformed as (

select
        id as order_id,
        user_id AS customer_id,
        order_date,
        status as order_status,
        row_number() over (
            partition by user_id order by order_date, id
        ) as user_order_seq
    FROM source
 --   {{limit_data_in_dev('order_date')}}
)

SELECT * From transformed