import sys

with open('lib/screens/master_dispatch_screen.dart', 'r') as f:
    content = f.read()

old_address_ui = """                    TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ko\\'cha, uy, orientir...',
                        prefixIcon: const Icon(LucideIcons.mapPin),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),"""

new_address_ui = """                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Ko\\'cha, uy, orientir...',
                              prefixIcon: const Icon(LucideIcons.mapPin),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _accent, width: 1.5),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.map, color: _accent),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Xaritadan tanlash tez orada qo\\'shiladi')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),"""

content = content.replace(old_address_ui, new_address_ui)

with open('lib/screens/master_dispatch_screen.dart', 'w') as f:
    f.write(content)
