import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/vanity_provider.dart';
import 'widgets/barcode_scanner_view.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialBarcode;

  const AddProductScreen({super.key, this.initialBarcode});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _barcodeController = TextEditingController();
  final _brandController = TextEditingController();
  final _nameController = TextEditingController();
  final _volumeController = TextEditingController();
  final _priceController = TextEditingController();
  final _paoController = TextEditingController(text: '12');

  String _selectedCategory = 'serum';
  String? _imageUrl;
  bool _openedToday = true;
  bool _isLookingUp = false;
  String? _lookupNotice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _nameController.dispose();
    _volumeController.dispose();
    _priceController.dispose();
    _paoController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? newCategoryId) {
    if (newCategoryId == null) return;
    setState(() {
      _selectedCategory = newCategoryId;
      final cat = CategoryModel.findById(newCategoryId);
      _paoController.text = cat.defaultPaoMonths.toString();
    });
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    setState(() {
      _isLookingUp = true;
      _barcodeController.text = barcode;
    });

    final provider = context.read<VanityProvider>();
    final product = await provider.lookupBarcode(barcode);

    if (!mounted) return;

    setState(() {
      _isLookingUp = false;
    });

    if (product != null) {
      setState(() {
        _brandController.text = product.brand;
        _nameController.text = product.name;
        _selectedCategory = product.categoryId;
        _paoController.text = product.paoMonths.toString();
        _volumeController.text = product.volume ?? '';
        _imageUrl = product.imageUrl;
        _lookupNotice = '✨ Found on Open Beauty Facts!';
      });
      _tabController.animateTo(1);
    } else {
      setState(() {
        _lookupNotice = 'ℹ️ Barcode not in database. Enter details manually.';
      });
      _tabController.animateTo(1);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VanityProvider>();
    final pao = int.tryParse(_paoController.text) ?? 12;
    final price = double.tryParse(_priceController.text);

    try {
      await provider.addProduct(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        categoryId: _selectedCategory,
        paoMonths: pao,
        barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
        volume: _volumeController.text.trim().isNotEmpty ? _volumeController.text.trim() : null,
        imageUrl: _imageUrl,
        price: price,
        openedToday: _openedToday,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} added to your vanity!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add to Vanity',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan Barcode'),
            Tab(icon: Icon(Icons.edit_document), text: 'Manual Entry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Barcode Scanner
          Stack(
            children: [
              BarcodeScannerView(
                onBarcodeScanned: _handleBarcodeScanned,
                onManualEntryRequested: () => _tabController.animateTo(1),
              ),
              if (_isLookingUp)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Searching Open Beauty Facts...',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Tab 2: Manual Entry Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_lookupNotice != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lookupNotice!.contains('Found')
                            ? AppColors.statusGreenBg
                            : AppColors.statusAmberBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _lookupNotice!.contains('Found')
                              ? AppColors.statusGreenBorder
                              : AppColors.statusAmberBorder,
                        ),
                      ),
                      child: Text(
                        _lookupNotice!,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _lookupNotice!.contains('Found')
                              ? AppColors.statusGreen
                              : AppColors.statusAmber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Brand Input
                  TextFormField(
                    controller: _brandController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Brand *',
                      hintText: 'e.g. CeraVe, The Ordinary, Glossier',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Please enter the brand name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Product Name Input
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g. Moisturizing Cream, Niacinamide Serum',
                      prefixIcon: Icon(Icons.spa_outlined),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Please enter the product name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: CategoryModel.defaultCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.categoryId,
                        child: Text('${cat.categoryName} (${cat.defaultPaoMonths}M PAO)'),
                      );
                    }).toList(),
                    onChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: 16),

                  // PAO Months & Volume Row
                  Row(
                    children: [
                      // PAO (Period After Opening)
                      Expanded(
                        child: TextFormField(
                          controller: _paoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'PAO (Months) *',
                            hintText: 'e.g. 12',
                            prefixIcon: Icon(Icons.timelapse_outlined),
                            suffixText: 'mo',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final num = int.tryParse(val);
                            if (num == null || num <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Volume
                      Expanded(
                        child: TextFormField(
                          controller: _volumeController,
                          decoration: const InputDecoration(
                            labelText: 'Volume / Size',
                            hintText: 'e.g. 50ml / 1.7oz',
                            prefixIcon: Icon(Icons.straighten_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Optional Price & Barcode Row
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price (Optional)',
                            hintText: 'e.g. 24.50',
                            prefixIcon: Icon(Icons.attach_money_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Barcode
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            hintText: 'Optional',
                            prefixIcon: Icon(Icons.qr_code_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Opened Today Toggle Switch Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on, color: AppColors.secondary, size: 22),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Opened Today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Start PAO expiration countdown today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _openedToday,
                          activeColor: AppColors.secondary,
                          onChanged: (val) => setState(() => _openedToday = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Add to My Vanity'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
