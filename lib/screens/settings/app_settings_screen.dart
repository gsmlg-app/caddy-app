import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:caddy_app/destination.dart';
import 'package:caddy_app/screens/settings/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_bloc/theme_bloc.dart';

class AppSettingsScreen extends StatelessWidget {
  static const name = 'App Settings';
  static const path = 'app';
  static const fullPath = '${SettingsScreen.path}/$name';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(SettingsScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        final sharedPrefs = context.read<SharedPreferences>();
        final appName = sharedPrefs.getString('APP_NAME');

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(context.l10n.settingsTitle)),
              SliverFillRemaining(
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return SettingsList(
                      sections: [
                        SettingsSection(
                          title: Text(context.l10n.appNameLabel),
                          tiles: <SettingsTile>[
                            SettingsTile(
                              leading: const Icon(Icons.api),
                              title: Center(
                                child: Text(
                                  context.l10n.appNameLabel,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              trailing: appName == null
                                  ? Text(context.l10n.notAvailable)
                                  : Text(appName),
                              onPressed: (context) {
                                showAppDialog(
                                  context: context,
                                  title: Text(context.l10n.appName),
                                  content: Text(context.l10n.welcomeHome),
                                  actions: [
                                    AppDialogAction(
                                      onPressed: (context) {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(context.l10n.ok),
                                    ),
                                    AppDialogAction(
                                      onPressed: (context) {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(context.l10n.cancel),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}
