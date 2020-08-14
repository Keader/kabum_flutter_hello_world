import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:kabumflutterhelloworld/appDB/appDatabase.dart';
import 'package:kabumflutterhelloworld/appDB/watch.dart';
import 'package:kabumflutterhelloworld/productDetail.dart';
import 'package:kabumflutterhelloworld/search.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'notification/localNotification.dart';
import 'notificationPage.dart';
import 'kabum_privateAPI/kabum_api/Kabum.dart';

class Product {
  final String name;
  final String price;
  final String photo;
  final String code;

  Product(this.name, this.price, this.photo, this.code);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppDatabase db = await $FloorAppDatabase
      .databaseBuilder('kabum_flutter.db')
      .build();

  //List<Watch> watches = await db.watchDao.findAllWatchs();
  //watches.isNotEmpty ? setupService() : BackgroundFetch.stop();

  BackgroundFetch.stop();

  runApp(
      MultiProvider(
        providers: [
          Provider<DB>(create: (_) => DB(db)),
          Provider<LocalNotification>(create: (_) => LocalNotification())
        ],
        child: MyApp(),
      ),
  );
}

void backgroundFetchHeadlessTask(String taskId) async {

  switch(taskId) {
    case 'flutter_background_fetch':
      {
        break;
      }
    default:
      break;
  }
  BackgroundFetch.finish(taskId);
}

void onBackgroundFetch(String taskId) async {
  //LocalNotification().showNotification(title: "Teste", body: "Mytest");

  switch(taskId) {
    case 'flutter_background_fetch':
      break;
    default:
      break;
  }

  print('_onBackgroundFetch: $taskId');
  BackgroundFetch.finish(taskId);
}

void setupService() async {
  await BackgroundFetch.configure(BackgroundFetchConfig(
    minimumFetchInterval: 15,
    forceAlarmManager: false,
    stopOnTerminate: false,
    startOnBoot: true,
    enableHeadless: true,
    requiresBatteryNotLow: false,
    requiresCharging: false,
    requiresStorageNotLow: false,
    requiresDeviceIdle: false,
    requiredNetworkType: NetworkType.ANY,
  ), onBackgroundFetch);

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  bool _isLoading = false;
  AppBar _appBar;

  @override
  void initState() {
    super.initState();

    // Handle with page scrolldown
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // Loading already in progress
        if (_isLoading)
          return;
        // Check if we got the max pages already
        if (_currentPage < _maxPages)
          ++_currentPage;

        setState(() { _isLoading = true; });
        _getProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
          child: Scaffold(
            backgroundColor: Colors.blue,
            bottomNavigationBar: Container (
              height: 52.0,
              child: TabBar (
                tabs: [
                  Tab(icon: Icon(Icons.add_shopping_cart, color: Colors.blue[200],), text: "Promoções", iconMargin: EdgeInsets.all(5)),
                  Tab(icon: Icon(Icons.notifications, color: Colors.blue[200]), text: "Notificações", iconMargin: EdgeInsets.all(5)),
                ],
                unselectedLabelColor: Colors.white60,
                labelColor: Colors.white,
                indicatorColor: Colors.transparent,
              ),
            ),
            body: TabBarView(
              children: [
                _buildPromotionHome(),
                _buildNotificationPage(),
              ],
            ),
          ),
    );
  }

  Widget _buildNotificationPage() {
    return NotificationPage(_appBar);
  }

  Widget _buildPromotionHome() {
    _appBar = AppBar(
      centerTitle: true,
      title: Container(
        height: 130.0,
        width: 130.0,
        child: Image.network('https://static.kabum.com.br/conteudo/temas/001/imagens/topo/logo_kabum_.png'),
      ),
      actions: <Widget>[
        IconButton(icon: Icon(Icons.search), onPressed: _pushSearch),
      ],
    );

    return Scaffold(
      appBar: _appBar,
      body: _buildHome(),
    );
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
      double priceDouble = entry['vlr_oferta'].runtimeType == double ? entry['vlr_oferta'] : entry['vlr_oferta'].toDouble();
      String price = priceDouble.toStringAsFixed(2);
      String photo = entry['imagem'];
      String code = entry['codigo'].toString();
        _products.add(Product(name, price, photo, code));
    }

    setState(() { _isLoading = false; });
  }

  Widget _buildHome() {
    if (_products.isEmpty) {
      _getOffers();
      return Center(
          child: Column(
              children: [
                Lottie.asset('assets/explosion2.json')
        ], mainAxisAlignment: MainAxisAlignment.center),
      );
    }

    return Column (
      children: [
      Flexible(child: _buildListView()),
        _getProgressBar()
      ],
    );
  }

  Widget _getProgressBar() => _isLoading ? LinearProgressIndicator(backgroundColor: Colors.blue[700], valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)) : Container();

  Widget _buildListView() {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
          color: Colors.black,
        ),
        controller: _scrollController,
        itemCount: _products.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
              leading: Hero(
                  tag: _products.elementAt(index).code,
                  child: CircleAvatar (
                    backgroundImage: NetworkImage(_products.elementAt(index).photo),
                  )),
              title: Text(_products.elementAt(index).name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Preço: R\$ " + _products.elementAt(index).price),
              trailing: Icon(Icons.shopping_basket, color: Colors.deepOrange),
              onTap: () {
                _getProductDetail(_products.elementAt(index));
                /*
                BackgroundFetch.scheduleTask(TaskConfig(
                    taskId: "MyCustomEvent",
                    delay: 10000,
                    periodic: false,
                    forceAlarmManager: false,
                    stopOnTerminate: false,
                    enableHeadless: true
                ));*/
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
