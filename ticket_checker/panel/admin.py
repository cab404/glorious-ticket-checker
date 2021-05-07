from django.contrib import admin
from django.db.models import QuerySet
from django.contrib.auth.models import Group
import zipfile
from qr_code.qrcode import maker as qrmaker
from django.http.response import FileResponse
import io
from django.core.mail import get_connection as mail_sender, EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.translation import gettext_lazy as _
from django.conf import settings
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

download_stuff.short_description = _("Download those tickets!")

def send_emails(modeladmin, request, queryset: QuerySet[Ticket]):
    conn = mail_sender(fail_silently=False)
    def form_mail(ticket):
        return EmailMultiAlternatives(
            "Билет на кон",
            f"В этом html-письме ­— твой QR код. Посмотри его в клиенте, поддерживающем html!",
            settings.EMAIL_HOST_USER,
            [ticket.email],
            connection = conn,
            alternatives=[
                (render_to_string("panel/email.html", context={"ticket": ticket}), 'text/html')
            ]
        )

    mail_sender(fail_silently=False).send_messages([form_mail(ticket) for ticket in queryset])
send_emails.short_description = _("Send emails!")

class TicketAdmin(admin.ModelAdmin):
    list_display = ("full_name", "category", "cost", "passes", "order", )
    search_fields = ("full_name", "comments", )
    list_filter = ("category", )
    actions = [admin.actions.delete_selected, send_emails, download_stuff]

admin.site.register(Ticket, TicketAdmin)
admin.site.unregister(Group)
admin.site.site_header = "Glorious Ticket Checker"
