import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_alice/model/alice_form_data_file.dart';
import 'package:flutter_alice/model/alice_from_data_field.dart';
import 'package:flutter_alice/model/alice_http_request.dart';

extension DioRequestOptionExtension on RequestOptions {
  AliceHttpRequest transformAliceHttpRequest() {
    AliceHttpRequest request = AliceHttpRequest();
    var data = this.data;

    /// Empty model
    if (data == null) {
      request.size = 0;
      request.body = "";

      return request;
    }

    /// Is Form data
    if (data is FormData) {
      request.body += "Form data";

      if (data.fields.isNotEmpty == true) {
        List<AliceFormDataField> fields = [];
        data.fields.forEach((entry) {
          fields.add(AliceFormDataField(entry.key, entry.value));
        });
        request.formDataFields = fields;
      }

      if (data.files.isNotEmpty == true) {
        List<AliceFormDataFile> files = [];
        data.files.forEach((entry) {
          files.add(AliceFormDataFile(entry.value.filename!,
              entry.value.contentType.toString(), entry.value.length));
        });

        request.formDataFiles = files;
      }

      return request;
    }

    /// Is Json data
    if (data.toString().contains(',')) {
      request.body = data.toString().split(',').map((item) {
        if (item.contains(':')) {

          List<String> parts = item.split(":");
          if (parts.length >= 2) {
            String partKey = parts[0];
            String partValue = parts.sublist(1).join(":");

            return [partKey, partValue].map((keyValue) {
              /// case contains {
              if (keyValue.contains('{')) {
                final listConverted = keyValue.split('{');
                listConverted[1] = '\{\"${listConverted[1].trim()}\"'.trim();
                return listConverted.join('').trim();
              }

              /// case contains }
              if (keyValue.contains('}')) {
                final listConverted = keyValue.split('}');
                listConverted[0] = '\"${listConverted[0].trim()}\"\}'.trim();
                return listConverted.join('').trim();
              }

              return '\"${keyValue.trim()}\"'.trim();
            }).join(':').trim();
          }
        }
        return item.trim();
      }).join(',').trim();
      request.size = request.body.toString().length;

      return request;
    }


    /// Default case
    request.body = data;
    request.size = utf8.encode(request.body.toString()).length;

    return request;
  }
}
