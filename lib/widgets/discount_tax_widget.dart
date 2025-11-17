import 'package:flutter/material.dart';

class DiscountTaxWidget extends StatelessWidget {
  final TextEditingController discountPercentController;
  final TextEditingController discountAmountController;
  final bool isEditingPercent;
  final Function(bool) onModeChange;
  final double subtotal;

  final String? selectedTaxRate;
  final String selectedTaxType;
  final List<String> taxRateOptions;
  final Function(String?) onTaxRateChanged;

  final double taxAmount;
  final double parsedTaxRate;

  const DiscountTaxWidget({
    super.key,
    required this.discountPercentController,
    required this.discountAmountController,
    required this.isEditingPercent,
    required this.onModeChange,
    required this.subtotal,
    required this.selectedTaxRate,
    required this.selectedTaxType,
    required this.taxRateOptions,
    required this.onTaxRateChanged,
    required this.taxAmount,
    required this.parsedTaxRate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _summaryRow("Subtotal", subtotal),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _textField(
                controller: discountPercentController,
                label: "Discount %",
                suffix: "%",
                onTap: () => onModeChange(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: discountAmountController,
                label: "Discount ₹",
                prefix: "₹ ",
                onTap: () => onModeChange(false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        IgnorePointer(
          ignoring: selectedTaxType != 'With Tax',
          child: Opacity(
            opacity: selectedTaxType == 'With Tax' ? 1 : 0.4,
            child: DropdownButtonFormField<String>(
              value: selectedTaxRate,
              decoration: const InputDecoration(
                labelText: "Select Tax Rate",
                border: OutlineInputBorder(),
              ),
              items:
                  taxRateOptions
                      .map(
                        (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                      )
                      .toList(),
              onChanged: onTaxRateChanged,
            ),
          ),
        ),

        if (selectedTaxType == 'With Tax' && parsedTaxRate > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  "Tax Rate",
                  "${parsedTaxRate.toStringAsFixed(2)}%",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  "Tax Amount",
                  "₹ ${taxAmount.toStringAsFixed(2)}",
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Text(
          "₹ ${value.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
