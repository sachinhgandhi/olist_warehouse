{% macro get_date_key_format(date_value, date_format="YYYYMMDD") %}

    {{ return("to_number(to_char(" ~ date_value ~ ", '" ~ date_format ~ "'))") }}

{% endmacro %}
