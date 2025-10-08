import 'package:flutter/foundation.dart';
import 'package:aplikasitest1/models/order.dart';
import 'package:aplikasitest1/models/laundry_item.dart';
import 'package:aplikasitest1/models/laundry_service.dart';
import 'package:aplikasitest1/services/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  LaundryService? _selectedService;
  List<LaundryItem> _currentOrderItems = [];
  PickupInfo? _pickupInfo;


  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  LaundryService? get selectedService => _selectedService;
  List<LaundryItem> get currentOrderItems => _currentOrderItems;
  PickupInfo? get pickupInfo => _pickupInfo;


  double get currentOrderTotal {
    if (_selectedService == null) return 0.0;
    
    double total = 0.0;
    for (var item in _currentOrderItems) {
      total += item.totalPrice;
    }
    
    
    total *= _selectedService!.multiplier;
    
    
    total += 5000; 
    
    return total;
  }

  int get currentOrderItemCount {
    return _currentOrderItems.fold(0, (sum, item) {
      if (item.itemType.isPerKg) {
        return sum + 1; 
      } else {
        return sum + item.quantity;
      }
    });
  }

  
  void setSelectedService(LaundryService service) {
    _selectedService = service;
    notifyListeners();
  }

  void setPickupInfo(PickupInfo pickupInfo) {
    _pickupInfo = pickupInfo;
    notifyListeners();
  }

  
  void addItem(
    ItemType itemType, {
    int quantity = 1,
    double weight = 0.0,
    String? notes,
  }) {
    try {
      
      final existingIndex = _currentOrderItems.indexWhere(
        (item) => item.itemType == itemType,
      );

      if (existingIndex >= 0) {
        
        final existingItem = _currentOrderItems[existingIndex];
        
        if (itemType.isPerKg) {
          
          _currentOrderItems[existingIndex] = existingItem.copyWithWeight(
            existingItem.weight + weight,
          );
        } else {
        
          _currentOrderItems[existingIndex] = existingItem.copyWithQuantity(
            existingItem.quantity + quantity,
          );
        }
      } else {
        
        final newItem = LaundryItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          itemType: itemType,
          quantity: quantity,
          weight: weight,
          notes: notes,
        );
        _currentOrderItems.add(newItem);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Error adding item: $e';
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    try {
      _currentOrderItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _error = 'Error removing item: $e';
      notifyListeners();
    }
  }

  void updateItemQuantity(String itemId, int newQuantity) {
    try {
      final index = _currentOrderItems.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        if (newQuantity <= 0) {
          removeItem(itemId);
        } else {
          _currentOrderItems[index] = _currentOrderItems[index].copyWithQuantity(newQuantity);
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Error updating item quantity: $e';
      notifyListeners();
    }
  }

  void updateItemWeight(String itemId, double newWeight) {
    try {
      final index = _currentOrderItems.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        if (newWeight <= 0) {
          removeItem(itemId);
        } else {
          _currentOrderItems[index] = _currentOrderItems[index].copyWithWeight(newWeight);
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Error updating item weight: $e';
      notifyListeners();
    }
  }

  void clearCurrentOrder() {
    _currentOrderItems.clear();
    _selectedService = null;
    _pickupInfo = null;
    _error = null;
    notifyListeners();
  }

  
  List<ItemType> getAvailableItems() {
    if (_selectedService == null) return [];
    return LaundryItem.getItemsByCategory(_selectedService!.category);
  }

 
  Future<Order?> createOrder(String userId, List<LaundryItem> items) async {
    if (_selectedService == null || _pickupInfo == null) {
      _error = 'Service atau pickup info belum dipilih';
      notifyListeners();
      return null;
    }

    if (!validateCurrentOrder()) {
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      final order = Order(
        id: orderId,
        userId: userId,
        service: _selectedService!,
        items: _currentOrderItems,
        pickupInfo: _pickupInfo!,
        pickupFee: 2500,
        deliveryFee: 2500,
      );

      final createdOrder = await _orderService.createOrder(order);
      
      await loadOrders(userId);
      
      clearCurrentOrder();
      
      return createdOrder;
    } catch (e) {
      _error = 'Gagal membuat pesanan: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getUserOrders(userId);
    } catch (e) {
      _error = 'Gagal memuat pesanan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOrdersForAdmin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getAllOrders();
    } catch (e) {
      _error = 'Gagal memuat semua pesanan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
     
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].updateStatus(newStatus);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Gagal update status: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, OrderStatus.dibatalkan);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllOrders() async {
    try {
      await _orderService.clearAllOrders();
      _orders.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Gagal menghapus semua pesanan: $e';
      notifyListeners();
    }
  }

  // Utility methods
  String formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (match) => '${match[1]}.'
    )}';
  }

  String formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return '${weight.round()} kg';
    }
    
    final kg = weight.floor();
    final gram = ((weight % 1) * 1000).round();
    
    if (kg == 0) {
      return '${gram}g';
    } else if (gram == 0) {
      return '${kg} kg';
    } else {
      return '${kg}kg ${gram}g';
    }
  }


  bool validateCurrentOrder() {
    if (_selectedService == null) {
      _error = 'Pilih layanan terlebih dahulu';
      notifyListeners();
      return false;
    }

    if (_currentOrderItems.isEmpty) {
      _error = 'Tambahkan minimal satu item';
      notifyListeners();
      return false;
    }

    if (_pickupInfo == null) {
      _error = 'Isi informasi pickup terlebih dahulu';
      notifyListeners();
      return false;
    }


    for (var item in _currentOrderItems) {
      if (item.itemType.isPerKg && item.weight <= 0) {
        _error = 'Berat ${item.displayName} harus lebih dari 0 kg';
        notifyListeners();
        return false;
      }
      if (!item.itemType.isPerKg && item.quantity <= 0) {
        _error = 'Quantity ${item.displayName} harus lebih dari 0';
        notifyListeners();
        return false;
      }
    }

    _error = null;
    return true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void addItemsFromWeightSelection(Map<ItemType, double> itemWeights) {
    try {
   
      if (_selectedService != null) {
        _currentOrderItems.removeWhere(
          (item) => item.itemType.category == _selectedService!.category && item.itemType.isPerKg
        );
      }

      // Add new items with weights
      itemWeights.forEach((itemType, weight) {
        if (weight > 0) {
          final newItem = LaundryItem(
            id: 'item_${itemType.name}_${DateTime.now().millisecondsSinceEpoch}',
            itemType: itemType,
            quantity: 1, 
            weight: weight,
          );
          _currentOrderItems.add(newItem);
        }
      });

      notifyListeners();
    } catch (e) {
      _error = 'Error adding weight-based items: $e';
      notifyListeners();
    }
  }


  double get currentOrderTotalWeight {
    return _currentOrderItems.fold(0.0, (sum, item) {
      if (item.itemType.isPerKg) {
        return sum + item.weight;
      }
      return sum;
    });
  }


  double get currentOrderSubtotal {
    if (_selectedService == null) return 0.0;
    
    double subtotal = 0.0;
    for (var item in _currentOrderItems) {
      subtotal += item.totalPrice;
    }
    
    return subtotal * _selectedService!.multiplier;
  }
}