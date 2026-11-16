import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/child_profile.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_button.dart';
import '../widgets/animal_avatar.dart';
import '../widgets/scenic_background.dart';

const _avatars = <(String, IconData)>[
  ('Lion', Icons.pets_rounded),
  ('Elephant', Icons.park_rounded),
  ('Monkey', Icons.emoji_nature_rounded),
  ('Crocodile', Icons.water_rounded),
  ('Tiger', Icons.pets_rounded),
  ('Fox', Icons.pets_rounded),
  ('Rabbit', Icons.cruelty_free_rounded),
  ('Panda', Icons.face_rounded),
  ('Owl', Icons.visibility_rounded),
];

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  int _step = 0;
  int _grade = 1;
  String _avatar = _avatars.first.$1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a player')),
      body: ScenicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Step ${_step + 1} of 3',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Profile setup, step ${_step + 1} of 3',
              child: LinearProgressIndicator(
                value: (_step + 1) / 3,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 24),
            if (_step == 0) ...[
              Text(
                "What's your name?",
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                maxLength: 18,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  helperText: 'This is how your name will appear in MathQuest.',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (_step == 1) ...[
              Text(
                'What grade are you in?',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (var grade = 1; grade <= 6; grade++)
                Semantics(
                  selected: _grade == grade,
                  label: 'Grade $grade${_grade == grade ? ', selected' : ''}',
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      minTileHeight: 52,
                      leading: Icon(
                        _grade == grade
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _grade == grade
                            ? AppColors.primaryDark
                            : AppColors.darkGrey,
                      ),
                      title: Text('Grade $grade'),
                      onTap: () => setState(() => _grade = grade),
                    ),
                  ),
                ),
            ] else ...[
              Text(
                'Pick Your Partner!',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _avatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final selected = avatar.$1 == _avatar;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${avatar.$1} avatar',
                    child: Material(
                      color: selected
                          ? const Color(0xFFDDF7E6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => setState(() => _avatar = avatar.$1),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryDark
                                  : AppColors.lightGrey,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimalAvatar(name: avatar.$1, size: 40),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  avatar.$1,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            QuestButton(
              label: _step < 2 ? 'Next' : "Let's Go!",
              onPressed: () async {
                if (_step == 0 && _name.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Choose a nickname first.')),
                  );
                  return;
                }
                if (_step < 2) {
                  setState(() => _step++);
                  return;
                }
                final name = _name.text.trim();
                await ref
                    .read(progressProvider.notifier)
                    .addProfile(
                      ChildProfile(name: name, grade: _grade, avatar: _avatar),
                    );
                if (context.mounted) context.go('/ready');
              },
            ),
            if (_step > 0)
              TextButton(
                onPressed: () => setState(() => _step--),
                child: const Text('Back'),
              ),
          ],
        ),
      ),
    );
  }
}

class ReadyScreen extends ConsumerWidget {
  const ReadyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final index = progress.currentProfile;
    final profile = index == null ? null : progress.profiles[index];
    final course = profile?.startingCourse ?? 1;
    final courseTheme = CourseTheme.forCourse(course);
    final avatar = _avatars.firstWhere(
      (option) => option.$1 == profile?.avatar,
      orElse: () => _avatars.first,
    );
    return Scaffold(
      body: ScenicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  size: 72,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 16),
                Text(
                  "You're ready${profile == null ? '' : ', ${profile.name}'}!",
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AnimalAvatar(name: avatar.$1, size: 64),
                        const SizedBox(height: 8),
                        Text(
                          'Based on your grade, we’ll start you in:',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${courseTheme.title.toUpperCase()} · COURSE $course',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                QuestButton(
                  label: 'Start My Quest',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSelectorScreen extends ConsumerWidget {
  const ProfileSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(progressProvider).profiles;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Who's Playing?"),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: profiles.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create a player profile to begin your quest.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  QuestButton(
                    label: 'Create player',
                    onPressed: () => context.go('/profile-setup'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var index = 0; index < profiles.length; index++)
                  Card(
                    child: ListTile(
                      minTileHeight: 76,
                      leading: AnimalAvatar(
                        name: profiles[index].avatar,
                        size: 48,
                      ),
                      title: Text(
                        profiles[index].name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('Grade ${profiles[index].grade}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await ref
                            .read(progressProvider.notifier)
                            .selectProfile(index);
                        if (context.mounted) context.go('/home');
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/profile-setup'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add another player'),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Parent Area'),
                    subtitle: const Text('Parent check required'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings'),
                  ),
                ),
              ],
            ),
    );
  }
}
