# Orcam - A Collection of Useful Swift Macros

This is a collection of useful Swift macros

## Prerequisites

- Xcode 15 or higher
- Swift 5.9

## Installation

### Swift Package Manager

Once you have your Swift package set up, adding `orcam` as a dependency to the `dependencies` value in `Package.swift`.

```swift
.package(url: "https://github.com/trinhngocthuyen/orcam", from: "0.0.1")
```

Then, add `Orcam` module product as a dependency of a `target`'s `dependencies`.
```swift
.product(name: "Orcam", package: "orcam")
```

## Features

### `@Init` - Generate the member-wise `init` of a struct/class

```swift
@Init
class Foo {
  let x: Int
  let y: Double?
  let completion: () -> Void
}
```

<details>
  <summary>Expanded code</summary>

```swift
class Foo {
  let x: Int
  let y: Double?
  let completion: () -> Void

  init(x: Int, y: Double? = nil, completion: @escaping () -> Void) {
    self.x = x
    self.y = y
    self.completion = completion
  }
}
```
</details>

### `@Singleton` - Generate the Singleton code of a struct/class

```swift
@Singleton
class Foo {
}
```

<details>
  <summary>Expanded code</summary>

```swift
class Foo {
  static let shared = Foo()

  private init() {
  }
}
```
</details>

The macro still works when we explicitly declare the `shared` variable.

```swift
@Singleton
class Foo {
  let x: Int

  static let shared = Foo(x: 0)
}
```

### `@Copyable` - Generate the `copy` function of a struct/class with updated properties

```swift
@Copyable
struct Foo {
  let x: Int
  let y: Int
}
```

<details>
  <summary>Expanded code</summary>

```swift
struct Foo {
  let x: Int
  let y: Int

  func copy(x: Int? = nil, y: Int? = nil) -> Self {
    return .init(x: x ?? self.x, y: y ?? self.y)
  }
}
```
</details>

This macro also generates a `copy` function in which each property can be updated with a closure. To enable this, pass the argument `closure` as `true` to the macro.

```swift
@Copyable(closure: true)
struct Foo {
  let x: Int
  let y: Int
}
```

<details>
  <summary>Expanded code</summary>

```swift
struct Foo {
  let x: Int
  let y: Int

  func copy(x: Int? = nil, y: Int? = nil) -> Self {
    return .init(x: x ?? self.x, y: y ?? self.y)
  }

  func copy(update_x: ((Int) -> Int)? = nil, update_y: ((Int) -> Int)? = nil) -> Self {
    func call<V>(_ f: ((V) -> V)?, _ v: V) -> V {
      f?(v) ?? v
    }
    return .init(x: call(update_x, self.x), y: call(update_y, self.y))
  }
}
```
</details>
