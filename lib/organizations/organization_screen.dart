import 'package:flutter/material.dart';
import '../models/organization.dart';

class OrganizationScreen extends StatelessWidget {
  final List<Organization> organizations;

  const OrganizationScreen({Key? key, required this.organizations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
      ),
      body: ListView.builder(
        itemCount: organizations.length,
        itemBuilder: (context, index) {
          final organization = organizations[index];
          return ListTile(
            title: Text(organization.name),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add organization screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
