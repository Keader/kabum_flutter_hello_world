// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:kabumflutterhelloworld/productDetail.dart';
import 'package:kabumflutterhelloworld/search.dart';

class Product {
  final String name;
  final String price;
  final String photo;
  final String code;

  Product(this.name, this.price, this.photo, this.code);
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      home: AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  @override
  AppHomeState createState() => AppHomeState();
}

class AppHomeState extends State<AppHome> {
  final Set<Product> _products = Set<Product>();
  String _offer = "";
  int _maxPages = 10;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Kabum Flutter Teste', style: TextStyle(fontSize: 18.0, color: Colors.lightBlueAccent)),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.search), onPressed: _pushSearch),
        ],
      ),

      body: _buildHome(),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // Check if we got the max pages already
        if (_currentPage < _maxPages) {
          ++_currentPage;
        }

          _getProducts();
      }
    });

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _pushSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return AppsSearch();
        },
      ),
    );
  }


  void _getOffers() async {
    Response resp = await Dio().get(Dictionary.home_endpoint);
    _offer = resp.data['oferta']['path_json'];
    _getProducts();
  }

  void _getProducts() async {
    String finalEndPoint = Dictionary.offers_endpoint+"pagina="+_currentPage.toString()+"&app=1&limite=10&campanha="+_offer;
    Response resp = await Dio().get(finalEndPoint);

    // Update max pages number (first run only xd)
    if (_maxPages != resp.data['quant_paginas'])
      _maxPages = resp.data['quant_paginas'];

    List<dynamic> list = resp.data['produtos'];
    for (int i = 0; i < list.length; ++i){
      dynamic entry = list[i];
      String name = entry['produto'];
      double priceDouble = entry['vlr_oferta'];
      String price = priceDouble.toStringAsFixed(2);
      String photo = entry['imagem'];
      String code = entry['codigo'].toString();
      _products.add(Product(name, price, photo, code));
    }

    setState(() {});
  }

  Widget _buildHome() {
    if (_products.isEmpty) {
      _getOffers();
      return Center(
          child: Column(
              children: [
                Text("Loading..."),
                CircularProgressIndicator(),
        ], mainAxisAlignment: MainAxisAlignment.center),
      );
    }

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
                _getProductDetail(_products.elementAt(index));
              });
        });
  }

  void _getProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(product.name, overflow: TextOverflow.ellipsis),
            ),
            body: AppProductDetail(product.code));
        },
      ),
    );
  }
}
