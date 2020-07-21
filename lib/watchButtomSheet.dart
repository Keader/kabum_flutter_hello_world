import 'package:flutter/material.dart';

class WatchButtonSheet {
  final int _id;
  SwitchListTile _offerTile;
  bool _offerTileMark = false;
  SwitchListTile _stockTile;
  bool _stockTileMark = false;
  TextField _priceField;
  SwitchListTile _valueBelowTile;
  bool _valueBelowMark = false;
  BuildContext _context;

  WatchButtonSheet(this._id);

  void mainBottomSheet(BuildContext context) {
    _context = context;
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, setState) {
            _startContent(setState);
            return Column(
                mainAxisSize: MainAxisSize.min, children: _buildContent());
          });
        });
  }

  void _startContent(setState) {
    _offerTile = SwitchListTile(
        title: const Text('Promoção'),
        value: _offerTileMark,
        onChanged: (bool value) {
          setState(() { _offerTileMark = value; });
        },
        secondary: Icon(Icons.local_offer, color: Colors.blue),
      activeColor: Colors.deepOrange,
    );

    _stockTile = SwitchListTile(
        title: const Text('Voltar para estoque'),
        value: _stockTileMark,
        onChanged: (bool value) {
          setState(() { _stockTileMark = value; });
        },
        secondary: Icon(Icons.add_shopping_cart, color: Colors.green[800]),
      activeColor: Colors.deepOrange,
    );

    _valueBelowTile = SwitchListTile(
      title: const Text('Preço abaixo de'),
      value: _valueBelowMark,
      onChanged: (bool value) {
        setState(() { _valueBelowMark = value; });
      },
      secondary: Icon(Icons.attach_money, color: Colors.amber),
      activeColor: Colors.deepOrange,
    );
  }

  Widget _buildButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 50,
      children: <Widget>[
        FlatButton(
          child: Text('Ok'),
          color: Colors.deepOrange,
          onPressed: () => _handleOkButton),
        FlatButton(
          child: Text('Cancelar'),
          color: Colors.deepOrange,
          onPressed: () => Navigator.pop(_context)),
      ],
    );
  }

  Widget _buildTextField() {
    _priceField = TextField(
      keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
          hintText: "R\$ 00,00",
          hintStyle: TextStyle(fontSize: 16.0),
      ),
      style: TextStyle(fontSize: 16.0),
    );

    return ListTile(
      leading: Icon(Icons.monetization_on, color: Colors.teal),
      title: Text("Valor: ", style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: SizedBox(child: _priceField, width: 75),
    );
  }

  void _handleOkButton() {
    // Do DB Magic here
    Navigator.pop(_context);
  }

  // Navigator.pop(context);
  List<Widget> _buildContent() {
    List<Widget> list = List();
    list.add(_offerTile);
    list.add(_stockTile);
    list.add(_valueBelowTile);
    if (_valueBelowMark)
      list.add(_buildTextField());
    list.add(_buildButtons());
    return list;
  }
}



