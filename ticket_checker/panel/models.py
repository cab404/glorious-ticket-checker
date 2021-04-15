from django.db import models
import uuid

# Create your models here.
class Ticket(models.Model):
    code = models.UUIDField("Ticket code", primary_key=True, auto_created=True, default=uuid.uuid4)
    full_name = models.CharField("Full name", max_length=200)
    passes = models.IntegerField("Passes", default=0)
    category = models.CharField("Category", max_length=200)
    order = models.IntegerField("Order", default=None, null=True)
    # not really interested in having it saved
    cost = models.CharField("Cost", max_length=20, null=True)
    comments = models.TextField("Comments", max_length=2000, null=True, blank=True)

    def __str__(self):
        return f"{self.full_name} (passed {self.passes} times)"
