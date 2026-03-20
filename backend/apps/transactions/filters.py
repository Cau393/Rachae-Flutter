import django_filters

from apps.transactions.models import Transaction


class TransactionFilter(django_filters.FilterSet):
    group_id = django_filters.UUIDFilter(field_name="group_id")
    status = django_filters.CharFilter(method="filter_status")

    def filter_status(self, queryset, name, value):
        if value == "confirmed":
            return queryset.filter(is_confirmed=True)
        elif value == "disputed":
            return queryset.filter(is_disputed=True)
        elif value == "pending":
            return queryset.filter(is_confirmed=False, is_disputed=False)
        return queryset

    class Meta:
        model = Transaction
        fields = ["group_id"]
