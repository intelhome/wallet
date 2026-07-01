import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class ContactService {
  final AuthCoreService authCore;
  final LocalCacheService _cacheService = LocalCacheService();

  ContactService(this.authCore);

  Future<List<dynamic>> getContacts({Function(List<dynamic>)? onNetworkSync}) async {
    if (authCore.publicAddress.isEmpty) return [];

    List<dynamic> cachedContacts = _cacheService.getCachedContacts();

    // Petición de fondo
    _fetchContactsFromNetwork().then((freshData) {
      if (freshData.isNotEmpty && onNetworkSync != null) {
        onNetworkSync(freshData);
      }
    }).catchError((e) => print("Error de red en contactos: $e"));

    if (cachedContacts.isEmpty) {
      return await _fetchContactsFromNetwork();
    }
    return cachedContacts;
  }

  // Método original convertido en Helper privado
  Future<List<dynamic>> _fetchContactsFromNetwork() async {
    try {
      final url = Uri.parse(ApiConfig.getContacts.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
      final response = await http.get(url, headers: authCore.authHeaders).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> lista = jsonDecode(response.body);
        lista.sort((a, b) {
          int favA = (a['favorite'] == true) ? 1 : 0;
          int favB = (b['favorite'] == true) ? 1 : 0;
          return favB.compareTo(favA);
        });
        
        await _cacheService.saveContacts(lista); // 🔥 GUARDAR EN CACHÉ
        return lista;
      }
    } catch (e) {
      print("Error ContactService._fetchContactsFromNetwork: $e");
    }
    return [];
  }

  // Future<List<dynamic>> getContacts() async {
  //   if (authCore.publicAddress.isEmpty) return [];
  //   try {
  //     final url = Uri.parse(ApiConfig.getContacts.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
  //     final response = await http.get(url, headers: authCore.authHeaders);

  //     if (response.statusCode == 200) {
  //       List<dynamic> lista = jsonDecode(response.body);
  //       // Ordenamos: Favoritos primero
  //       lista.sort((a, b) {
  //         int favA = (a['favorite'] == true) ? 1 : 0;
  //         int favB = (b['favorite'] == true) ? 1 : 0;
  //         return favB.compareTo(favA);
  //       });
  //       return lista;
  //     }
  //   } catch (e) {
  //     print("Error ContactService.getContacts: $e");
  //   }
  //   return [];
  // }

  Future<String> addContact(String contactAddress, String alias, String category) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.addContact),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "ownerAddress": authCore.publicAddress.toLowerCase(),
          "contactAddress": contactAddress.toLowerCase(),
          "alias": alias,
          "category": category,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) return "Exito";
      if (response.statusCode == 401 || response.statusCode == 403) return "Error de sesión: Token inválido";
      return "El contacto ya existe en tu libreta";
    } catch (e) {
      return "Error de red al guardar";
    }
  }

  Future<bool> updateContact(String contactId, {String? alias, String? category, bool? isFavorite}) async {
    try {
      final bodyData = <String, dynamic>{};
      if (alias != null) bodyData["alias"] = alias;
      if (category != null) bodyData["category"] = category;
      if (isFavorite != null) bodyData["isFavorite"] = isFavorite;

      final url = Uri.parse(ApiConfig.updateContact.replaceAll("{id}", contactId));
      final response = await http.put(url, headers: authCore.authHeaders, body: jsonEncode(bodyData));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      final url = Uri.parse(ApiConfig.deleteContact.replaceAll("{id}", contactId));
      final response = await http.delete(url, headers: authCore.authHeaders);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}