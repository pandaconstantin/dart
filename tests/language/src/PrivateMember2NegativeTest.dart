// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('PrivateMemberLibA');

#import('PrivateMember2LibB.dart');

class A {}

class Test extends B {
  test() {
    _staticField = true;
  }
}

void main() {
  new Test().test();
}