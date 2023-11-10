import SwiftSyntax
import SwiftSyntaxBuilder
import MacroToolkit

extension DeclGroup {
  var variables: [Variable] {
    members.compactMap { $0.asVariable }
  }
}

extension Type {
  var isOptional: Bool {
    description.hasPrefix("Optional<") || description.hasSuffix("?")
  }
}

extension Variable {
  var isLet: Bool {
    _syntax.bindingSpecifier.tokenKind == .keyword(.let)
  }

  var isConstant: Bool {
    isLet && bindings.contains { $0.initialValue != nil }
  }
}
