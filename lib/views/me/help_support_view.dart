import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final subject = TextEditingController();
    final message = TextEditingController();
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ListView(
            children: [
              const ListTile(title: Text('Quick Help')),
              const ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('FAQ'),
              ),
              const ListTile(
                leading: Icon(Icons.book_outlined),
                title: Text('User Guide'),
              ),
              const ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('Safety Tips'),
              ),
              const Divider(),
              const ListTile(title: Text('Contact Us')),
              const ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('Email Support'),
                subtitle: Text('support@loveconnect.com'),
              ),
              const ListTile(
                leading: Icon(Icons.phone_outlined),
                title: Text('Phone Support'),
                subtitle: Text('(555) 123-4567'),
              ),
              const ListTile(
                leading: Icon(Icons.chat_outlined),
                title: Text('Live Chat'),
              ),
              const Divider(),
              const ListTile(title: Text('Submit a Support Ticket')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: subject,
                  decoration: const InputDecoration(hintText: 'Subject'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: message,
                  decoration: const InputDecoration(
                    hintText: 'What do you need help with?',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Submit'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
