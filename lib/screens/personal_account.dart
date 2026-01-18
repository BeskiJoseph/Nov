import 'package:flutter/material.dart';
import 'home_screen.dart';

class PersonalAccountScreen extends StatefulWidget {
  const PersonalAccountScreen({super.key});

  @override
  State<PersonalAccountScreen> createState() => _PersonalAccountScreenState();
}

class _PersonalAccountScreenState extends State<PersonalAccountScreen> {
  int _currentStep = 0;

  final usernameController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
          "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  void nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: nextStep,
        onStepCancel: prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 4 ? "Finish" : "Next"),
                ),
                const SizedBox(width: 12),
                if (_currentStep != 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text("Back"),
                  ),
              ],
            ),
          );
        },
        steps: [
          /// STEP 1 – BASIC INFO
          Step(
            title: const Text("Basic Info"),
            content: Column(
              children: [
                _field("Username", usernameController),
                _field("First Name", firstNameController),
                _field("Last Name", lastNameController),
              ],
            ),
          ),

          /// STEP 2 – DOB
          Step(
            title: const Text("Date of Birth"),
            content: TextField(
              controller: dobController,
              readOnly: true,
              onTap: pickDate,
              decoration: const InputDecoration(
                labelText: "Select Date of Birth",
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ),

          /// STEP 3 – LOCATION
          Step(
            title: const Text("Location"),
            content: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Location permission + auto-fill
                    locationController.text = "Auto-detected location";
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text("Use my current location"),
                ),
                const SizedBox(height: 10),
                _field("Or enter manually", locationController),
              ],
            ),
          ),

          /// STEP 4 – CONTACT
          Step(
            title: const Text("Contact Details"),
            content: Column(
              children: [
                _field("Email", emailController),
                _field("Phone Number", phoneController),
                const Text(
                  "Verification will be done later",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          /// STEP 5 – PROFILE (OPTIONAL)
          Step(
            title: const Text("Profile Setup"),
            content: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 40),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Image picker
                  },
                  child: const Text("Upload Profile Picture (Optional)"),
                ),
                _field("Bio (Optional)", bioController, maxLines: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
