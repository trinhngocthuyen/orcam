import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct SingletonMacro: BaseMemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try declaration.expectKind(.classDecl, .structDecl)
    let entityName = declaration.entityName?.text ?? "Self"
    let accessLevelWithTrailingSpacing = DeclGroup(declaration).accessLevel?.withTrailingSpacing ?? ""

    // TODO: Reuse init declaration from InitMacro

    return [
      DeclSyntax(
        stringLiteral: "\(accessLevelWithTrailingSpacing)static let shared = \(entityName)()"
      ),
      try InitializerDeclSyntax(
        accessLevel: "private",
        literals: []
      ).asDeclSyntax,
    ]
  }
}
