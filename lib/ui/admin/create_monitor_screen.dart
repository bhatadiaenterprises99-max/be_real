import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'controller/create_monitor_controller.dart';

class CreateMonitorScreen extends StatelessWidget {
  const CreateMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return GetBuilder<CreateMonitorController>(
      init: CreateMonitorController(),
      builder: (controller) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 800 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Monitor Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add new field monitor credentials to the system',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Personal Information Section
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Full Name field
                                TextFormField(
                                  controller: controller.fullNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Full name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Username field with availability check
                                Obx(
                                  () => TextFormField(
                                    controller: controller.usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.account_circle,
                                      ),
                                      suffixIcon:
                                          controller.checkingUsername.value
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : controller.usernameAvailable.value
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          : controller
                                                .usernameController
                                                .text
                                                .isNotEmpty
                                          ? const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            )
                                          : null,
                                      helperText: 'Username must be unique',
                                    ),
                                    validator: controller.validateUsername,
                                    onChanged: (val) =>
                                        controller.checkUsername(),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email and Mobile in a row for wide screens
                                isWide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: _buildEmailField(controller),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildMobileField(
                                              controller,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildEmailField(controller),
                                          const SizedBox(height: 16),
                                          _buildMobileField(controller),
                                        ],
                                      ),
                                const SizedBox(height: 24),

                                // Account Security Section
                                const Text(
                                  'Account Security',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password field with toggle visibility
                                Obx(
                                  () => TextFormField(
                                    controller: controller.passwordController,
                                    obscureText:
                                        !controller.passwordVisible.value,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.passwordVisible.value
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed:
                                            controller.togglePasswordVisibility,
                                      ),
                                    ),
                                    validator: controller.validatePassword,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password field
                                Obx(
                                  () => TextFormField(
                                    controller:
                                        controller.confirmPasswordController,
                                    obscureText:
                                        !controller.passwordVisible.value,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                    ),
                                    validator:
                                        controller.validateConfirmPassword,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Site Assignment Section
                                const Text(
                                  'Site Assignment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Optional: Assign sites to this monitor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Company selection dropdown
                                Obx(() {
                                  if (controller.loadingCompanies.value) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  return DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Select Company',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.business),
                                    ),
                                    value:
                                        controller
                                            .selectedCompanyId
                                            .value
                                            .isEmpty
                                        ? null
                                        : controller.selectedCompanyId.value,
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('-- Select a Company --'),
                                      ),
                                      ...controller.companies.map(
                                        (company) => DropdownMenuItem(
                                          value: company['id'],
                                          child: Text(company['name']),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      controller.selectCompany(value ?? '');
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),

                                // Sites from selected company
                                Obx(() {
                                  if (controller
                                      .selectedCompanyId
                                      .value
                                      .isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  if (controller.loadingSitesForCompany.value) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (controller.companySites.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'No sites found for selected company',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  }

                                  return FormField<List<String>>(
                                    initialValue: controller.selectedSiteIds,
                                    validator: (value) =>
                                        null, // Site assignment is optional
                                    builder: (formState) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child:
                                                MultiSelectDialogField<String>(
                                                  title: const Text(
                                                    "Select Sites to Assign",
                                                  ),
                                                  items: controller.companySites
                                                      .map(
                                                        (site) =>
                                                            MultiSelectItem(
                                                              site.id!,
                                                              site.location,
                                                            ),
                                                      )
                                                      .toList(),
                                                  selectedColor: Colors.blue,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  buttonIcon: const Icon(
                                                    Icons.arrow_drop_down,
                                                  ),
                                                  buttonText: const Text(
                                                    "Select Sites",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  onConfirm: (values) {
                                                    controller
                                                            .selectedSiteIds
                                                            .value =
                                                        values;
                                                    formState.didChange(values);
                                                  },
                                                  initialValue: controller
                                                      .selectedSiteIds,
                                                ),
                                          ),
                                          if (controller
                                              .selectedSiteIds
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Wrap(
                                                spacing: 8,
                                                children: controller
                                                    .selectedSiteIds
                                                    .map((siteId) {
                                                      final site = controller
                                                          .companySites
                                                          .firstWhereOrNull(
                                                            (s) =>
                                                                s.id == siteId,
                                                          );
                                                      final siteName =
                                                          site?.location ??
                                                          'Unknown Site';

                                                      return Chip(
                                                        label: Text(siteName),
                                                        onDeleted: () {
                                                          controller
                                                              .selectedSiteIds
                                                              .remove(siteId);
                                                          controller
                                                              .selectedSiteIds
                                                              .refresh();
                                                          formState.didChange(
                                                            controller
                                                                .selectedSiteIds,
                                                          );
                                                        },
                                                      );
                                                    })
                                                    .toList(),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                }),

                                const SizedBox(height: 32),

                                // Submit Button
                                Obx(
                                  () => ElevatedButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : () => controller.submitMonitorData(),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: controller.isLoading.value
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Create Monitor Account',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailField(CreateMonitorController controller) {
    return TextFormField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.email),
      ),
      validator: controller.validateEmail,
    );
  }

  Widget _buildMobileField(CreateMonitorController controller) {
    return TextFormField(
      controller: controller.mobileController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.phone_android),
      ),
      validator: controller.validateMobile,
    );
  }
}
