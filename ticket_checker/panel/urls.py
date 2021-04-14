from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name = "Index page"),
    path('login', views.log_in, name = "Log in"),
    path('import_csv', views.import_csv, name = "Import CSV"),
    path('check', views.check_ticket, name = "Check ticket"),
]