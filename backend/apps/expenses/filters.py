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
    date_from = django_filters.DateFilter(field_name="expense_date", lookup_expr="gte")
    date_to = django_filters.DateFilter(field_name="expense_date", lookup_expr="lte")
    category = django_filters.ChoiceFilter(choices=EXPENSE_CATEGORY_CHOICES)
    q = django_filters.CharFilter(field_name="description", lookup_expr="icontains")

    class Meta:
        model = Expense
        fields = ["group_id", "category"]
