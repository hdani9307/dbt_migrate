{{
    config(
            materialized='incremental',
            unique_key='model_name'
    )
}}

SELECT '' as model_name, {{ dbt.current_timestamp() }} as ran_at