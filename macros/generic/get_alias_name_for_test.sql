{% macro get_alias_name_for_test(model_name, column_name, test_name, severity = "error")%}
    {{ return (model_name ~ "_" ~ column_name ~ "_" ~ test_name ~ "_" ~ severity ) }}
{% endmacro %}