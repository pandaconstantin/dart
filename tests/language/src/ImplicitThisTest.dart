// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Interface {
  final x;
}

// The abstract keyword is implicit if a class declares an abstract
// member. This class does not declare any abstract members, so it
// must be marked abstract because it doesn't implement the x getter.
abstract class Abstract implements Interface {
  String toString() => x.toString();
}

// This class does not implement "x" either, but it is not marked
// abstract.
class SubAbstract1 extends Abstract { } /// 01: static type error

// This class is implicitly abstract as it declares an abstract getter
// method.
class SubAbstract2 extends Abstract {
  abstract get x();
}

// This class does not implement "x" either, but it is not marked
// abstract.
class SubSubAbstract2 extends SubAbstract2 { } /// 04: static type error

class Concrete extends Abstract {
  get x() => 7;
}

class SubConcrete extends Concrete {
  final x;
  SubConcrete(this.x);
}

void main() {
  var x = new Abstract(); /// 02: static type error
  var y = new SubAbstract1(); /// 01: continued
  var z = new SubAbstract2(); /// 03: static type error
  var a = new SubSubAbstract2(); /// 04: continued
  Expect.equals(x, x); /// 02: continued
  Expect.equals('7', new Concrete().toString());
  Expect.equals('42', new SubConcrete(42).toString());
  Expect.equals('7', new SubConcrete(new Concrete()).toString());
}
