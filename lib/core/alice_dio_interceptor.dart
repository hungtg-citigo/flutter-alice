import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/model/alice_form_data_file.dart';
import 'package:flutter_alice/model/alice_from_data_field.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';
import 'package:flutter_alice/utils/dio_request_option_extension.dart';

class AliceDioInterceptor extends InterceptorsWrapper {
  /// AliceCore instance
  final AliceCore aliceCore;

  /// Creates dio interceptor
  AliceDioInterceptor(this.aliceCore);

  /// Handles dio request and creates alice http call based on it
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    AliceHttpCall call = new AliceHttpCall(options.hashCode);

    Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.length == 0) {
      path = "/";
    }
    call.endpoint = path;
    call.server = uri.host;
    call.client = "Dio";
    call.uri = options.uri.toString();

    if (uri.scheme == "https") {
      call.secure = true;
    }

    /// Convert to alice http request
    AliceHttpRequest request = options.transformAliceHttpRequest();

    request.time = DateTime.now();
    request.headers = options.headers;
    request.contentType = options.contentType.toString();

    /// Convert query parameter if need
    if (options.path.contains("?")) {
      final listParameter = options.path.split("?");

      if (listParameter.length >= 2) {
        final queryParameters = Map<String, dynamic>.fromIterable(
          listParameter[1].split("&"),
          key: (param) => param.split("=")[0],
          value: (param) => param.split("=")[1],
        );
        request.queryParameters = queryParameters;
      }
    } else {
      request.queryParameters = options.queryParameters;
    }

    call.request = request;
    call.response = AliceHttpResponse();

    aliceCore.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to alice http call
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    var httpResponse = AliceHttpResponse();
    httpResponse.status = response.statusCode!;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(response.data.toString()).length;
    }

    httpResponse.time = DateTime.now();
    Map<String, String> headers = Map();
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    aliceCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to alice http call
  @override
  void onError(
    DioError error,
    ErrorInterceptorHandler handler,
  ) {
    var httpError = AliceHttpError();
    httpError.error = error.toString();
    if (error is Error) {
      var basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }

    aliceCore.addError(httpError, error.requestOptions.hashCode);
    var httpResponse = AliceHttpResponse();
    httpResponse.time = DateTime.now();
    if (error.response == null) {
      httpResponse.status = -1;
      aliceCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = error.response!.statusCode!;

      if (error.response!.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        httpResponse.body = error.response!.data;
        httpResponse.size = utf8.encode(error.response!.data.toString()).length;
      }
      Map<String, String> headers = Map();
      if (error.response?.headers != null) {
        error.response!.headers.forEach((header, values) {
          headers[header] = values.toString();
        });
      }
      httpResponse.headers = headers;
      aliceCore.addResponse(
          httpResponse, error.response!.requestOptions.hashCode);
    }
    handler.next(error);
  }
}
