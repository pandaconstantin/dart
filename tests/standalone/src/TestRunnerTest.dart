
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("TestRunnerTest");


#import("../../../tools/testing/dart/test_runner.dart");

// TODO(whesse) source("ProcessTestUtil.dart"); when it is committed.

class TestController {
  static final int numTests = 4;
  static int numCompletedTests = 0;

  // Used as TestCase.completedCallback.
  static processCompletedTest(TestCase testCase) {
    TestOutput output = testCase.output;
    print("Test: ${testCase.commandLine}");
    if (output.unexpectedOutput) {
      print("Unexpected output: ${output.result}");
    }
    print("stdout: ");
    for (var line in output.stdout) print(line);
    print("stderr: ");
    for (var line in output.stderr) print(line);
    
    print("Time: ${output.time}");
    print("Exit code: ${output.exitCode}");

    ++numCompletedTests;
    print("$numCompletedTests/$numTests");
    if (numCompletedTests == numTests) {
      print("TestRunnerTest.dart PASSED");
    }
  }
}

TestCase MakeTestCase(String testName, List<String> expectations) {
  return new TestCase(getDartShellFileName(), <String>[
                      "--ignore-unrecognized-flags",
                      "--enable_type_checks",
                      "tests/standalone/src/${testName}.dart"],
                      TestController.processCompletedTest,
                      new Set<String>.from(expectations));
}

void main() {
  new RunningProcess(MakeTestCase("PassTest", [PASS]), 30).start();
  new RunningProcess(MakeTestCase("FailTest", [FAIL]), 30).start();
  new RunningProcess(MakeTestCase("TimeoutTest", [TIMEOUT]), 30).start();

  // TODO(whesse): Replace process_test with getProcessTestFileName().
  new RunningProcess(new TestCase("out/Debug_ia32/process_test",
                                  const ["0", "0", "1", "1"],
                                  TestController.processCompletedTest,
                                  new Set<String>.from([CRASH])),
                     30).start();
  Expect.equals(4, TestController.numTests);
  // Throw must be from body of start() function for this test to work.
  Expect.throws(
      new RunningProcess(MakeTestCase("PassTest", [SKIP]), 30).start);
}

