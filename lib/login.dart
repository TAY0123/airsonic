import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/animatedwave.dart';
import 'package:airsonic/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'const.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final mp = MediaPlayer.instance;

  bool login = true;

  var domain = "";
  var username = "";
  var password = "";

  var passwordo = true;

  String? errorMsg;

  var formkey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    () async {
      if ((await SharedPreferences.getInstance()).getBool("login") ?? false) {
        Navigator.of(context).popAndPushNamed("/album");
      }
    }();
  }

  void loginAction() async {
    if (!formkey.currentState!.validate()) return;
    setState(() {
      login = false;
    });
    var success = false;
    try {
      final result = await mp.login(
          domain: domain, username: username, password: password);
      success = result.status;
    } catch (e) {
      setState(() {
        errorMsg = "Error: ${e.toString()}";
        login = true;
      });
    }

    if (success) {
      (await SharedPreferences.getInstance()).setBool("login", true);
      Navigator.of(context).popAndPushNamed("/album");
      //login failed
    } else {
      setState(() {
        errorMsg = "Error: login credentials error";
        login = true;
      });
      //(await SharedPreferences.getInstance()).setBool("login", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        //loginpage

        var p = Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    Spacer(),
                    Form(
                      key: formkey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Theme.of(context).colorScheme.primary,
                              child: const Icon(
                                Icons.music_note,
                                size: 48,
                              ),
                            ),
                          ),
                          Text(
                            "Welcome to Flutsonic",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (errorMsg != null)
                            Text(
                              errorMsg!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.red),
                            ),
                          TextFormField(
                            enabled: login,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Server',
                            ),
                            onChanged: (value) => domain = value,
                            validator: (url) {
                              try {
                                final test = Uri.parse(url ?? "").isAbsolute;
                                if (!test) {
                                  return "Please enter a valid url";
                                }
                              } catch (e) {
                                return "Please enter a valid url";
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            enabled: login,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Username',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please input username";
                              }
                              return null;
                            },
                            onChanged: (value) => username = value,
                          ),
                          TextFormField(
                            enabled: login,
                            obscureText: passwordo,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      passwordo = !passwordo;
                                    });
                                  },
                                  icon: Icon(passwordo
                                      ? Icons.visibility
                                      : Icons.visibility_off)),
                              border: OutlineInputBorder(),
                              labelText: 'Password',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please input password";
                              }
                              return null;
                            },
                            onChanged: (value) => password = value,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: login
                                          ? ElevatedButton.icon(
                                              icon: const Icon(Icons.login),
                                              onPressed: loginAction,
                                              label: const Text("Login"))
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                    ),
                                  ],
                                )),
                          )
                        ].map((e) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: e,
                          );
                        }).toList(),
                      ),
                    ),
                    Spacer()
                  ],
                ),
              ),
            ),
          ),
        );

        if (constraints.maxWidth > breakpointM) {
          //tablet mode
          return Scaffold(
            body: Row(
              children: [
                Expanded(child: p),
                Expanded(
                    child: Container(
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AnimatedWave(
                            height: constraints.maxHeight / 4,
                            speed: 0.3,
                            color: Theme.of(context).primaryColor,
                          ),
                          AnimatedWave(
                              height: constraints.maxHeight / 4,
                              speed: 0.2,
                              color: Theme.of(context).colorScheme.surface),
                          AnimatedWave(
                              height: constraints.maxHeight / 4,
                              speed: 0.4,
                              color: Theme.of(context).primaryColorLight),
                        ],
                      ),
                    ],
                  ),
                ))
              ],
            ),
          );
        } else {
          return Scaffold(
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                p,
                AnimatedWave(
                  height: constraints.maxHeight / 4,
                  speed: 0.3,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                AnimatedWave(
                    height: constraints.maxHeight / 4,
                    speed: 0.2,
                    color: Theme.of(context).colorScheme.inverseSurface),
                AnimatedWave(
                    height: constraints.maxHeight / 4,
                    speed: 0.4,
                    color: Theme.of(context).primaryColorLight),
              ],
            ),
          );
        }
      },
    );
  }
}
