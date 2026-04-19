import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class ModelViewerWidget extends StatefulWidget {
  final String modelPath;
  final String backgroundColor;
  
  const ModelViewerWidget({
    super.key,
    required this.modelPath,
    this.backgroundColor = '#FFF5E8',
  });

  @override
  State<ModelViewerWidget> createState() => _ModelViewerWidgetState();
}

class _ModelViewerWidgetState extends State<ModelViewerWidget> {
  late WebViewController _webViewController;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('BlobLoader', onMessageReceived: (JavaScriptMessage message) {
        // Handle messages from JavaScript if needed
      });
    
    _loadFuture = _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // Load the GLB file as binary data
      final bytes = await rootBundle.load(widget.modelPath);
      final byteList = bytes.buffer.asUint8List();
      
      // Load the HTML page first
      await _webViewController.loadHtmlString(_getHtmlString());
      
      // Wait for the page to load
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Send the binary data as base64 to JavaScript to create a blob URL
      // Split into chunks to avoid size limits
      final chunkSize = 100000;
      final totalChunks = (byteList.length / chunkSize).ceil();
      
      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (i + 1) * chunkSize > byteList.length ? byteList.length : (i + 1) * chunkSize;
        final chunk = byteList.sublist(start, end);
        final base64Chunk = base64Encode(chunk);
        
        await _webViewController.runJavaScript('''
          window.modelChunks = window.modelChunks || [];
          window.modelChunks.push('$base64Chunk');
          if (window.modelChunks.length === $totalChunks) {
            loadModelFromChunks($totalChunks);
          }
        ''');
      }
    } catch (e) {
      print('Error loading model: \$e');
      rethrow;
    }
  }

  String _getHtmlString() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script type="module" src="https://unpkg.com/@google/model-viewer@4.2.0/dist/model-viewer.min.js"></script>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        html, body {
          width: 100%;
          height: 100%;
          background-color: ${widget.backgroundColor};
          font-family: sans-serif;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        model-viewer {
          width: 100%;
          height: 100%;
          background-color: ${widget.backgroundColor};
        }
      </style>
    </head>
    <body>
      <model-viewer
        id="viewer"
        alt="3D Baby Model"
        auto-rotate
        camera-controls
        touch-action="pan-y"
        style="width:100%; height:100%; background-color:${widget.backgroundColor};">
      </model-viewer>
      
      <script>
        window.modelChunks = [];
        
        function loadModelFromChunks(totalChunks) {
          // Combine all chunks
          const base64Data = window.modelChunks.join('');
          
          // Convert base64 to binary
          const binaryString = atob(base64Data);
          const bytes = new Uint8Array(binaryString.length);
          for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
          }
          
          // Create blob from binary data
          const blob = new Blob([bytes], { type: 'model/gltf-binary' });
          const blobUrl = URL.createObjectURL(blob);
          
          // Set the model src to the blob URL
          const viewer = document.getElementById('viewer');
          if (viewer) {
            viewer.src = blobUrl;
          }
        }
      </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: \${snapshot.error}'),
          );
        }
        return WebViewWidget(controller: _webViewController);
      },
    );
  }

  String base64Encode(List<int> bytes) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    StringBuffer result = StringBuffer();
    int i = 0;
    while (i < bytes.length) {
      int b1 = bytes[i++];
      int b2 = i < bytes.length ? bytes[i++] : 0;
      int b3 = i < bytes.length ? bytes[i++] : 0;

      bool haveb2 = i - 2 < bytes.length;
      bool haveb3 = i - 1 < bytes.length;

      int bitmap = (b1 << 16) | (b2 << 8) | b3;
      result.write(chars[(bitmap >> 18) & 63]);
      result.write(chars[(bitmap >> 12) & 63]);
      if (haveb2) {
        result.write(chars[(bitmap >> 6) & 63]);
      } else {
        result.write("=");
      }
      if (haveb3) {
        result.write(chars[bitmap & 63]);
      } else {
        result.write("=");
      }
    }
    return result.toString();
  }
}
