// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListInputStream implements InputStream {
  List<int> read() {
    var result = _data;
    _data = null;
    return result;
  }

  void set dataHandler(void callback()) {
    _dataHandler = callback;
  }

  void set closeHandler(void callback()) {
    _closeHandler = callback;
  }

  void set errorHandler(void callback(int error)) {
  }

  void write(List<int> data) {
    Expect.equals(null, _data);
    _data = data;
    if (_dataHandler != null) {
      // Data handler is not called through the event loop here.
      _dataHandler();
    }
  }

  void close() {
    Expect.equals(null, _data);
    // Close handler is not called through the event loop here.
    if (_closeHandler != null) _closeHandler();
  }

  List<int> _data;
  var _dataHandler;
  var _closeHandler;
}

void test1() {
  void testWithChunkSize(var data, int chunkSize, Function testDone) {
    InputStream s = new ListInputStream();
    ChunkedInputStream stream = new ChunkedInputStream(s);
    int chunkCount = 0;
    int byteCount = 0;
    void chunkData() {
      List<int> chunk = stream.read();
      if (byteCount + chunkSize < data.length) {
        Expect.equals(chunkSize, chunk.length);
      } else {
        if (byteCount == data.length) {
          Expect.equals(null, chunk);
        } else {
          Expect.equals(data.length - byteCount, chunk.length);
        }
      }
      if (chunk != null) {
        for (int i = 0; i < chunk.length;i++) {
          Expect.equals(data[byteCount], chunk[i]);
          byteCount++;
        }
        chunkCount++;
      }
    }

    void closeHandler() {
      Expect.equals(data.length, byteCount);
      testDone(byteCount);
    }

    stream.dataHandler = chunkData;
    stream.closeHandler = closeHandler;
    stream.chunkSize = chunkSize;
    s.write(data);
    s.close();
  }

  for (int i = 1; i <= 10; i++) {
    var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    void testDone(int byteCount) {
      Expect.equals(data.length, byteCount);
    }

    testWithChunkSize(data, i, testDone);
  }

  var _16k = 1024 * 16;
  var data = new List<int>(_16k);
  for (int i = 0; i < _16k; i++) { data[i] = i % 256; }

  void testDone(int byteCount) {
    Expect.equals(data.length, byteCount);
  }

  testWithChunkSize(data, 512, testDone);
  testWithChunkSize(data, 1024, testDone);
  testWithChunkSize(data, 2048, testDone);
}


void test2() {
  InputStream s = new ListInputStream();
  ChunkedInputStream stream = new ChunkedInputStream(s);
  stream.chunkSize = 5;

  var stage = 0;

  void chunkData() {
    var chunk;
    if (stage == 0) {
      Expect.equals(stream.chunkSize, 5);
      chunk = stream.read();  // 5 bytes read from stream.
      Expect.equals(stream.chunkSize, chunk.length);
      chunk = stream.read();  // 5 bytes read from stream.
      Expect.equals(null, chunk);
      stage++;
      s.write([7, 8, 9]);  // 10 bytes written to stream.
    } else if (stage == 1) {
      Expect.equals(stream.chunkSize, 5);
      chunk = stream.read();  // 10 bytes read from stream.
      Expect.equals(stream.chunkSize, chunk.length);
      chunk = stream.read();  // 10 bytes read from stream.
      Expect.equals(null, chunk);
      stage++;
      s.write([10, 11, 12, 13, 14]);  // 15 bytes written to stream.
      s.write([15, 16, 17, 18]);  // 19 bytes written to stream.
    } else if (stage == 2) {
      Expect.equals(stream.chunkSize, 5);
      chunk = stream.read();  // 15 bytes read from stream.
      Expect.equals(stream.chunkSize, chunk.length);
      chunk = stream.read();  // 15 bytes read from stream.
      Expect.equals(null, chunk);
      stage++;
      stream.chunkSize = 3;
    } else if (stage == 3) {
      Expect.equals(stream.chunkSize, 3);
      chunk = stream.read();  // 18 bytes read from stream.
      Expect.equals(stream.chunkSize, chunk.length);
      chunk = stream.read();  // 18 bytes read from stream.
      Expect.equals(null, chunk);
      stage++;
      s.close();  // 18 bytes written to stream.
    } else if (stage == 4) {
      chunk = stream.read();  // 19 bytes read from stream.
      Expect.equals(1, chunk.length);
      chunk = stream.read();  // 19 bytes read from stream.
      Expect.equals(null, chunk);
      stage++;
    }
  }

  void streamClosed() {
    Expect.equals(5, stage);
  }

  stream.dataHandler = chunkData;
  stream.closeHandler = streamClosed;
  s.write([0, 1, 2, 3]);  // 4 bytes written to stream.
  Expect.equals(0, stage);
  s.write([4, 5, 6]);  // 7 bytes written to stream.
  Expect.equals(4, stage);
}


main() {
  test1();
  test2();
}
