// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A collection of helper io functions implemented using node.js.
 *
 * Idea is to clone the node.js API as closely as possible while adding types.
 * Dart libraries on top of this will experiment with different APIs.
 */
#library('node');

var createSandbox() native
  """return {'require': require, 'process': process, 'console': console,
      'setTimeout': setTimeout, 'clearTimeout': clearTimeout};""";

typedef void RequestListener(ServerRequest request, ServerResponse response);

// TODO(nweiz): properly title-case these class names

class http native "require('http')" {
  static Server createServer(RequestListener listener) native;
}

class Server native "http.Server" {
  void listen(int port, [String hostname, Function callback]) native;
}

class ServerRequest native "http.IncomingMessage" {
  final String method;
  final String url;
  final Map<String, String> headers;
  final String httpVersion;

  void setEncoding([String encoding]) {}
}

class ServerResponse native "http.ServerResponse" {
  int statusCode;

  void setHeader(String name, String value) native;

  String getHeader(String name) native;

  void removeHeader(String name) native;

  void write(String data, [String encoding = 'utf8']) native;

  void end([String data, String encoding = 'utf8']) native;
}

class Console native "=console" {
  // TODO(jimhug): Map node.js's ability to take multiple args to what?
  void log(String text) native;
  void info(String text) native;
  void warn(String text) native;
  void error(String text) native;
}

// TODO(jmesserly): fix this so it can be a field
Console get console() native 'return console';

class process native "process" {
  static List<String> argv;
  // TODO(nweiz): add Stream type information
  static stdin;
  static stdout;

  static void exit([int code = 0]) native;
  static String cwd() native;
}

class vm native "require('vm')" {
  static void runInThisContext(String code, [String filename]) native;
  static void runInNewContext(String code, [var sandbox, String filename])
    native;
  static Script createScript(String code, [String filename]) native;
  static Context createContext([sandbox]) native;
  static runInContext(String code, Context context, [String filename]) native;
}

interface Context {}

class Script native "vm.Script" {
  void runInThisContext() native;
  void runInNewContext([Map sandbox]) native;
}

class fs native "require('fs')" {
  static void writeFileSync(String outfile, String text) native;

  static String readFileSync(String filename, [String encoding = 'utf8'])
    native;

  static String realpathSync(String path) native;

  static void mkdirSync(String path, [num mode = 511 /* 0777 octal */]) native;
  static List<String> readdirSync(String path) native;
  static void rmdirSync(String path) native;
  static Stats statSync(String path) native;
  static void unlinkSync(String path) native;
}

class Stats native "fs.Stats" {
  bool isFile() native;
  bool isDirectory() native;
  bool isBlockDevice() native;
  bool isCharacterDevice() native;
  bool isSymbolicLink() native;
  bool isFIFO() native;
  bool isSocket() native;

  // TODO(rnystrom): There are also the other fields we can add here if needed.
  // See: http://nodejs.org/docs/v0.6.1/api/fs.html#fs.Stats.
}

class path native "require('path')" {
  static bool existsSync(String filename) native;
  static String dirname(String path) native;
  static String basename(String path) native;
  static String extname(String path) native;
  static String normalize(String path) native;
  // TODO(jimhug): Get the right signatures for normalizeArray and join
}

class Readline native "require('readline')" {
  static ReadlineInterface createInterface(input, output) native;
}

class ReadlineInterface native "Readline.Interface" {
  void setPrompt(String prompt, [int length]) native;
  void prompt() native;
  void on(String event, Function callback) native;
}

interface TimeoutId {}

TimeoutId setTimeout(Function callback, num delay, [arg]) native;
clearTimeout(TimeoutId id) native;
