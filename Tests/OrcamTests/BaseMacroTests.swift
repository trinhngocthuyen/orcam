import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import OrcamImpl

class BaseMacroTests: XCTestCase {
  func assertMacroExpansion(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let macros = Dictionary(
      uniqueKeysWithValues: OrcamPlugin().providingMacros.map { m -> (String, Macro.Type) in
        ("\(m)".replacing("Macro", with: ""), m)
      }
    )
    SwiftSyntaxMacrosTestSupport.assertMacroExpansion(
      originalSource,
      expandedSource: expectedExpandedSource,
      macros: macros,
      indentationWidth: .spaces(2),
      file: file,
      line: line
    )
  }
}
