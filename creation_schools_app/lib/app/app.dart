import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import 'auth_state.dart';
import '../router/app_router.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late AuthState _auth;
  @override
  void initState() {
    super.initState();
    _auth = AuthState();
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: Builder(
        builder: (ctx) {
          final router = createRouter(ctx);
          return MaterialApp.router(
            title: 'Creation Schools',
            debugShowCheckedModeBanner: false,
            theme: appTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
