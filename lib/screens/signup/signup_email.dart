import 'package:flutter/material.dart';
import '../../models/signup_data.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';

import 'signup_username.dart';

class SignupEmailScreen extends StatelessWidget {
  final SignupData data;
  SignupEmailScreen({super.key, required this.data});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InputField(hint: "Email", controller: emailController),
            const SizedBox(height: 12),
            InputField(
              hint: "Password",
              controller: passwordController,
              obscure: true,
            ),
            const Spacer(),
            PrimaryButton(
              text: "Next",
              onTap: () {
                data.email = emailController.text;
                data.password = passwordController.text;
                debugPrint(
      "EMAIL: ${data.email}\n"
      "PASSWORD: ${data.password}\n"
      "LAT: ${data.latitude?.toStringAsFixed(6)}\n"
      "LNG: ${data.longitude?.toStringAsFixed(6)}"
    );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupUsernameScreen(data: data),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

