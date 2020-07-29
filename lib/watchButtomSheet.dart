import 'package:flutter/material.dart';
import 'package:kabumflutterhelloworld/Database/database.dart';
import 'package:provider/provider.dart';

import 'Database/watch.dart';
import 'notificationPage.dart';

class WatchButtonSheet {
  final int _id;
  SwitchListTile _offerTile;
  bool _offerTileMark = false;
  SwitchListTile _stockTile;
  bool _stockTileMark = false;
  TextFormField _priceField;
  SwitchListTile _valueBelowTile;
  bool _valueBelowMark = false;
  BuildContext _context;
  bool _isValidForm = false;
  bool _needDBLoad = true;
  final _textController = TextEditingController();
  NotificationPageState _notificationPage;

  static const FLAG_OFFER = 1;
  static const FLAG_STOCK = 2;
  static const FLAG_PRICE = 4;

  WatchButtonSheet(this._id);

  void mainBottomSheet(BuildContext context, [NotificationPageState notificationPage]) {
    _notificationPage = notificationPage;
    _context = context;
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, setState) {
            if (_needDBLoad) {
              _needDBLoad = false;
              _handleWithMarks(setState);
            }
            _startContent(setState);
            return Column(
                mainAxisSize: MainAxisSize.min, children: _buildContent());
          });
        });
  }

  void _handleWithMarks(setState) async {
    WatchDao db = Provider.of<DB>(_context, listen: false).watchDB;
    Watch watch = await db.findWatchById(_id);

    if (watch == null)
      return;

    setState(() {
      _offerTileMark = watch.flags & FLAG_OFFER != 0 ? true : false;
      _stockTileMark = watch.flags & FLAG_STOCK != 0 ? true : false;
      _valueBelowMark = watch.flags & FLAG_PRICE != 0 ? true : false;
      _textController.text = watch.price.toString();
    });
  }

  void _startContent(setState) {
    _offerTile = SwitchListTile(
        title: const Text('Promoção'),
        value: _offerTileMark,
        onChanged: (bool value) {
          setState(() { _offerTileMark = value; });
        },
        secondary: Icon(Icons.local_offer, color: _offerTileMark ? Colors.blue : Colors.grey),
      activeColor: Colors.deepOrange,
    );

    _stockTile = SwitchListTile(
        title: const Text('Voltar para estoque'),
        value: _stockTileMark,
        onChanged: (bool value) {
          setState(() { _stockTileMark = value; });
        },
        secondary: Icon(Icons.add_shopping_cart, color: _stockTileMark ? Colors.blue : Colors.grey),
      activeColor: Colors.deepOrange,
    );

    _valueBelowTile = SwitchListTile(
      title: const Text('Preço abaixo de'),
      value: _valueBelowMark,
      onChanged: (bool value) {
        setState(() { _valueBelowMark = value; });
      },
      secondary: Icon(Icons.attach_money, color: _valueBelowMark ? Colors.blue : Colors.grey),
      activeColor: Colors.deepOrange,
    );
  }

  Widget _buildButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 50,
      children: <Widget>[
        Container(
            width: 150,
            height: 48,
            child: MaterialButton(
              elevation: 0.0,
              color: Colors.white,
              child: Text('Cancelar', style: TextStyle(color: Colors.blue)),
              shape: StadiumBorder(side: BorderSide(color: Colors.blue, width: 2)),
              onPressed: () => Navigator.pop(_context)
            )),
        Container(
            width: 150,
            height: 48,
            child: MaterialButton(
              color: Colors.blue,
              child: Text('Confirmar', style: TextStyle(color: Colors.white)),
              shape: StadiumBorder(),
              onPressed: () => _handleOkButton()
            ))
      ],
    );
  }

  Widget _buildTextField() {
    _priceField = TextFormField (
      controller: _textController,
      validator: (value) {
        _isValidForm = false;
        if (value.isEmpty) {
          return "";
        }

        value = value.replaceAll(",", ".");
        double price = double.tryParse(value);
        // Check if someone type a int value
        if (price == null) {
          int priceInt = int.tryParse(value);
          if (priceInt != null)
            price = priceInt.toDouble();
        }

        if (price == null || price < 0) {
          return "Erro";
        }

        _isValidForm = true;
        return null;
      },
      autovalidate: true,
      keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
          hintText: "R\$ 0,00",
          hintStyle: TextStyle(fontSize: 16.0),
      ),
      style: TextStyle(fontSize: 16.0),
    );

    return ListTile(
      leading: Icon(Icons.monetization_on, color: Colors.blue),
      title: Text("Valor: ", style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: SizedBox(child: _priceField, width: 75),
    );
  }

  Future<void> _handleOkButton() async {
    if (_valueBelowMark && !_isValidForm) {
      return;
    }

    Navigator.pop(_context);
    WatchDao db = Provider.of<DB>(_context, listen: false).watchDB;
    // nothing marked, so delete everything
    if (!_offerTileMark && !_stockTileMark && !_valueBelowMark) {
      db.deleteById(_id);
      return;
    }

    int flags = 0;
    double price = 0;
    if (_offerTileMark)
      flags |= FLAG_OFFER;
    if (_stockTileMark)
      flags |= FLAG_STOCK;
    if (_valueBelowMark)
      flags |= FLAG_PRICE;

    if (_valueBelowMark) {
      price = double.tryParse(_textController.text);
      // Sanity check. Should never happens, cause validator should handle with it
      if (price == null)
        return;
    }

    Watch watch = Watch(_id, price, flags);
    db.insertWatch(watch);
    _notificationPage?.updateInterface();
  }

  List<Widget> _buildContent() {
    List<Widget> list = List();
    list.add(_offerTile);
    list.add(_stockTile);
    list.add(_valueBelowTile);
    if (_valueBelowMark)
      list.add(_buildTextField());
    list.add(_buildButtons());
    list.add(Container(padding: EdgeInsets.all(8)));
    return list;
  }
}



