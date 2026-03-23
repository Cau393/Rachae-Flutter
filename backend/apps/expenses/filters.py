import django_filters

from apps.expenses.models import Expense


EXPENSE_CATEGORY_CHOICES = (
    ("geral", "Geral"),
    ("comida", "Comida"),
    ("transporte", "Transporte"),
    ("moradia", "Moradia"),
    ("lazer", "Lazer"),
    ("viagem", "Viagem"),
    ("utilidades", "Utilidades"),
)


class ExpenseFilter(django_filters.FilterSet):
    group_id = django_filters.UUIDFilter(field_name="group_id")
    with_user = django_filters.UUIDFilter(method="filter_with_user")
    date_from = django_filters.DateFilter(field_name="expense_date", lookup_expr="gte")
    date_to = django_filters.DateFilter(field_name="expense_date", lookup_expr="lte")
    category = django_filters.ChoiceFilter(choices=EXPENSE_CATEGORY_CHOICES)
    q = django_filters.CharFilter(field_name="description", lookup_expr="icontains")
    owed_to_me = django_filters.BooleanFilter(method="filter_owed_to_me")

    def filter_with_user(self, queryset, name, value):
        del name
        return queryset

    def filter_owed_to_me(self, queryset, name, value):
        del name, value
        return queryset

    class Meta:
        model = Expense
        fields = ["group_id", "with_user", "category", "owed_to_me"]
