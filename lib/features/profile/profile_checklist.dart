import 'package:flutter/material.dart';

class ProfileChecklist extends StatelessWidget {
  const ProfileChecklist({
    super.key,
    required this.hasPhoto,
    required this.hasBio,
    required this.hasSkills,
    required this.onPhoto,
    required this.onBio,
    required this.onSkills,
  });
  final bool hasPhoto, hasBio, hasSkills;
  final VoidCallback onPhoto, onBio, onSkills;
  @override
  Widget build(BuildContext context) {
    final completed = [
      hasPhoto,
      hasBio,
      hasSkills,
    ].where((done) => done).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help people get to know you',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text('$completed of 3 optional details added'),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completed / 3,
            semanticsLabel: 'Optional profile details: $completed of 3 added',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final item in [
                ('Profile photo', hasPhoto, onPhoto),
                ('Short bio', hasBio, onBio),
                ('Skills & interests', hasSkills, onSkills),
              ])
                TextButton.icon(
                  onPressed: item.$3,
                  icon: Icon(
                    item.$2
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(item.$1),
                ),
            ],
          ),
          const Text(
            'Add what you’re comfortable sharing. Save your bio and skills below; photo changes save immediately.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
