from django.contrib import admin
from django.db.models import QuerySet
from django.contrib.auth.models import Group
import zipfile
from qr_code.qrcode import maker as qrmaker
from django.http.response import FileResponse
import io

# Register your models here.
from .models import Ticket

def download_stuff(modeladmin, request, queryset: QuerySet[Ticket]):
    bio = io.BytesIO()
    mow = zipfile.ZipFile(bio, mode="x")
    for a in queryset:
        qr = qrmaker.make_qr_code_image(a.code, qr_code_options=qrmaker.QRCodeOptions(
            size="M",
            alignment_dark_color="#F00",
            light_color="#FFFF",
            image_format="png"
        ))
        fname = f"{str(a.full_name).strip()}-{str(a.code)[:5]}.png"
        mow.writestr(fname, qr)
    mow.close()
    bio.seek(0)
    return FileResponse(bio, as_attachment=True, filename="mow.zip")

class TicketAdmin(admin.ModelAdmin):
    list_display = ("full_name", "category", "cost", "passes", "order", )
    search_fields = ("full_name", "comments", )
    list_filter = ("category", )
    actions = [admin.actions.delete_selected, download_stuff]

admin.site.register(Ticket, TicketAdmin)
admin.site.unregister(Group)
admin.site.site_header = "Glorious Ticket Checker"