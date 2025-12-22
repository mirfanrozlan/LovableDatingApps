import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../widgets/common/text_input.dart';
import '../../themes/theme.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController(text: 'Your Name');
    final location = TextEditingController(text: 'New York, USA');
    final occupation = TextEditingController(text: 'Software Engineer');
    final bio = TextEditingController(
      text: 'Love to travel, read, books, and meet new people.',
    );
    final interests = TextEditingController(
      text: 'Travel, Reading, Coffee, Hiking, Photography',
    );
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
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: const [
                  CircleAvatar(radius: 28, child: Text('YN')),
                  SizedBox(width: 12),
                  Text('Tap to change profile photo'),
                ],
              ),
              const SizedBox(height: 16),
              TextInput(controller: name, hint: 'Name'),
              const SizedBox(height: 12),
              TextInput(controller: location, hint: 'Location'),
              const SizedBox(height: 12),
              TextInput(controller: occupation, hint: 'Occupation'),
              const SizedBox(height: 12),
              TextInput(controller: bio, hint: 'Bio'),
              const SizedBox(height: 12),
              TextInput(controller: interests, hint: 'Interests'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
