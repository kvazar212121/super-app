import sys

with open('lib/screens/dental_booking_screen.dart', 'r') as f:
    content = f.read()

# Update call target
old_call = """                      CallService().startCall(0, widget.clinic.name);"""

new_call = """                      int targetId = _selectedDentist?.providerId ?? widget.clinic.providerId;
                      if (targetId == 0) targetId = widget.clinic.providerId;
                      CallService().startCall(targetId, _selectedDentist?.name ?? widget.clinic.name);"""

content = content.replace(old_call, new_call)

# Update order submission
old_order = """                  final order = ServiceOrder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    serviceName: _selectedService!,
                    providerName: widget.clinic.name,
                    address: widget.clinic.address,
                    notes: notes,
                    date: _selectedDate,
                    price: _price,
                    status: OrderStatus.pending,
                    providerId: widget.clinic.providerId > 0
                        ? widget.clinic.providerId
                        : null,
                  );"""

new_order = """                  int actualProviderId = _selectedDentist?.providerId ?? widget.clinic.providerId;
                  if (actualProviderId == 0) actualProviderId = widget.clinic.providerId;
                  
                  final order = ServiceOrder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    serviceName: _selectedService!,
                    providerName: _selectedDentist?.name ?? widget.clinic.name,
                    address: widget.clinic.address,
                    notes: notes,
                    date: _selectedDate,
                    price: _price,
                    status: OrderStatus.pending,
                    providerId: actualProviderId > 0
                        ? actualProviderId
                        : null,
                  );"""

content = content.replace(old_order, new_order)

# Update availability fetch
old_fetch = """    _availability.fetch(providerId: widget.clinic.providerId, date: _selectedDate).then((avail) {"""
new_fetch = """    
    int fetchId = _selectedDentist?.providerId ?? widget.clinic.providerId;
    if (fetchId == 0) fetchId = widget.clinic.providerId;
    
    _availability.fetch(providerId: fetchId, date: _selectedDate).then((avail) {"""

content = content.replace(old_fetch, new_fetch)

with open('lib/screens/dental_booking_screen.dart', 'w') as f:
    f.write(content)

print("dental_booking_screen.dart patched")
