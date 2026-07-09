import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/services/handle_sync.dart';
import 'package:komorebi/themes/theme.dart';

class SanboxNewUserPopup extends HookConsumerWidget {
  const SanboxNewUserPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = useState("");
    return AlertDialog(
      insetPadding: .zero,
      contentPadding: .all(8),
      titlePadding: .all(8),
      titleTextStyle: context.textTheme.headlineSmall?.copyWith(fontSize: 20),
      title: Text(S.of(context).createAReadonlySandboxAccount),
      content: SizedBox(
        width: 300,
        child: TextField(
          onChanged: (value) {
            userName.value = value;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.alternate_email_outlined),
            border: OutlineInputBorder(),
            hintText: S.of(context).enterUsername,
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: userName.value.trim().isEmpty
              ? null
              : () async {
                  final isSuccess = await doSandboxSignIn(
                    ref,
                    userName.value.trim(),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSuccess
                            ? S
                                  .of(context)
                                  .profileUsernamevalueLinkedSuccessfully(
                                    userName.value,
                                  )
                            : S
                                  .of(context)
                                  .unableToLinkProfileUsernamevalue(
                                    userName.value,
                                  ),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
          child: Text(S.of(context).yes),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(S.of(context).no),
        ),
      ],
    );
  }
}
