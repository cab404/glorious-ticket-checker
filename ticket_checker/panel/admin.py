from django.contrib import admin
from django.contrib.auth.models import Group

# Register your models here.
from .models import Ticket

class TicketAdmin(admin.ModelAdmin):
    list_display = ("full_name", "category", "cost", "passes", )
    search_fields = ("full_name", "comments", )
    list_filter = ("category", )

admin.site.register(Ticket, TicketAdmin)
admin.site.unregister(Group)
admin.site.site_header = "Glorious Ticket Checker"