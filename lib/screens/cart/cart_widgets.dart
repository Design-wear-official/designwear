// The cart and checkout pieces, drawn after the "cart and checkout" design:
// rounded cards on a dark page, gold actions, a summary card with a pill button.
import 'package:flutter/material.dart';

import '../../models/commerce.dart';
import '../../theme/app_theme.dart';
import '../catalog/product_image.dart';
import '../home/home_screen.dart' show formatPrice;

/// The surfaces of the cart pages, for the current theme.
class CartPalette {
  const CartPalette._({
    required this.item,
    required this.itemBorder,
    required this.panel,
    required this.panelBorder,
    required this.summary,
    required this.rule,
  });

  /// A cart line, a panel (address, payment), the summary card, and the lines
  /// between rows.
  final Color item, itemBorder, panel, panelBorder, summary, rule;

  static const _dark = CartPalette._(
    item: Color(0xFF18181E),
    itemBorder: Color(0xFF393943),
    panel: Color(0xFF24242E),
    panelBorder: Color(0xFF555561),
    summary: Color(0xFF252530),
    rule: Color(0xFF7C7B84),
  );
  static const _light = CartPalette._(
    item: Colors.white,
    itemBorder: Color(0xFFDDDBD5),
    panel: Color(0xFFF7F5F0),
    panelBorder: Color(0xFFD0CEC6),
    summary: Color(0xFFF2F0EA),
    rule: Color(0xFFB5B3AB),
  );

  static CartPalette of(BuildContext context) =>
      context.isDark ? _dark : _light;
}

/// "−  2  +" with gold ring buttons.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  Widget _ring(
    BuildContext context,
    IconData icon,
    String tip,
    VoidCallback onTap,
  ) {
    final gold = context.accent;
    return Tooltip(
      message: tip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 2),
          ),
          child: Icon(icon, size: 16, color: gold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _ring(context, Icons.remove, 'Decrease', onMinus),
      SizedBox(
        width: 36,
        child: Text(
          '$quantity',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      _ring(context, Icons.add, 'Increase', onPlus),
    ],
  );
}

/// One cart line: picture, title, size, price, quantity.
class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.line, required this.onQuantity});
  final CartLine line;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final p = CartPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final size = narrow ? 84.0 : 118.0;
    return Container(
      padding: EdgeInsets.all(narrow ? 12 : 18),
      decoration: BoxDecoration(
        color: p.item,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.itemBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductImage(url: line.imageUrl),
            ),
          ),
          SizedBox(width: narrow ? 12 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Size ${line.size}',
                  style: TextStyle(color: context.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  formatPrice(line.total),
                  style: TextStyle(
                    color: context.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          QuantityStepper(
            quantity: line.quantity,
            onMinus: () => onQuantity(line.quantity - 1),
            onPlus: () => onQuantity(line.quantity + 1),
          ),
        ],
      ),
    );
  }
}

/// Subtotal, GST and total with the main action as a full-width pill.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.actionLabel,
    required this.onAction,
    this.notes = const [],
  });
  final double subtotal;
  final double tax;
  final double total;
  final String actionLabel;

  /// Null disables the button.
  final VoidCallback? onAction;

  /// Messages shown above the button (errors, delivery warnings).
  final List<Widget> notes;

  Widget _row(String label, String value, {bool big = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: big ? 16 : 14,
            fontWeight: big ? FontWeight.w800 : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 16 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = CartPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: p.summary,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Subtotal', formatPrice(subtotal)),
          _row('GST (18%)', formatPrice(tax)),
          Divider(color: p.rule, thickness: 2, height: 28),
          _row('Total', formatPrice(total), big: true),
          const SizedBox(height: 6),
          ...notes,
          SizedBox(
            height: 46,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

/// A rounded pill row (delivery address, payment): icon, text, chevron.
class PillRow extends StatelessWidget {
  const PillRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = CartPalette.of(context);
    return Material(
      color: p.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(subtitle == null ? 25 : 22),
        side: BorderSide(color: p.panelBorder),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.arrow_forward, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Cash on delivery" / "Pay online" with gold radio buttons.
class PaymentChoices extends StatelessWidget {
  const PaymentChoices({
    super.key,
    required this.online,
    required this.onChanged,
  });
  final bool online;
  final ValueChanged<bool> onChanged;

  Widget _option(
    BuildContext context,
    bool value,
    String title,
    String subtitle,
  ) {
    final selected = online == value;
    final gold = context.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? gold : context.muted,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: context.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = CartPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: p.panelBorder),
      ),
      child: Column(
        children: [
          _option(
            context,
            false,
            'Cash on delivery',
            'Pay when your order arrives',
          ),
          _option(
            context,
            true,
            'Pay online',
            'UPI, cards, netbanking, wallets',
          ),
        ],
      ),
    );
  }
}

/// A line of the order being placed: "T-shirt ×2 / Size XL ... price".
class OrderLineRow extends StatelessWidget {
  const OrderLineRow({super.key, required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${line.title}  ×${line.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Size ${line.size}',
                style: TextStyle(fontSize: 12, color: context.muted),
              ),
            ],
          ),
        ),
        Text(
          formatPrice(line.total),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
