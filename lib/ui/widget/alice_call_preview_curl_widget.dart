import 'package:flutter/material.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/widget/alice_base_call_details_widget.dart';

class AliceCallPreviewCurlWidget extends StatefulWidget {
  final AliceHttpCall call;

  AliceCallPreviewCurlWidget(this.call);

  @override
  State<StatefulWidget> createState() {
    return _AliceCallRequestWidget();
  }
}

class _AliceCallRequestWidget
    extends AliceBaseCallDetailsWidgetState<AliceCallPreviewCurlWidget> {
  AliceHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    rows.add(getListRow("Curl:", _call.getCurlCommand()));

    return Container(
      padding: const EdgeInsets.all(6),
      child: ListView(children: rows),
    );
  }
}
