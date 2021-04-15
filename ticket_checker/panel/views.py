from django.shortcuts import render
from django.http import HttpResponse
from django.http import JsonResponse, HttpResponseRedirect
from django.http.request import HttpRequest

from django.contrib.auth import authenticate, get_user, login
from django.contrib.auth.decorators import login_required
from django.views.decorators.csrf import csrf_exempt

from django.contrib.admin.models import LogEntryManager, CHANGE, ContentType
from django.contrib.admin.options import ModelAdmin

from .models import Ticket
import csv
import io

# Login
# Import CSV
# Check ticket

@csrf_exempt
def log_in(request: HttpRequest):
    username = request.POST["username"]
    password = request.POST["password"]

    user = authenticate(request=request, username = username, password = password)
    if (user != None):
        login(request, user)
    return HttpResponseRedirect("/")

@login_required(login_url="/")
def import_csv(request: HttpRequest):
    if (request.method == "GET"):
        return render(request, "panel/import_tickets.html")
    else:
        loaded_file = request.FILES["csv"]
        reader = csv.DictReader(io.TextIOWrapper(loaded_file))
        imported = 0
        for line in reader:
            imported += 1
            ticket = Ticket(
                full_name = line["Name"], 
                cost = line["Cost"], 
                category = line["Category"], 
                comments = line["Comment"],
                order = None if line["Order"] == "" else line["Order"],
            )
            ticket.save()
            ModelAdmin.log_addition(
                None, 
                request,
                ticket,
                f"Created from CSV line {line}"
            )
        
        return render(request, "panel/import_tickets.html", { "message": f"Success! Imported {imported} tickets" })
    

@login_required
def check_ticket():

    pass


def test_api(request: HttpRequest):
    user = authenticate(request=request)
    print(request.method)
    return JsonResponse({ "a": 12, "b": [1,2,3], "headers": dict(request.headers.items()), "user": get_user(request).get_username() })

# Create your views here.
def index(request: HttpRequest):
    
    ticket_count = Ticket.objects.count()
    return render(request, "panel/index.html")


def intify(request: HttpRequest, someint: int):
    return HttpResponse(f"{someint} is an int!")