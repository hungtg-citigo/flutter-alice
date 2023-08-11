import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/helper/alice_alert_helper.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_menu_item.dart';
import 'package:flutter_alice/ui/page/alice_call_details_screen.dart';
import 'package:flutter_alice/ui/utils/alice_constants.dart';
import 'package:flutter_alice/ui/widget/alice_call_list_item_widget.dart';
import 'package:rxdart/rxdart.dart';

import 'alice_stats_screen.dart';

class AliceCallsListScreen extends StatefulWidget {
  final AliceCore _aliceCore;

  AliceCallsListScreen(this._aliceCore);

  @override
  _AliceCallsListScreenState createState() => _AliceCallsListScreenState();
}

class _AliceCallsListScreenState extends State<AliceCallsListScreen> {
  AliceCore get aliceCore => widget._aliceCore;
  bool _searchEnabled = false;
  final TextEditingController _queryTextEditingController =
      TextEditingController();
  List<AliceMenuItem> _menuItems = [];

  StreamController<bool> _enableOnlyCurlStreamController = BehaviorSubject();

  @override
  void dispose() {
    _queryTextEditingController.dispose();
    _enableOnlyCurlStreamController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _menuItems.add(AliceMenuItem(title: "Delete", iconData: Icons.delete));
    _menuItems.add(AliceMenuItem(title: "Stats", iconData: Icons.insert_chart));
    _menuItems.add(AliceMenuItem(title: "Save", iconData: Icons.save));
    _menuItems.add(AliceSwitchItem(title: "Only curl", enable: widget._aliceCore.enableShareOnlyCurl));

    _enableOnlyCurlStreamController.sink.add(widget._aliceCore.enableShareOnlyCurl);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget._aliceCore.brightness,
        primarySwatch: Colors.green,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: _searchEnabled ? _buildSearchField() : _buildTitleWidget(),
          actions: [
            _buildSearchButton(),
            _buildMenuButton(),
          ],
        ),
        body: _buildCallsListWrapper(),
      ),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: Icon(Icons.search),
      onPressed: _onSearchClicked,
    );
  }

  void _onSearchClicked() {
    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = "";
      }
    });
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<AliceMenuItem>(
      onSelected: (AliceMenuItem item) => _onMenuItemSelected(item),
      itemBuilder: (BuildContext context) {
        return _menuItems.map((AliceMenuItem item) {
          if (item.runtimeType == AliceMenuItem) {
            return PopupMenuItem<AliceMenuItem>(
              value: item,
              child: Row(children: [
                Icon(
                  item.iconData,
                  color: AliceConstants.lightRed,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10),
                ),
                Text(item.title)
              ]),
            );
          }
          return PopupMenuItem<AliceMenuItem>(
            value: item,
            child: Row(children: [
              StreamBuilder<bool>(
                initialData: widget._aliceCore.enableShareOnlyCurl,
                stream: _enableOnlyCurlStreamController.stream,
                builder: (c, s) {
                  return Switch(
                    value: s.data ?? widget._aliceCore.enableShareOnlyCurl,
                    onChanged: (value) {
                      widget._aliceCore.setEnableOnlyCurl(value);
                      _enableOnlyCurlStreamController.sink.add(value);
                    },
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
              ),
              Text(item.title)
            ]),
          );
        }).toList();
      },
    );
  }

  Widget _buildTitleWidget() {
    return Text("Inspector");
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryTextEditingController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search http request...",
        hintStyle: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
        // border: InputBorder,
      ),
      style: TextStyle(fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  void _onMenuItemSelected(AliceMenuItem menuItem) {
    if (menuItem.title == "Delete") {
      _showRemoveDialog();
    }
    if (menuItem.title == "Stats") {
      _showStatsScreen();
    }
  }

  Widget _buildCallsListWrapper() {
    return StreamBuilder<List<AliceHttpCall>>(
      stream: aliceCore.callsSubject,
      builder: (context, snapshot) {
        List<AliceHttpCall> calls = snapshot.data ?? [];
        String query = _queryTextEditingController.text.trim();
        if (query.isNotEmpty) {
          calls = calls
              .where((call) =>
                  call.endpoint.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
        if (calls.isNotEmpty) {
          return _buildCallsListWidget(calls);
        } else {
          return _buildEmptyWidget();
        }
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.error_outline,
            color: AliceConstants.orange,
          ),
          const SizedBox(height: 6),
          Text(
            "There are no calls to show",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "• Check if you send any http request",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              "• Check your Alice configuration",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              "• Check search filters",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            )
          ])
        ]),
      ),
    );
  }

  Widget _buildCallsListWidget(List<AliceHttpCall> calls) {
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        return AliceCallListItemWidget(calls[index], _onListItemClicked);
      },
    );
  }

  void _onListItemClicked(AliceHttpCall call) {
    Navigator.push(
      widget._aliceCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => AliceCallDetailsScreen(call, widget._aliceCore),
      ),
    );
  }

  void _showRemoveDialog() {
    AliceAlertHelper.showAlert(
      context,
      "Delete calls",
      "Do you want to delete http calls?",
      firstButtonTitle: "No",
      firstButtonAction: () => {},
      secondButtonTitle: "Yes",
      secondButtonAction: () => _removeCalls(),
    );
  }

  void _removeCalls() {
    aliceCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push(
      aliceCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => AliceStatsScreen(widget._aliceCore),
      ),
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }
}
