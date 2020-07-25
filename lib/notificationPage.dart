

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kabumflutterhelloworld/Database/database.dart';
import 'package:kabumflutterhelloworld/productDetail.dart';
import 'package:kabumflutterhelloworld/watchButtomSheet.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'Database/watch.dart';
import 'kabum_privateAPI/kabum_api/Kabum.dart';

class NotificationPage extends StatefulWidget {
  final AppBar _appBar;

  const NotificationPage(this._appBar);

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  Set<ProductDetail> _products = Set<ProductDetail>();
  List<Watch> _watchs;
  bool error = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget._appBar,
      body: _buildContent()
    );
  }

  Widget _buildContent() {
    if (error) {
      return Center(
        child: Column(
            children: [
              Lottie.asset('assets/error.json'),
              Text("Você não possui nenhuma notificação.", style: TextStyle(color: Colors.red, fontSize: 20.0, fontWeight: FontWeight.bold))
            ], mainAxisAlignment: MainAxisAlignment.center),
      );
    }

    if (_products.isEmpty)
      return Center(child: Lottie.asset('assets/load_favorite.json'));

    return _buildListView();
  }

  void _loadProducts() async {
    WatchDao db = Provider.of<DB>(context, listen: false).watchDB;
    List<Watch> watchs = await db.findAllWatchs();
    if (watchs.isEmpty && !error) {
      setState(() => error = true);
      return;
    }
    _products.clear();
    for(Watch watch in watchs) {
      ProductDetail product = await _getProductDetail(watch.id);
      _products.add(product);
    }

    setState(() {
      error = false;
      _watchs = watchs;
    });
  }

  Future<ProductDetail> _getProductDetail(int productId) async {
    Response resp = await Dio().get(Dictionary.productDetailEndPoint + productId.toString());
    dynamic data = resp.data;

    String name = data['nome'];
    String price = data['preco'].toString();
    List<dynamic> photos = data['fotos'];
    List<String> convertedPhotos = List<String>();
    photos.forEach((element) {
      convertedPhotos.add(element.toString());
    });
    String code = data['codigo'].toString();
    String offerPrice = data['preco_desconto'].toStringAsFixed(2);
    String description = data['produto_html'];
    String oldPrice = data['preco_antigo'].toStringAsFixed(2);
    ProductDetail product = ProductDetail(name, price, convertedPhotos, code, offerPrice, description, oldPrice);
    return product;
  }

  Widget _buildListView() {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(color: Colors.black),
        itemCount: _products.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(_products.elementAt(index).photos.first),
              ),
              title: Text(_products.elementAt(index).name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: _buildAlertIcons(index),
              trailing: Icon(Icons.edit, color: Colors.deepOrange),
              onTap: () {
                WatchButtonSheet(int.parse(_products.elementAt(index).code)).mainBottomSheet(context, this);
              });
        });
  }

  void updateInterface() {
    _loadProducts();
  }

  Widget _buildAlertIcons(int index) {
    ProductDetail product = _products.elementAt(index);
    Watch watch = _watchs.firstWhere((element) {
     return element.id == int.parse(product.code);
    });
    List items = List<Widget>();

    if (watch.flags & WatchButtonSheet.FLAG_OFFER != 0)
      items.add(Icon(Icons.local_offer, color: Colors.blue));

    if (watch.flags & WatchButtonSheet.FLAG_STOCK != 0)
      items.add(Icon(Icons.add_shopping_cart, color: Colors.green[800]));

    if (watch.flags & WatchButtonSheet.FLAG_PRICE != 0) {
      items.add(Icon(Icons.attach_money, color: Colors.amber));
      items.add(Text('R\$ ${watch.price}'));
    }

    return Row(children:items);
  }
}
