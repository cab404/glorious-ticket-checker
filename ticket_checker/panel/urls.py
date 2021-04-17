from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name = "Index page"),
    path('login', views.log_in, name = "Log in"),
    path('import_csv', views.import_csv, name = "Import CSV"),
    path('ticket/<uuid:ticket_uuid>', views.check_ticket, name = "Check ticket by UUID"),
    path('check', views.check_ticket, name = "Check ticket"),
    path('checker', views.ticket_checker, name = "Ticket checker page"),
    path('checker/qr-worker.js', views.ticket_checker, name = "Ticket checker page"),
]