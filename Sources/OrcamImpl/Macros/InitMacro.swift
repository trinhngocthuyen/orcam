import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

enum InitMacroHelper {
  static func initializerParameters(of declaration: some DeclGroupSyntax) -> [FunctionParameter] {
    let group = DeclGroup(declaration)
    return group.variables
      .filter { $0.isStoredProperty && !$0.isConstant }
      .flatMap {
        $0.bindings.compactMap { binding in
          binding.asFunctionParameter?.withoutTrivia()
        }
      }
  }

  static func propertyWrapperVariables(of declaration: some DeclGroupSyntax) -> [String] {
    let group = DeclGroup(declaration)
    return group.variables.filter(\.isPropertyWrapper).flatMap(\.identifiers)
  }
}

public struct InitMacro: BaseMemberMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext,
    arguments overridenArguments: [String: Any]
  ) throws -> [DeclSyntax] {
    try declaration.expectKind(.classDecl, .structDecl)
    let arguments = try MacroArguments(from: node.asMacroAttribute, overriden: overridenArguments)
    let defaultForOptional = arguments.value(for: "defaultForOptional", default: true)
    let accessLevel = arguments.value(for: "accessLevel", default: declaration.accessLevel ?? "")

    let propertyWrapperVariables = InitMacroHelper.propertyWrapperVariables(of: declaration)
    let parameters = InitMacroHelper.initializerParameters(of: declaration)
      .map(\.withEscapingAttribute)
      .map { defaultForOptional ? $0.withDefaultValueForOptional : $0 }
    let initDeclSyntax = try InitializerDeclSyntax("init()") {
      for parameter in parameters {
        if propertyWrapperVariables.contains(parameter.name) {
          "self._\(raw: parameter.name) = .init(wrappedValue: \(raw: parameter.name))"
        } else {
          "self.\(raw: parameter.name) = \(raw: parameter.name)"
        }
      }
    }
    .withParameters(parameters)
    .withAccessLevel(accessLevel)
    return [
      initDeclSyntax.asDeclSyntax,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try expansion(
      of: node,
      providingMembersOf: declaration,
      in: context,
      arguments: [:]
    )
  }
}
