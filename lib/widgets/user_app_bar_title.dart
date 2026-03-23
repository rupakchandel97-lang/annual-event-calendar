import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class UserAppBarTitle extends StatelessWidget {
  final String title;

  const UserAppBarTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final displayName = authProvider.currentUser?.displayName.trim();
        final hasDisplayName = displayName != null && displayName.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            if (hasDisplayName)
              Text(
                'Logged in: $displayName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .appBarTheme
                          .foregroundColor
                          ?.withOpacity(0.85),
                    ),
              ),
          ],
        );
      },
    );
  }
}
