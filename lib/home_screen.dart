import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasitest1/controllers/order_controller.dart';
import 'package:aplikasitest1/services/auth_service.dart';
import 'package:aplikasitest1/models/laundry_item.dart';
import 'package:aplikasitest1/view/order_category_page.dart';
import 'package:aplikasitest1/view/order_history_page.dart';
import 'package:aplikasitest1/view/LoginPage.dart';
import 'package:aplikasitest1/widgets/admin_access_widget.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String username;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load orders setelah widget di-render
      context.read<OrderController>().loadOrders(widget.userId);
    });
  }

  // Logout function
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await AuthService.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.lightBlueAccent,
                        Colors.blue.shade300,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Overlay gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                borderRadius: BorderRadius.circular(25),
                blur: 8,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                color: Colors.white.withOpacity(0.03),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.04),
                  ],
                  stops: const [0.0, 1.0],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildCategoriesSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const AdminAccessWidget(),
    );
  }

  // Header with logout button
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color:
                      const Color.fromARGB(255, 45, 202, 233).withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/images/olaf.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${widget.username}!',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Mari mulai mencuci pakaian Anda 🧺',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Logout button
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout,
                color: Color.fromARGB(219, 50, 213, 72)),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  // Quick Actions
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGlassButton(
                  icon: Icons.add_shopping_cart,
                  title: 'Buat Pesanan',
                  color: Colors.greenAccent,
                  onTap: () => _showCategoryBottomSheet(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassButton(
                  icon: Icons.history,
                  title: 'Riwayat',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryPage(userId: widget.userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 18,
      border: Border.fromBorderSide(
        BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      color: Colors.white.withOpacity(0.02),
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.12),
          const Color.fromARGB(255, 221, 93, 93).withOpacity(0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Categories Section
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Tersedia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: LaundryCategory.values.length,
            itemBuilder: (context, index) {
              final category = LaundryCategory.values[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(LaundryCategory category) {
    final color = _getCategoryColors(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        blur: 18,
        border: Border.fromBorderSide(
          BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        color: Colors.white.withOpacity(0.02),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              category.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _getCategoryDescription(category),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryOrderPage(
                    userId: widget.userId,
                    category: category,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getCategoryColors(LaundryCategory category) {
    switch (category) {
      case LaundryCategory.pakaian:
        return Colors.blueAccent;
      case LaundryCategory.tas:
        return Colors.greenAccent;
      case LaundryCategory.sepatu:
        return Colors.orangeAccent;
      case LaundryCategory.kering:
        return Colors.purpleAccent;
      case LaundryCategory.setrika:
        return Colors.redAccent;
      case LaundryCategory.karpet:
        return Colors.tealAccent;
    }
  }

  String _getCategoryDescription(LaundryCategory category) {
    switch (category) {
      case LaundryCategory.pakaian:
        return 'Cuci bersih semua jenis pakaian';
      case LaundryCategory.tas:
        return 'Pembersihan tas dan dompet';
      case LaundryCategory.sepatu:
        return 'Cuci sepatu profesional';
      case LaundryCategory.kering:
        return 'Dry cleaning premium';
      case LaundryCategory.setrika:
        return 'Layanan setrika saja';
      case LaundryCategory.karpet:
        return 'Cuci karpet & gorden';
    }
  }

  // Bottom Sheet Pilihan Kategori
  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Kategori Laundry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...LaundryCategory.values.map(
              (category) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColors(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(category.displayName),
                subtitle: Text(_getCategoryDescription(category)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryOrderPage(
                        userId: widget.userId,
                        category: category,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
