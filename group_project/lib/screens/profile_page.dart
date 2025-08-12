import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> _sendVerifyEmail(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile refreshed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut(); // authStateChanges() will route back to LoginPage
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body:
          user == null
              ? const Center(child: Text('No user signed in'))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(user.email ?? '(no email)'),
                    subtitle: const Text('Email'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(user.uid),
                    subtitle: const Text('UID'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(
                      user.emailVerified ? 'Verified' : 'Not verified',
                    ),
                    subtitle: const Text('Email status'),
                  ),
                  if (user.displayName != null && user.displayName!.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user.displayName!),
                      subtitle: const Text('Display name'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(
                      user.metadata.creationTime?.toLocal().toString() ?? '—',
                    ),
                    subtitle: const Text('Created'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.login_outlined),
                    title: Text(
                      user.metadata.lastSignInTime?.toLocal().toString() ?? '—',
                    ),
                    subtitle: const Text('Last sign-in'),
                  ),
                  const SizedBox(height: 12),
                  if (!user.emailVerified)
                    ElevatedButton.icon(
                      onPressed: () => _sendVerifyEmail(context),
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Send verification email'),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _refresh(context),
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
    );
  }
}
