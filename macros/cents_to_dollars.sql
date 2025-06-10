{% macro cents_to_dollars(column_name,decimal=2) %}
round(1.0 * {{column_name}} / 100, {{decimal}})
{% endmacro %}