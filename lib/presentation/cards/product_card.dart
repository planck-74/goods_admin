import 'package:flutter/material.dart';
import 'package:goods_admin/data/models/order_model.dart';

class ProductCard extends StatelessWidget {
  final OrderProduct orderProduct;

  const ProductCard({super.key, required this.orderProduct});

  @override
  Widget build(BuildContext context) {
    final product = orderProduct.product;
    final quantity = orderProduct.controller;
    // Use offerPrice if available, otherwise fall back to price
    final subtotal = ((product.offerPrice ?? product.price) ?? 0) * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.shopping_bag),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.classification,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        // Show offerPrice if available, otherwise show price
                        '${(product.offerPrice ?? product.price)?.toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.offerPrice != null &&
                          product.price != product.offerPrice) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${product.price?.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('الكمية: $quantity', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '${subtotal.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
