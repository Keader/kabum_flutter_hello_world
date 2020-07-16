
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:lottie/lottie.dart';

import 'custom/custom_icons.dart';
import 'kabum_privateAPI/kabum_api/Kabum.dart';

class ProductDetail {
  final String name;
  final String price;
  final List<String> photos;
  final String code;
  final String offerPrice;
  final String description;

  ProductDetail(this.name, this.price, this.photos, this.code, this.offerPrice, this.description);
}

class AppProductDetail extends StatefulWidget {
  final String code;
  const AppProductDetail(this.code);

  @override
  AppProductDetailState createState() => AppProductDetailState();
}

class AppProductDetailState extends State<AppProductDetail> {
  ProductDetail _productDetail;
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (_productDetail == null) {
      _getProductDetail();
      return Container(
          child: Center(
              child: Lottie.asset('assets/load_detail.json')
          )
      );
    }

    return Scaffold(
        body: Container(
      child: ListView(children: [
        Column(children: [
          Container(child: _buildSlider(), color: Colors.white),
          _buildPriceCard(),
          _buildDescriptionCard()
        ], mainAxisAlignment: MainAxisAlignment.start),
      ]),
      color: Colors.grey[200],
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ///TODO: Make watch page
        },
        label: Text('Observar'),
        icon: Icon(Icons.remove_red_eye),
        backgroundColor: Colors.deepOrange,
      ));
  }

  Widget _buildSlider() {
    return CarouselSlider(
      options: CarouselOptions(autoPlay: _productDetail.photos.length > 1 ? true : false),
      items: _productDetail.photos.map((it) {
        if (_productDetail.photos.first == it) {
          return Container(
              child: Hero( child: Image.network(it), tag: _productDetail.code)
          );
        }

        return Container(child: Image.network(it));
      }).toList(),
    );
  }

  Widget _buildProductName() {
    return Text(_productDetail.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        textAlign: TextAlign.center);
  }

  Widget _buildPriceCard() {
    return Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey[200],
        child: Card(
            child: Container(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(text: "DE ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: 'R\$ ${_productDetail.price}',
                                style: TextStyle( decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold)),
                            TextSpan(text: ' POR', style: TextStyle(fontWeight: FontWeight.bold))]))]
                  ),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(text: 'R\$ ${_productDetail.offerPrice}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green[700])),
                            TextSpan(text: ' à vista',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[700]))]))]
                  ),
                  Row(
                  children: [
                    Icon(CustomIcons.barcode),
                    Text(' R\$ ${_productDetail.offerPrice} no boleto. 15% de desconto')]
                  ),
                  Row(
                      children: [
                        Icon(Icons.credit_card, size: 25,),
                        Text(' R\$ ${_productDetail.price} em até 12x')]
                  ),
                ]))));
  }

  Widget _buildDescriptionCard() {
    return Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey[200],
        child: Card(
            child: Column(
              children: [
                ListTile(
                  title: Text("Descrição: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon:
                    Icon(_isExpanded ? Icons.arrow_drop_up : Icons
                        .arrow_drop_down),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ),
                Divider(),
                ListTile(
                  title: _handleDescription(_isExpanded),
                ),
              ],
            )
        )
    );
  }

  Widget _handleDescription(bool expanded) {
    if (!expanded)
      return Container();

    return Html(data: _productDetail.description);
  }

  void _getProductDetail() async {
    Response resp = await Dio().get(Dictionary.productDetailEndPoint + widget.code);
    dynamic data = resp.data;

    String name = data['nome'];
    String price = data['preco'].toString();
    List<dynamic> photos = data['fotos'];
    List<String> convertedPhotos = List<String>();
    photos.forEach((element) {
      convertedPhotos.add(element.toString());
    });
    String code = data['codigo'].toString();
    String offerPrice = data['preco_desconto'].toString();
    String description = data['produto_html'];

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _productDetail = ProductDetail(
            name, price, convertedPhotos, code, offerPrice, description);
      });
    });
  }
}
