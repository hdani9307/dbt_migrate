{% materialization migrate, adapter='trino' %}

    {%- set existing_relation = load_cached_relation(this) -%}
    {% set model_name = this.name %}
    {% set target_relation = this.incorporate(type='table') %}
    {%- set intermediate_relation = make_intermediate_relation(target_relation) -%}
    {% set query_text %}
        select * from {{ ref('migration_history') }} where model_name='{{ model_name }}'
    {% endset %}
    {% set existing_entry = run_query(query_text) %}

    {% if existing_entry|length == 0 %}
        {{ log('Running migration ' ~ model_name, info=True) }}
        -- 'BEGIN' happens here
        {{ run_hooks(pre_hooks, inside_transaction=True) }}
        {% call statement('main') -%}
            {{ get_create_table_as_sql(False, intermediate_relation, sql) }}
        {%- endcall %}
        {% call statement('main') -%}
            insert into {{ ref('migration_history') }} (model_name,ran_at) values ('{{ model_name }}', {{ dbt.current_timestamp() }})
        {%- endcall %}

        -- cleanup
        {% if existing_relation is not none %}
            /* Do the equivalent of rename_if_exists. 'existing_relation' could have been dropped
               since the variable was first set. */
            {% set existing_relation = load_cached_relation(existing_relation) %}
            {% if existing_relation is not none %}
                {{ adapter.rename_relation(existing_relation, backup_relation) }}
            {% endif %}
        {% endif %}

        {{ adapter.rename_relation(intermediate_relation, target_relation) }}
        {% do create_indexes(target_relation) %}

        {{ run_hooks(post_hooks, inside_transaction=True) }}
        -- 'COMMIT' happens here
        {{ adapter.commit() }}
        {{ return({'relations': [target_relation]}) }}
    {% else %}
        {{ log('Not running migration ' ~ model_name, info=True)}}
        {% call statement('main') -%}
            {{ sql }}
        {%- endcall %}
        {{ return({'relations': []}) }}
    {% endif %}

{% endmaterialization %}