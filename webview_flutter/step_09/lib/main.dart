import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MaterialApp(home: WebViewExample()));

class WebViewExample extends StatefulWidget {
  const WebViewExample({Key? key}) : super(key: key);

  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  final _controller = Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter WebView example'),
        actions: [
          NavigationControls(_controller.future),
          Menu(_controller.future),
        ],
      ),
      body: WebView(
        initialUrl: 'https://flutter.dev',
        onWebViewCreated: (webViewController) {
          _controller.complete(webViewController);
        },
        onPageStarted: (url) {
          print('Page started loading: $url');
        },
        onProgress: (progress) {
          print('WebView is loading (progress : $progress%)');
        },
        onPageFinished: (url) {
          print('Page finished loading: $url');
        },
        navigationDelegate: (request) {
          if (request.url.startsWith('https://m.youtube.com/')) {
            print('blocking navigation to $request}');
            return NavigationDecision.prevent;
          }
          print('allowing navigation to $request');
          return NavigationDecision.navigate;
        },
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture, {Key? key})
      : super(key: key);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder: (context, snapshot) {
        final webViewReady = snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        if (!webViewReady || controller == null) {
          return Row(
            children: const <Widget>[
              Icon(Icons.arrow_back_ios),
              Icon(Icons.arrow_forward_ios),
              Icon(Icons.replay),
            ],
          );
        }

        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () async {
                if (await controller.canGoBack()) {
                  await controller.goBack();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No back history item')),
                  );
                  return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () async {
                if (await controller.canGoForward()) {
                  await controller.goForward();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No forward history item')),
                  );
                  return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () {
                controller.reload();
              },
            ),
          ],
        );
      },
    );
  }
}

enum _MenuOptions {
  navigationDelegate,
  userAgent,
}

class Menu extends StatelessWidget {
  const Menu(this.controller);

  final Future<WebViewController> controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder: (context, controller) {
        return PopupMenuButton<_MenuOptions>(
          onSelected: (value) async {
            switch (value) {
              case _MenuOptions.navigationDelegate:
                controller.data!.loadUrl('https://m.youtube.com');
                break;
              case _MenuOptions.userAgent:
                final userAgent = await controller.data!
                    .runJavascriptReturningResult('navigator.userAgent');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(userAgent),
                ));
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<_MenuOptions>(
              value: _MenuOptions.navigationDelegate,
              child: Text('Navigation Delegate Example'),
            ),
            const PopupMenuItem<_MenuOptions>(
              value: _MenuOptions.userAgent,
              child: Text('Show user-agent'),
            ),
          ],
        );
      },
    );
  }
}
