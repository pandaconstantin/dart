// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_options_parser");

/**
 * Specification of a single test option.
 *
 * The name of the specification is used as the key for the option in
 * the Map returned from the [TestOptionParser] parse method.
 */
class _TestOptionSpecification {
  _TestOptionSpecification(this.name,
                           this.description,
                           this.keys,
                           this.values,
                           this.defaultValue,
                           [this.type = 'string']);
  String name;
  String description;
  List<String> keys;
  List<String> values;
  String defaultValue;
  String type;
}


/**
 * Parser of test options.
 */
class TestOptionsParser {
  /**
   * Creates a test options parser initialized with the known options.
   */
  TestOptionsParser() {
    _options =
        [ new _TestOptionSpecification(
              'mode',
              'Mode in which to run the tests',
              ['-m', '--mode'],
              ['all', 'debug', 'release'],
              'debug'),
          new _TestOptionSpecification(
              'component',
              'The component to test against',
              ['-c', '--component'],
              ['most', 'vm', 'dartc', 'chromium', 'dartium'],
              'vm'),
          new _TestOptionSpecification(
              'architecture',
              'The architecture to run tests for',
              ['-a', '--arch'],
              ['all', 'ia32', 'x64', 'simarm', 'arm'],
              'ia32'),
          new _TestOptionSpecification(
              'os',
              'The operating system to run tests on',
              ['-o', '--os'],
              ['linux', 'macos', 'windows'],
              new Platform().operatingSystem()),
          new _TestOptionSpecification(
              'checked',
              'Run tests in checked mode',
              ['--checked'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'tasks',
              'The number of parallel tasks to run',
              ['-j', '--tasks'],
              [],
              new Platform().numberOfProcessors(),
              'int'),
          new _TestOptionSpecification(
              'help',
              'Print list of options',
              ['-h', '--help'],
              [],
              false,
              'bool')];
  }


  /**
   * Parse a list of strings as test options.
   *
   * Returns a Map mapping from option keys to values. When
   * encountering the first non-option string, the rest of the
   * arguments are stored in the returned Map under the 'rest' key.
   */
  Map parse(List<String> arguments) {
    var configuration = new Map();
    // Build configuration of default values.
    for (var option in _options) {
      configuration[option.name] = option.defaultValue;
    }
    // Overwrite with the arguments passed to the test script.
    var numArguments = arguments.length;
    for (var i = 0; i < numArguments; i++) {
      // Extract name and value for options.
      var arg = arguments[i];
      var name = '';
      var value = '';
      if (arg.startsWith('--')) {
        if (arg == '--help') {
          _printHelp();
          return null;
        }
        var split = arg.lastIndexOf('=');
        name = arg;
        value = '';
        if (split != -1) {
          name = arg.substring(0, split);
          value = arg.substring(split + 1, arg.length);
        }
      } else if (arg.startsWith('-')) {
        if (arg == '-h') {
          _printHelp();
          return null;
        }
        name = arg;
        if ((i + 1) >= arguments.length) {
          print('No value supplied for option $name');
          return null;
        }
        value = arguments[++i];
      } else {
        // The option name does not start with '-' or '--' so we
        // assume that the rest of the arguments specify tests or test
        // suites to run.
        configuration['rest'] = arguments.getRange(i, numArguments - i);
        return configuration;
      }
      // Find the option specification for the name.
      var spec = _getSpecification(name);
      if (spec == null) {
        print('Unknown test option $name');
        return null;
      }
      // Parse the value for the option.
      if (spec.type == 'bool') {
        if (!value.isEmpty()) {
          print('No value expected for bool option $name');
          return null;
        }
        configuration[spec.name] = true;
      } else if (spec.type == 'int') {
        try {
          configuration[spec.name] = Math.parseInt(value);
        } catch (var e) {
          print('Integer value expected for int option $name');
          return null;
        }
      } else {
        assert(spec.type == 'string');
        if (spec.values.lastIndexOf(value) == -1) {
          print('Unknown value ($value) for option $name');
          return null;
        }
        configuration[spec.name] = value;
      }
    }

    return configuration;
  }


  /**
   * Print out usage information.
   */
  void _printHelp() {
    print('usage: dart_bin test.dart [options]\n');
    print('Options:\n');
    for (var option in _options) {
      print('${option.name}: ${option.description}.');
      for (var name in option.keys) {
        assert(name.startsWith('-'));
        var buffer = new StringBuffer();;
        buffer.add(name);
        if (option.type == 'bool') {
          assert(option.values.empty());
        } else {
          buffer.add(name.startsWith('--') ? '=' : ' ');
          if (option.type == 'int') {
            assert(option.values.empty());
            buffer.add('n (default: ${option.defaultValue})');
          } else {
            buffer.add('[');
            bool first = true;
            for (var value in option.values) {
              if (!first) buffer.add(", ");
              if (value == option.defaultValue) buffer.add('*');
              buffer.add(value);
              first = false;
            }
            buffer.add(']');
          }
        }
        print(buffer.toString());
      }
      print('');
    }
  }


  /**
   * Find the test option specification for a given option key.
   */
  _TestOptionSpecification _getSpecification(String name) {
    for (var option in _options) {
      if (option.keys.some((key) => key == name)) {
        return option;
      }
    }
    return null;
  }


  List<_TestOptionSpecification> _options;
}
