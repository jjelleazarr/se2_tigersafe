import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class ReportLoggingScreen extends StatelessWidget {
  const ReportLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isNarrow = constraints.maxWidth < 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Please fill out the form",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        isNarrow
                            ? Column(children: _buildStackedForm())
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildSideBySideForm(),
                              ),
                        const SizedBox(height: 32),
                        isNarrow
                            ? Center(child: _buildButtons())
                            : Align(
                                alignment: Alignment.centerRight,
                                child: _buildButtons(),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Report ',
              style: TextStyle(
                color: Color(0xFFFEC00F),
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            TextSpan(
              text: 'Logging',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStackedForm() {
    return [
      _buildInputField("Name"),
      const SizedBox(height: 16),
      _buildInputField("Date and Time"),
      const SizedBox(height: 16),
      _buildInputField("Location", hint: "e.g. Room 203, Main Building"),
      const SizedBox(height: 16),
      _buildInputField("Status of the Incident"),
      const SizedBox(height: 16),
      _buildInputField("Resolved By"),
      const SizedBox(height: 24),
      _buildDescriptionField(),
      const SizedBox(height: 24),
      _buildFileUpload(),
    ];
  }

  List<Widget> _buildSideBySideForm() {
    return [
      Expanded(
        child: Column(
          children: [
            _buildInputField("Name"),
            const SizedBox(height: 16),
            _buildInputField("Date and Time"),
            const SizedBox(height: 16),
            _buildInputField("Location", hint: "e.g. Room 203, Main Building"),
            const SizedBox(height: 16),
            _buildInputField("Status of the Incident"),
            const SizedBox(height: 16),
            _buildInputField("Resolved By"),
          ],
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildFileUpload(),
          ],
        ),
      ),
    ];
  }

  Widget _buildInputField(String label, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextFormField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Description of the Incident",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "What happened, who was involved...",
          ),
        ),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload your file:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 32, color: Colors.grey),
                Text(
                  "Drag & Drop",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                Text(
                  "or browse",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          icon: const Icon(Icons.save, color: Colors.blue),
          label: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Save ",
                  style: TextStyle(
                    color: Color(0xFFFEC00F), // Yellow
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: "Report",
                  style: TextStyle(
                    color: Colors.white, // White
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
          label: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Save ",
                  style: TextStyle(
                    color: Color(0xFFFEC00F), // Yellow
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: "and Export",
                  style: TextStyle(
                    color: Colors.white, // White
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
