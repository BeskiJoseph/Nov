import 'package:flutter/material.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../models/signup_data.dart';
import 'signup_profile.dart';

class SignupLocationScreen extends StatelessWidget {
  final SignupData data;
  SignupLocationScreen({super.key, required this.data});

  final locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InputField(hint: "City / Country", controller: locationController),
            const Spacer(),
            PrimaryButton(
              text: "Next",
              onTap: () {
                data.location = locationController.text;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupProfileScreen(data: data),
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
