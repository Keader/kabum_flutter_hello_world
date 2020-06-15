import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kabumflutterhelloworld/productDetail.dart';

import 'home.dart';

class ProductSuggestion {
  final String name;
  final String code;

  ProductSuggestion(this.name, this.code);
}

class AppsSearch extends StatefulWidget {
  @override
  AppsSearchState createState() => AppsSearchState();
}

class AppsSearchState extends State<AppsSearch> {
  final FocusNode _searchNode = FocusNode();
  Timer _timer;
  final Set<ProductSuggestion> _suggestions = Set<ProductSuggestion>();
  final ScrollController _scrollController = ScrollController();
  final Set<Product> _products = Set<Product>();
  bool _hasSearchInProgress = false;
  bool _isSubmited = false;
  int _currentPage = 1;
  int _maxPages = 0;
  String _searchWord;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (_currentPage < _maxPages) {
          ++_currentPage;
          _handleSearch(false);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _getSuggestions(String text) async {
    String url = Dictionary.autoCompleteEndPoint + text +"&limite=10";
    Response resp = await Dio().get(url);
    _suggestions.clear();
    List<dynamic> list = resp.data['produtos'];
    for (int i = 0; i < list.length; ++i){
      dynamic entry = list[i];
      String name = entry['nome'];
      String code = entry['codigo'].toString();
      _suggestions.add(ProductSuggestion(name, code));
    }

    setState(() {
      _hasSearchInProgress = false;
      _isSubmited = false;
    });
  }

  void _handleSearch(bool showProgressBar) async {
    setState(() {
      if (showProgressBar) _hasSearchInProgress = true;
    });

    String finalEndPoint = Dictionary.searchEndPoint + _searchWord + "&pagina="+_currentPage.toString();
    Response resp = await Dio().get(finalEndPoint);
    bool isRedirect = false;

    if (resp.data['redirect'].length != 0) {
      String redirectTarget = resp.data['redirect'].join('/');
      String url = Dictionary.listEndPoint + redirectTarget + "?" + "pagina=" + _currentPage.toString();
      resp = await Dio().get(url);
      isRedirect = true;
    }

    double pageNumber =  (isRedirect ? resp.data['itens'] : resp.data['itens']['count']) / 10;
    _maxPages = pageNumber.ceil();

    List<dynamic> list = resp.data['listagem'];
    for (int i = 0; i < list.length; ++i){
      dynamic entry = list[i];
      String name = entry['nome'];
      double priceDouble = entry['preco_desconto'];
      String price = priceDouble.toStringAsFixed(2);
      String photo = entry['img'];
      String code = entry['codigo'].toString();
      _products.add(Product(name, price, photo, code));
    }

    setState(() {
      _hasSearchInProgress = false;
      _isSubmited = true;
    });
  }

  void _handleSuggestion(String text) {
    if (_timer?.isActive == true) {
      _timer.cancel();
    }
    _timer = Timer(const Duration(seconds: 2), () {
      if (text.isNotEmpty) {
        setState(() {
          _hasSearchInProgress = true;
        });
        _getSuggestions(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: TextField(
            focusNode: _searchNode,
            onSubmitted: (value) {
              _searchNode.unfocus();
              if (value != _searchWord){
                _products.clear();
                _searchWord = value;
              }
              _timer?.cancel();
              _handleSearch(true);
            },
            onChanged: (value) {
              _handleSuggestion(value);
            },
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Buscar...",
              hintStyle: TextStyle(fontSize: 16.0, color: Colors.lightBlue),
              icon: Icon(Icons.search, color: Colors.lightBlueAccent)
            ),
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 16.0
            ),
          ),
        ),
        body: _buildSuggestionBody()
    );
  }

  Widget _buildSuggestionBody() {
    // Make progress bar animation
    if (_hasSearchInProgress)
      return LinearProgressIndicator(backgroundColor: Colors.lightBlue);

    // Make a empty screen (initial search screen)
    if (_suggestions.isEmpty && !_isSubmited)
      return Container();

    // Make product list screen
    if (_isSubmited)
      return _buildProductList();

    // Make suggestion screen
    return _buildSuggestionList();
  }

  Widget _buildProductList() {

    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
          color: Colors.black,
        ),
        controller: _scrollController,
        itemCount: _products.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_products.elementAt(index).photo),
              ),
              title: Text(_products.elementAt(index).name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Preço: R\$ " + _products.elementAt(index).price),
              trailing: Icon(Icons.shopping_cart, color: Colors.lightBlue),
              onTap: () {
                _getProductDetailOverload(_products.elementAt(index));
              });
        });
  }

  Widget _buildSuggestionList() {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey,
        ),
        itemCount: _suggestions.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
              leading: Icon(Icons.search, color: Colors.black26),
              title: Text(_suggestions.elementAt(index).name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.shopping_cart, color: Colors.lightBlue),
              onTap: () {
                _getProductDetail(_suggestions.elementAt(index));
              });
        });
  }

  void _getProductDetail(ProductSuggestion product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(
                title: Text(product.name, overflow: TextOverflow.ellipsis),
              ),
              body: AppProductDetail(product.code)
          );
        },
      ),
    );
  }

  void _getProductDetailOverload(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(
                title: Text(product.name, overflow: TextOverflow.ellipsis),
              ),
              body: AppProductDetail(product.code)
          );
        },
      ),
    );
  }

}
