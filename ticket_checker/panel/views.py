from django.shortcuts import render
from django.http import HttpResponse, JsonResponse, HttpResponseRedirect, Http404
from django.http.request import HttpRequest

from django.contrib.auth import authenticate, get_user, login, logout
from django.contrib.auth.decorators import login_required
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction

from django.contrib.admin.models import LogEntryManager, CHANGE, ContentType
from django.contrib.admin.options import ModelAdmin

import uuid

from .models import Ticket
import csv
import io
from django.core.validators import EmailValidator
from django.core.exceptions import ValidationError

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
        try:
            with transaction.atomic():
                for line in reader:
                    imported += 1
                    email = None if line["E-mail"] == "" else line["E-mail"].strip()

                    EmailValidator(f"Problem with email on line {imported} {line} ")(email)

                    ticket = Ticket(
                        full_name = line["Name"],
                        cost = line["Cost"],
                        category = line["Category"],
                        comments = line["Comment"],
                        order = None if line["Order"] == "" else line["Order"],
                        email = email,
                    )
                    ticket.save()
                    ModelAdmin.log_addition(
                        None,
                        request,
                        ticket,
                        f"Created from CSV line {line}"
                    )
        except ValidationError as e:
            return render(request, "panel/import_tickets.html", { "message": f"Error! {e}" })
        return render(request, "panel/import_tickets.html", { "message": f"Success! Imported {imported} tickets" })

@login_required
def ticket_checker(request: HttpRequest):
    return render(request, "panel/checker.html")

@login_required
def quick_reject_ticket(request: HttpRequest, something: str):
    return JsonResponse({"error": "That's really not a ticket"})

@login_required
def check_ticket(request: HttpRequest, ticket_uuid: uuid.uuid4):
    ticket = Ticket.objects.filter(code = ticket_uuid).first()
    if ticket is None:
        return JsonResponse({"error": "Ticket not found"})
    ticket.passes += 1
    ticket.save()
    return JsonResponse({
        "cost": ticket.cost,
        "order": ticket.order,
        "passes": ticket.passes,
        "email": ticket.email,
        "comments": ticket.comments,
        "category": ticket.category,
        "full_name": ticket.full_name
    })

# Create your views here.
def index(request: HttpRequest):
    if request.POST and request.POST["action"] == "logout":
        logout(request)
    return render(request, "panel/index.html", {"server_name": request.get_host()})
