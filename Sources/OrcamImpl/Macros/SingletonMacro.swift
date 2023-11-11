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
    let group = DeclGroup(declaration)
    let entityName = declaration.entityName?.text ?? "Self"
    let accessLevelWithTrailingSpacing = DeclGroup(declaration).accessLevel?.withTrailingSpacing ?? ""
    let sharedVariableDeclSyntax = DeclSyntax(
      stringLiteral: "\(accessLevelWithTrailingSpacing)static let shared = \(entityName)()"
    )
    let syntaxes = group.containsVariable(name: "shared") ? [] : [sharedVariableDeclSyntax]
    return try syntaxes + InitMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      in: context,
      arguments: ["accessLevel": "private"]
    )
  }
}
