import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';
import 'package:http/http.dart' as http;

class FavoriteCubit extends Cubit<List<ProductModel>> {
  FavoriteCubit() : super([]);

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('favorites') ?? [];
    final list = jsonList
        .map((str) => ProductModel.fromJson(json.decode(str)))
        .toList();
    emit(list);
  }

  Future<void> toggle(ProductModel product) async {
    final current = List<ProductModel>.from(state);
    final exists = current.any((p) => p.productId == product.productId);

    if (exists) {
      current.removeWhere((p) => p.productId == product.productId);
    } else {
      current.add(product);
    }

    emit(current);
    await _saveToPrefs(current);
    await _syncWithServer(product, exists ? 'remove' : 'add');
  }

  Future<void> _saveToPrefs(List<ProductModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList('favorites', jsonList);
  }

  Future<void> remove(ProductModel product) async {
    final current = List<ProductModel>.from(state)
      ..removeWhere((p) => p.productId == product.productId);
    emit(current);
    await _saveToPrefs(current);
    await _syncWithServer(product, 'remove');
  }

  Future<void> _syncWithServer(ProductModel product, String action) async {
    final endpoint = action == 'add' ? 'addfavorite' : 'removefavorite';
    final url = Uri.parse('https://jewelrystore-production.up.railway.app/api/$endpoint');
    final resp = await http.post(url, body: {
      'ProductID': product.productId.toString(),
    });
    if (resp.statusCode != 200) {
      print('خطأ مزامنة المفضلة: ${resp.statusCode}');
    }
  }
}
