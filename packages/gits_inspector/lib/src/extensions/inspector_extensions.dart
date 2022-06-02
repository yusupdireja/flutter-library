import 'package:flutter/material.dart';
import 'package:gits_inspector/gits_inspector.dart';
import 'package:gits_inspector/src/extensions/date_time_extensions.dart';
import 'package:gits_inspector/src/helper/pretty_json_helper.dart';

const int kilobyteAsByte = 1000;
const int megabyteAsByte = 1000000;
const int secondAsMillisecond = 1000;
const int minuteAsMillisecond = 60000;

extension InspectorExtension on Inspector {
  String _formatDouble(double value) => value.toStringAsFixed(2);
  String _calculateSize(int bytes) {
    if (bytes < 0) {
      return "-1 B";
    }
    if (bytes <= kilobyteAsByte) {
      return "$bytes B";
    }
    if (bytes <= megabyteAsByte) {
      return "${_formatDouble(bytes / kilobyteAsByte)} kB";
    }

    return "${_formatDouble(bytes / megabyteAsByte)} MB";
  }

  String get pathWithQuery {
    final method = request.method;
    final path = request.url.path;
    final query = Uri.decodeQueryComponent(request.url.query);
    return '$method $path${query.isNotEmpty ? '?$query' : ''}';
  }

  bool get isSSL => request.url.scheme == 'https';

  String get totalSize {
    int size = -1;
    if (request.size != null || response?.size != null) {
      size = (request.size ?? 0) + (response?.size ?? 0);
    }
    return _calculateSize(size);
  }

  String get requestSize => _calculateSize(request.size ?? -1);
  String get responseSize => _calculateSize(response?.size ?? -1);

  String get duration {
    final timeInMillis = response?.dateTime != null
        ? response?.dateTime?.difference(createdAt).inMilliseconds ?? 0
        : -1;

    if (timeInMillis < 0) {
      return "-1 ms";
    }
    if (timeInMillis <= secondAsMillisecond) {
      return "$timeInMillis ms";
    }
    if (timeInMillis <= minuteAsMillisecond) {
      return "${_formatDouble(timeInMillis / secondAsMillisecond)} s";
    }

    final Duration duration = Duration(milliseconds: timeInMillis);

    return "${duration.inMinutes} min ${duration.inSeconds.remainder(60)} s "
        "${duration.inMilliseconds.remainder(1000)} ms";
  }

  Color? get colorStatus {
    final statusCode = response?.status ?? 0;
    if (statusCode >= 100 && statusCode < 200) {
      return Colors.grey;
    } else if (statusCode >= 200 && statusCode < 300) {
      return Colors.grey[200];
    } else if (statusCode >= 300 && statusCode < 400) {
      return Colors.blue[200];
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange[200];
    }
    return Colors.red[200];
  }

  String get status {
    if (response == null) return 'Incomplite';
    if (response?.isTimeout ?? false) return 'Timeout';
    if ((response?.status ?? 0) >= 200 && (response?.status ?? 0) < 300) {
      return 'Complete';
    }
    switch (response?.status) {
      case 100:
        return 'Continue';
      case 101:
        return 'Switching Protocols';
      case 102:
        return 'Processing';
      case 103:
        return 'Early Hints';
      case 300:
        return 'Multiple Choices';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found (Previously "Moved Temporarily")';
      case 303:
        return 'See Other';
      case 304:
        return 'Not Modified';
      case 305:
        return 'Use Proxy';
      case 306:
        return 'Switch Proxy';
      case 307:
        return 'Temporary Redirect';
      case 308:
        return 'Permanent Redirect';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 402:
        return 'Payment Required';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 406:
        return 'Not Acceptable';
      case 407:
        return 'Proxy Authentication Required';
      case 408:
        return 'Request Timeout';
      case 409:
        return 'Conflict';
      case 410:
        return 'Gone';
      case 411:
        return 'Length Required';
      case 412:
        return 'Precondition Failed';
      case 413:
        return 'Payload Too Large';
      case 414:
        return 'URI Too Long';
      case 415:
        return 'Unsupported Media Type';
      case 416:
        return 'Range Not Satisfiable';
      case 417:
        return 'Expectation Failed';
      case 418:
        return 'I\'m a Teapot';
      case 421:
        return 'Misdirected Request';
      case 422:
        return 'Unprocessable Entity';
      case 423:
        return 'Locked';
      case 424:
        return 'Failed Dependency';
      case 425:
        return 'Too Early';
      case 426:
        return 'Upgrade Required';
      case 428:
        return 'Precondition Required';
      case 429:
        return 'Too Many Requests';
      case 431:
        return 'Request Header Fields Too Large';
      case 451:
        return 'Unavailable For Legal Reasons';
      case 500:
        return 'Internal Server Error';
      case 501:
        return 'Not Implemented';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      case 505:
        return 'HTTP Version Not Supported';
      case 506:
        return 'Variant Also Negotiates';
      case 507:
        return 'Insufficient Storage';
      case 508:
        return 'Loop Detected';
      case 510:
        return 'Not Extended';
      case 511:
        return 'Network Authentication Required';
      default:
        return 'Unknown';
    }
  }

  String toMessageShare() {
    StringBuffer sb = StringBuffer('Gits Inspector\n\n');
    sb.writeln('Overview');
    sb.writeln('URL: ${Uri.decodeFull(request.url.toString())}');
    sb.writeln('Method: ${request.method}');
    sb.writeln('Status: $status');
    sb.writeln('Response: ${response?.status?.toString() ?? '-'}');
    sb.writeln('SSL: ${isSSL ? 'Yes' : 'No'}');
    sb.writeln('Request Time: ${request.dateTime?.toDateTimeString() ?? '-'}');
    sb.writeln(
        'Response Time: ${response?.dateTime?.toDateTimeString() ?? '-'}');
    sb.writeln('Duration: $duration');
    sb.writeln('Request Size: $requestSize');
    sb.writeln('Response Size: $responseSize');
    sb.writeln('Total Size: $totalSize');
    sb.write('\n');
    sb.writeln('Request');
    request.headers?.forEach(
      (key, value) {
        sb.writeln('$key: $value');
      },
    );
    if (request.body is Map) {
      sb.writeln('Body: ${prettyJson(request.body)}');
    } else {
      sb.writeln('Body: ${request.body?.toString() ?? '-'}');
    }
    if (request.url.queryParameters.isNotEmpty) {
      sb.writeln(
          'Query Parameters: ${prettyJson(request.url.queryParameters)}');
    }
    sb.write('\n');
    sb.writeln('Response');
    response?.headers?.forEach(
      (key, value) {
        sb.writeln('$key: $value');
      },
    );
    if (response?.body is Map) {
      sb.writeln('Body: ${prettyJson(response?.body)}');
    } else {
      sb.writeln('Body: ${response?.body?.toString() ?? '-'}');
    }
    return sb.toString();
  }
}
