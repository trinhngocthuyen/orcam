import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import OrcamImpl

final class InitMacroTests: BaseMacroTests {
  private var testMacros: [String: Macro.Type] { ["Init": InitMacro.self] }

  func testMacroForClass() {
    assertMacroExpansion(
      """
      @Init
      class Foo {
        var x: Int = 0 {
          didSet { }
        }
        var y: Bool { false }
        let z: Int = 0
        let completion: () -> Void
      }
      """,
      expandedSource:
      """
      class Foo {
        var x: Int = 0 {
          didSet { }
        }
        var y: Bool { false }
        let z: Int = 0
        let completion: () -> Void

        init(
          x: Int,
          completion: @escaping () -> Void
        ) {
          self.x = x
          self.completion = completion
        }
      }
      """
    )
  }

  func testDefaultForOptional() {
    assertMacroExpansion(
      """
      @Init
      class Foo {
        let x: Double?
        let y: Optional<Double>
      }
      """,
      expandedSource:
      """
      class Foo {
        let x: Double?
        let y: Optional<Double>

        init(
          x: Double? = nil,
          y: Optional<Double> = nil
        ) {
          self.x = x
          self.y = y
        }
      }
      """
    )

    assertMacroExpansion(
      """
      @Init(defaultForOptional: false)
      class Foo {
        let x: Double?
        let y: Optional<Double>
      }
      """,
      expandedSource:
      """
      class Foo {
        let x: Double?
        let y: Optional<Double>

        init(
          x: Double?,
          y: Optional<Double>
        ) {
          self.x = x
          self.y = y
        }
      }
      """
    )
  }

  func testWithPropertyWrapper() {
    assertMacroExpansion(
      """
      @Init
      class Foo {
        final class VM: ObservableObject {}

        @State var x: Int
        @StateObject var vm: VM
      }
      """,
      expandedSource:
      """
      class Foo {
        final class VM: ObservableObject {}

        @State var x: Int
        @StateObject var vm: VM

        init(
          x: Int,
          vm: VM
        ) {
          self._x = .init(wrappedValue: x)
          self._vm = .init(wrappedValue: vm)
        }
      }
      """
    )
  }
}
