import 'package:flutter/material.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'screens/sepay_checkout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Product> _products = sampleProducts;

  int get _cartItemCount => _products.fold(0, (sum, p) => sum + p.quantity);
  int get _cartTotal => _products.fold(0, (sum, p) => sum + p.total);

  void _updateQuantity(Product product, int delta) {
    setState(() {
      product.quantity = (product.quantity + delta).clamp(0, 99);
    });
  }

  void _goToCheckout() {
    final cartItems = _products.where((p) => p.quantity > 0).toList();
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SepayCheckoutScreen(
          cartItems: cartItems,
          total: _cartTotal,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Payment App',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_cartItemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: _goToCheckout,
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF0099FF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Chọn sản phẩm & Thanh toán',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hỗ trợ VNPay, MoMo & SePay QR',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Text('🛒', style: TextStyle(fontSize: 36)),
                ],
              ),
            ),
          ),

          // Products list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: _products[index],
                  onIncrement: () => _updateQuantity(_products[index], 1),
                  onDecrement: () => _updateQuantity(_products[index], -1),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: _cartItemCount > 0
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_cartItemCount món',
                          style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 12),
                        ),
                        Text(
                          _formatCurrency(_cartTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _goToCheckout,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đặt hàng',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
