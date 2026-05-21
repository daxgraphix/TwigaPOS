import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/utils/responsive.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../bloc/billing_bloc.dart';

class NewSalePage extends StatefulWidget {
  const NewSalePage({super.key});

  @override
  State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();
  String? _selectedProductId;
  List<Product> _availableProducts = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load products for selection dropdown
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _productNameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canAddToCart {
    final name = _productNameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    return (name.isNotEmpty || _selectedProductId != null) && price > 0 && qty > 0;
  }

  void _debouncedRebuild() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  void _addManualToCart() {
    final name = _productNameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    if ((name.isEmpty && _selectedProductId == null) || price <= 0 || qty <= 0) return;
    
    final productName = name.isNotEmpty ? name : 
        _availableProducts.firstWhere((p) => p.id == _selectedProductId, orElse: () => Product.empty()).name;
    
    final productPrice = _selectedProductId != null ? 
        _availableProducts.firstWhere((p) => p.id == _selectedProductId, orElse: () => Product.empty()).price : 
        price;
        
    final discountAmount = (productPrice * qty) * (discountPercent.clamp(0, 100) / 100);
    final discountedTotal = (productPrice * qty) - discountAmount;
    final effectiveUnitPrice = discountedTotal / qty;
    
    final manualProduct = Product(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: productName,
      barcode: '',
      price: effectiveUnitPrice,
      costPrice: effectiveUnitPrice,
      stock: 999,
      lastStockUpdate: DateTime.now(),
      category: 'Manual',
    );
    context
        .read<BillingBloc>()
        .add(AddProductToCartEvent(manualProduct, quantity: qty));
    setState(() {
      _productNameController.clear();
      _priceController.clear();
      _qtyController.text = '1';
      _discountController.text = '0';
      _notesController.clear();
      _selectedProductId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to cart'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _recordSale() {
    if (context.read<BillingBloc>().state.cartItems.isEmpty) return;
    context
        .read<BillingBloc>()
        .add(const CompleteSaleEvent(shiftId: 'default'));
  }

  void _proceedToCheckout() => context.push('/checkout');

  @override
  Widget build(BuildContext context) {
    final billingState = context.watch<BillingBloc>().state;
    final currency =
        HiveDatabase.settingsBox.get('selectedCurrency', defaultValue: 'TZS');
    final symbol = AppTheme.getCurrencySymbol(currency);
    final primary = AppTheme.primaryColor;
    final isSmallPhone = MediaQuery.of(context).size.width < 380;

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        if (productState.status == ProductStatus.loaded) {
          _availableProducts = productState.products;
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('New Sale'),
            actions: [
              if (billingState.cartItems.isNotEmpty)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: _proceedToCheckout,
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${billingState.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // ── Product Selection Card ────────────────────────────
                  Card(
                    elevation: Responsive.getCardElevation(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallPhone ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Selection',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          _availableProducts.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No products available. Please add products first.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Select Product',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: _selectedProductId,
                                  items: _availableProducts.map((product) {
                                    return DropdownMenuItem(
                                      value: product.id,
                                      child: Text('${product.name} - ${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${product.price.toStringAsFixed(2)}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedProductId = value;
                                      // Auto-fill price when product is selected
                                      final selectedProduct = _availableProducts.firstWhere((p) => p.id == value, orElse: () => Product.empty());
                                      _priceController.text = selectedProduct.price.toStringAsFixed(2);
                                    });
                                  },
                                ),
                          const SizedBox(height: 10),
                                  TextField(
                                   controller: _discountController,
                                   keyboardType: const TextInputType.numberWithOptions(
                                       decimal: true),
                                   decoration:
                                       const InputDecoration(labelText: 'Discount %'),
                                   onChanged: (_) => _debouncedRebuild(),
                                 ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Manual Product Entry Card ────────────────────────────
                  Card(
                    elevation: Responsive.getCardElevation(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallPhone ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manual Sale Entry',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _productNameController,
                            decoration:
                                const InputDecoration(labelText: 'Product Name'),
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _debouncedRebuild(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration:
                                      const InputDecoration(labelText: 'Price')
                                  ,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _qtyController,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Qty'),
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _discountController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration:
                                      const InputDecoration(labelText: 'Discount %'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                                  TextField(
                                   controller: _qtyController,
                                   keyboardType: TextInputType.number,
                                   decoration:
                                       const InputDecoration(labelText: 'Qty'),
                                   textInputAction: TextInputAction.done,
                                   onChanged: (_) => _debouncedRebuild(),
                                 ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _canAddToCart ? _addManualToCart : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                disabledBackgroundColor:
                                    primary.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Add to Cart'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Cart ─────────────────────────────────────────────────
                  if (billingState.cartItems.isNotEmpty)
                    Card(
                      elevation: Responsive.getCardElevation(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallPhone ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cart (${billingState.cartItems.length} item${billingState.cartItems.length == 1 ? '' : 's'})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: billingState.cartItems.length,
                              itemBuilder: (context, index) {
                                final item = billingState.cartItems[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(item.product.name),
                                  subtitle: Text(
                                    '$symbol${item.total.toStringAsFixed(2)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.remove, size: 18),
                                        onPressed: () => context
                                            .read<BillingBloc>()
                                            .add(
                                              UpdateQuantityEvent(
                                                item.product.id,
                                                item.quantity - 1,
                                              ),
                                            ),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () => context
                                            .read<BillingBloc>()
                                            .add(
                                              UpdateQuantityEvent(
                                                item.product.id,
                                                item.quantity + 1,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 18),
                                        onPressed: () => context
                                            .read<BillingBloc>()
                                            .add(
                                              RemoveProductFromCartEvent(
                                                item.product.id),
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total:',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '$symbol${billingState.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _proceedToCheckout,
                                    icon: const Icon(Icons.payment),
                                     label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Checkout')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _recordSale,
                                    icon: const Icon(Icons.check_circle),
                                     label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Record Sale')),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Invoice: proceed to checkout'),
                                        ),
                                      );
                                      _proceedToCheckout();
                                    },
                                    icon: const Icon(Icons.receipt),
                                     label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Invoice')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
