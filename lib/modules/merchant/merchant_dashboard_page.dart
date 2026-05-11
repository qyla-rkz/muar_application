import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/merchant_home_view.dart';
import '../../theme/app_theme.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  int _currentIndex = 0;

  // Controllers
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productDetailsController = TextEditingController();
  final _voucherCodeController = TextEditingController();
  final _voucherDiscountController = TextEditingController();
  String _selectedCategory = 'Makanan & Minuman';
  bool _isLoading = false;
  File? _productImageFile;
  DateTime? _voucherExpiryDate;
  String? _selectedNearbyPlaceId;
  String? _selectedNearbyPlaceName;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  void _loadShopData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _shopNameController.text = data['shopName'] ?? '';
            _descriptionController.text = data['description'] ?? '';
            _selectedCategory = data['category'] ?? 'Makanan & Minuman';
            // Simple mapping for legacy data
            if (_selectedCategory == 'Food & Beverage') {
              _selectedCategory = 'Makanan & Minuman';
            }
            _selectedNearbyPlaceId = data['nearbyPlaceId'];
            _selectedNearbyPlaceName = data['nearbyPlaceName'];
          });
        }
      }
    } catch (_) {}
  }

  // --- ACTIONS ---

  void _saveShopProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('shops').doc(user.uid).set({
        'shopName': _shopNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'nearbyPlaceId': _selectedNearbyPlaceId,
        'nearbyPlaceName': _selectedNearbyPlaceName,
        'merchantId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'approved',
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profil kedai berjaya disimpan!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ralat: $e"), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  void _addProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_productNameController.text.isEmpty ||
        _productPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sila pilih tarikh tamat baucar")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_productImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_productImageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('products').add({
        'merchantId': user.uid,
        'name': _productNameController.text.trim(),
        'price': double.parse(_productPriceController.text.trim()),
        'details': _productDetailsController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _productNameController.clear();
      _productPriceController.clear();
      _productDetailsController.clear();
      setState(() => _productImageFile = null);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ralat menambah produk: $e")));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickProductImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _productImageFile = File(pickedFile.path));
    }
  }

  void _addVoucher() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_voucherCodeController.text.isEmpty ||
        _voucherDiscountController.text.isEmpty ||
        _voucherExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Sila isi semua ruangan baucar dan tarikh tamat")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('vouchers').add({
        'merchantId': user.uid,
        'code': _voucherCodeController.text.trim().toUpperCase(),
        'discount': _voucherDiscountController.text.trim(),
        'expiryDate': Timestamp.fromDate(_voucherExpiryDate!),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _voucherCodeController.clear();
      _voucherDiscountController.clear();
      setState(() => _voucherExpiryDate = null);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ralat menambah baucar: $e")));
      }
    }
  }

  Future<void> _pickVoucherExpiry() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() => _voucherExpiryDate = pickedDate);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate to initial route and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat log keluar: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Akaun'),
        content: const Text(
          'Adakah anda pasti mahu memadamkan akaun anda? Ini akan memadamkan secara KEKAL:\n\n'
          '• Profil Kedai Anda\n'
          '• Semua Produk dan Baucar\n'
          '• Profil dan Akaun Pengguna Anda\n\n'
          'Tindakan ini tidak boleh dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Padam Selamanya',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // 1. Delete Shop Profile
      await firestore.collection('shops').doc(uid).delete();

      // 2. Delete Merchant's Products
      final products = await firestore
          .collection('products')
          .where('merchantId', isEqualTo: uid)
          .get();
      for (var p in products.docs) {
        await p.reference.delete();
      }

      // 3. Delete Merchant's Created Vouchers
      final createdVouchers = await firestore
          .collection('vouchers')
          .where('merchantId', isEqualTo: uid)
          .get();
      for (var v in createdVouchers.docs) {
        await v.reference.delete();
      }

      // 4. Delete Community Posts and their comments
      final posts = await firestore
          .collection('community_posts')
          .where('userId', isEqualTo: uid)
          .get();
      for (var post in posts.docs) {
        final comments = await post.reference.collection('comments').get();
        for (var comment in comments.docs) {
          await comment.reference.delete();
        }
        await post.reference.delete();
      }

      // 5. Delete User's Comments on other posts
      final groupComments = await firestore
          .collectionGroup('comments')
          .where('userId', isEqualTo: uid)
          .get();
      for (var comment in groupComments.docs) {
        await comment.reference.delete();
      }

      // 6. Delete User's Reviews (Collection Group)
      try {
        final reviews = await firestore
            .collectionGroup('reviews')
            .where('userId', isEqualTo: uid)
            .get();
        for (var review in reviews.docs) {
          await review.reference.delete();
        }
      } catch (e) {
        debugPrint("Review deletion failed: $e");
      }

      // 7. Delete User's Claimed Vouchers
      final claimedVouchers = await firestore
          .collection('user_vouchers')
          .where('userId', isEqualTo: uid)
          .get();
      for (var v in claimedVouchers.docs) {
        await v.reference.delete();
      }

      // 8. Delete User Document
      await firestore.collection('users').doc(uid).delete();

      // 9. Delete Auth Account
      await user.delete();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Navigate to start
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akaun berjaya dipadamkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        if (e.toString().contains('requires-recent-login')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Keselamatan: Sila log keluar dan log masuk semula untuk memadamkan akaun anda.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which page to show
    Widget currentPage;
    switch (_currentIndex) {
      case 0:
        currentPage = const MerchantHomeView();
        break;
      case 1:
        currentPage = _buildProductsTab();
        break;
      case 2:
        currentPage = _buildVouchersTab();
        break;
      case 3:
        currentPage = _buildShopProfileTab();
        break;
      default:
        currentPage = const MerchantHomeView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sila gunakan butang Log Keluar untuk keluar"),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: Text(_getTitleForIndex(_currentIndex),
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: currentPage,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Utama'),
            NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Produk'),
            NavigationDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: 'Baucar'),
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return "Papan Pemuka";
      case 1:
        return "Produk Saya";
      case 2:
        return "Pengurus Baucar";
      case 3:
        return "Profil Kedai";
      default:
        return "";
    }
  }

  Widget _buildShopProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.store,
                      size: 50, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  _shopNameController.text.isNotEmpty
                      ? _shopNameController.text
                      : "Kedai Saya",
                  style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  _selectedCategory,
                  style:
                      GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Shop Details Form
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.grey[50], // Subtle background for the form area
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Butiran Kedai",
                      style: GoogleFonts.outfit(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _shopNameController,
                    decoration: InputDecoration(
                        labelText: "Nama Kedai",
                        prefixIcon: const Icon(Icons.store_mall_directory),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedCategory),
                    initialValue:
                        _selectedCategory, // Using initialValue as we control state via key
                    decoration: InputDecoration(
                        labelText: "Kategori",
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white),
                    items: [
                      'Makanan & Minuman',
                      'Runcit',
                      'Kraftangan',
                      'Perkhidmatan'
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: "Penerangan",
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('places')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final places = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey(_selectedNearbyPlaceId),
                        initialValue: _selectedNearbyPlaceId,
                        decoration: InputDecoration(
                          labelText: "Pautan ke Tarikan Berdekatan",
                          hintText: "Pilih tempat berdekatan",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              const Icon(Icons.location_on, color: Colors.red),
                        ),
                        items: places.map((doc) {
                          final name = doc['name'] ?? 'Unknown Place';
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final placeDoc =
                              places.firstWhere((d) => d.id == val);
                          setState(() {
                            _selectedNearbyPlaceId = val;
                            _selectedNearbyPlaceName = placeDoc['name'];
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveShopProfile,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text("Simpan Perubahan"),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red, // Text and icon color
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: Text("Log Keluar",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          // Delete Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleDeleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_forever),
              label: Text("Padam Akaun",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('merchantId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tiada produk ditambah lagi."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8)),
                    child: data['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(data['imageUrl'],
                                fit: BoxFit.cover))
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  title: Text(data['name'] ?? 'Item',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("RM ${data['price']}",
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        snapshot.data!.docs[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        label: const Text("Tambah Produk"),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Produk Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _pickProductImage();
                    setDialogState(() {});
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _productImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_productImageFile!,
                                fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: _productNameController,
                    decoration:
                        const InputDecoration(labelText: "Nama Produk")),
                TextField(
                    controller: _productPriceController,
                    decoration: const InputDecoration(labelText: "Harga (RM)"),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: _productDetailsController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: "Butiran Produk")),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addProduct, child: const Text("Tambah")),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vouchers')
            .where('merchantId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tiada baucar ditambah lagi."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: const Icon(Icons.confirmation_number,
                          color: Colors.deepOrange)),
                  title: Text(data['code'] ?? 'KOD',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  subtitle: Text(
                      "Diskaun: ${data['discount']}\nTamat: ${data['expiryDate'] != null ? DateFormat('yyyy-MM-dd').format((data['expiryDate'] as Timestamp).toDate()) : 'N/A'}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        snapshot.data!.docs[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVoucherDialog(),
        label: const Text("Cipta Baucar"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  void _showAddVoucherDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Cipta Baucar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _voucherCodeController,
                  decoration: const InputDecoration(
                      labelText: "Kod Baucar (cth. MUAR10)")),
              TextField(
                  controller: _voucherDiscountController,
                  decoration: const InputDecoration(
                      labelText: "Penerangan Diskaun (cth. DISKAUN 10%)")),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_voucherExpiryDate == null
                    ? "Pilih Tarikh Tamat"
                    : "Tamat: ${DateFormat('yyyy-MM-dd').format(_voucherExpiryDate!)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  await _pickVoucherExpiry();
                  setDialogState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: _addVoucher,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange),
                child: const Text("Cipta")),
          ],
        ),
      ),
    );
  }
}
