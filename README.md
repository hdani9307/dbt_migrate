# dbt_migrate

dbt plugin to avoid duplicated data model migration runs

> ⚠️ Warning: Beta Phase
>
> This project is currently in **beta**.
>
> Please be aware that features may change, and there might be bugs or incomplete functionality.
> Please open an [issue](https://github.com/hdani9307/dbt_migrate/issues) if you encounter any
> problems or have any feedback.

## How to use

1. Install the [latest](https://github.com/hdani9307/dbt_migrate/releases) version by adding it to
   your `packages.yml` file.
2. Run `dbt run --log-level debug --select migration_history` to create the migration history table.
3. Use the `incremental_migration` materialization in your model.
4. Run `dbt run --select tag:migration` to run the migration models.

Example model

```sql
{{ 
    config(
        materialized="incremental_migration",
        incremental_strategy="append",
        unique_key=[
            "kind"
        ],
        tags=["migration"]
    ) 
}}
-- depends_on: {{ ref('migration_history') }}
SELECT kind
FROM {{ ref("animals") }}
```

## How it works

The `incremental_migration` is an extension of the default `incremental` materialization. It checks
the `migration_history` table if the model was executed before. If it was, it will skip the model.
Use the `--full-refresh` flag to force the model to run again.