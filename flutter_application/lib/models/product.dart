class Product {
  final String id;
  final String name;
  final String description;
  final int price; // VND
  final String emoji;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.quantity = 0,
  });

  int get total => price * quantity;
}

final List<Product> sampleProducts = [
  Product(
    id: 'p001',
    name: 'Cà phê sữa đá',
    description: 'Cà phê truyền thống Việt Nam',
    price: 35000,
    emoji: '☕',
  ),
  Product(
    id: 'p002',
    name: 'Trà tắc',
    description: 'Trà tắc tươi mát',
    price: 25000,
    emoji: '🍋',
  ),
  Product(
    id: 'p003',
    name: 'Bánh mì thịt',
    description: 'Bánh mì Sài Gòn đặc biệt',
    price: 30000,
    emoji: '🥖',
  ),
  Product(
    id: 'p004',
    name: 'Phở bò',
    description: 'Phở bò tái chín thơm ngon',
    price: 75000,
    emoji: '🍜',
  ),
  Product(
    id: 'p005',
    name: 'Bún thịt nướng',
    description: 'Bún thịt nướng đặc trưng miền Nam',
    price: 55000,
    emoji: '🍱',
  ),
];
