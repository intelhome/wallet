import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de Lógica Web3', () {
    
    test('La conversión de TTC a Wei debe ser exacta (evitando el RangeError)', () {
      // 1. Arrange (Preparar datos)
      double amountTTC = 1.5;
      
      // 2. Act (Ejecutar la lógica exacta de tu blockchain_service)
      String amountStr = amountTTC.toString();
      List<String> parts = amountStr.split('.');
      BigInt enteros = BigInt.parse(parts[0]) * BigInt.from(10).pow(18);
      BigInt decimales = parts.length > 1 
          ? BigInt.parse(parts[1].padRight(18, '0').substring(0, 18)) 
          : BigInt.zero;
      final amountInWei = enteros + decimales;

      // 3. Assert (Comprobar el resultado esperado)
      // 1.5 TTC debería ser exactamente 1500000000000000000 Wei
      expect(amountInWei.toString(), "1500000000000000000");
    });
    
  });
}