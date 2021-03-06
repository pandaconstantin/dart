// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import com.google.common.base.Joiner;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.parser.DartScanner.Position;
import com.google.dart.compiler.resolver.TypeErrorCode;

import junit.framework.TestCase;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;

/**
 * Test for {@link PrettyErrorFormatter}.
 */
public class PrettyErrorFormatterTest extends TestCase {
  private static String RED_BOLD_COLOR = "\033[31;1m";
  private static String RED_COLOR = "\033[31m";
  private static String NO_COLOR = "\033[0m";
  private static final Source SOURCE = new DartSourceTest("my/path/Test.dart",
      Joiner.on("\n").join("lineAAA", "lineBBB", "lineCCC"),
      new MockLibrarySource());

  /**
   * Not a {@link DartSource}, rollback to {@link DefaultErrorFormatter}.
   */
  public void test_notDartSource() throws Exception {
    Source emptyDartSource = new SourceTest("Test.dart") {
      @Override
      public Reader getSourceReader() throws IOException {
        return null;
      }
    };
    Location location = new Location(new Position(-1, 1, 3));
    DartCompilationError error =
        new DartCompilationError(emptyDartSource, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals("Test.dart:1:3: no such type \"Foo\"\n", errorString);
  }

  /**
   * Use {@link DartSource} with source {@link Reader} which throws {@link IOException}, rollback to
   * {@link DefaultErrorFormatter}.
   */
  public void test_throwsIOException() throws Exception {
    Source badDartSource = new DartSourceTest("my/path/Test.dart", "", new MockLibrarySource()) {
      @Override
      public Reader getSourceReader() {
        return new Reader() {
          @Override
          public int read(char[] cbuf, int off, int len) throws IOException {
            throw new IOException("boo!");
          }

          @Override
          public void close() throws IOException {
          }
        };
      }
    };
    Location location = new Location(new Position(-1, 1, 3));
    DartCompilationError error =
        new DartCompilationError(badDartSource, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals("my/path/Test.dart:1:3: no such type \"Foo\"\n", errorString);
  }

  /**
   * Empty {@link DartSource}, rollback to {@link DefaultErrorFormatter}.
   */
  public void test_emptyDartSource() throws Exception {
    Source emptyDartSource = new DartSourceTest("my/path/Test.dart", "", new MockLibrarySource());
    Location location = new Location(new Position(-1, 1, 3));
    DartCompilationError error =
        new DartCompilationError(emptyDartSource, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals("my/path/Test.dart:1:3: no such type \"Foo\"\n", errorString);
  }

  /**
   * Error on first line, so no previous line printed.
   */
  public void test_noColor_notMachine_firstLine() throws Exception {
    Location location = new Location(new Position(3, 1, 3), new Position(6, 1, 6));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        Joiner.on("\n").join(
            "my/path/Test.dart:1: no such type \"Foo\"",
            "     1: lineAAA",
            "          ~~~",
            ""),
        errorString);
  }

  /**
   * {@link Location} with single {@link Position}, underline single character.
   */
  public void test_noColor_notMachine_singlePosition() throws Exception {
    Location location = new Location(new Position(-1, 2, 3));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        Joiner.on("\n").join(
            "my/path/Test.dart:2: no such type \"Foo\"",
            "     1: lineAAA",
            "     2: lineBBB",
            "          ~~~~~",
            ""),
        errorString);
  }

  /**
   * {@link Location} with single {@link Position}, underline single character.
   */
  public void test_withColor_notMachine_singlePosition() throws Exception {
    Location location = new Location(new Position(-1, 2, 3));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, true, false);
    assertEquals(
        Joiner.on("\n").join(
            RED_BOLD_COLOR + "my/path/Test.dart:2: no such type \"Foo\"" + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + RED_COLOR + "neBBB" + NO_COLOR,
            ""),
        errorString);
  }

  /**
   * Underline range of characters.
   */
  public void test_noColor_notMachine() throws Exception {
    Location location = new Location(new Position(8 + 3, 2, 3), new Position(8 + 6, 2, 6));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        Joiner.on("\n").join(
            "my/path/Test.dart:2: no such type \"Foo\"",
            "     1: lineAAA",
            "     2: lineBBB",
            "          ~~~",
            ""),
        errorString);
  }

  /**
   * Use color to highlight range of characters.
   */
  public void test_withColor_notMachine() throws Exception {
    Location location = new Location(new Position(8 + 3, 2, 3), new Position(8 + 6, 2, 6));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, true, false);
    assertEquals(
        Joiner.on("\n").join(
            RED_BOLD_COLOR + "my/path/Test.dart:2: no such type \"Foo\"" + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + RED_COLOR + "neB" + NO_COLOR + "BB",
            ""),
        errorString);
  }

  /**
   * Include all information about error context.
   */
  public void test_noColor_forMachine() throws Exception {
    Location location = new Location(new Position(8 + 3, 2, 3), new Position(8 + 7, 2, 7));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, true);
    assertEquals(
        Joiner.on("\n").join(
            "WARNING:STATIC_TYPE:NO_SUCH_TYPE:my/path/Test.dart:2:3:4: no such type \"Foo\"",
            "     1: lineAAA",
            "     2: lineBBB",
            "          ~~~~",
            ""),
        errorString);
  }

  /**
   * Use color to highlight range of characters. Include all information about error context.
   */
  public void test_withColor_forMachine() throws Exception {
    Location location = new Location(new Position(8 + 3, 2, 3), new Position(8 + 7, 2, 7));
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, true, true);
    assertEquals(
        Joiner.on("\n").join(
            RED_BOLD_COLOR
                + "WARNING:STATIC_TYPE:NO_SUCH_TYPE:my/path/Test.dart:2:3:4: no such type \"Foo\""
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + RED_COLOR + "neBB" + NO_COLOR + "B",
            ""),
        errorString);
  }

  /**
   * @return output produced by {@link PrettyErrorFormatter}.
   */
  private String getErrorString(DartCompilationError error,
      boolean useColor,
      boolean printMachineProblems) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    PrintStream printStream = new PrintStream(outputStream);
    ErrorFormatter errorFormatter =
        new PrettyErrorFormatter(printStream, useColor, printMachineProblems);
    errorFormatter.format(error);
    return outputStream.toString();
  }
}
