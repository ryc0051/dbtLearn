select
    id as order_id,
    user_id as customer_id,
    order_date,
    status,
    _ETL_LOADED_AT AS _batched_at
from {{ source('jaffle_shop', 'orders') }}