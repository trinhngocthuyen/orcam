import SwiftSyntax
import SwiftSyntaxBuilder


extension DeclGroupSyntax {
  func isPublic() -> Bool {
    guard let keywords = (self as? WithModifiersSyntax)?.getKeywords() else { return false }
    return keywords.contains(.public) || keywords.contains(.open)
  }

  func storedProperties() -> [VariableDeclSyntax] {
    memberBlock.members.compactMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self), !variable.isComputedProperty else { return nil }
      return variable
    }
  }
}

extension WithModifiersSyntax {
  func getKeywords() -> [Keyword] {
    modifiers.compactMap { $0.name.keyword }
  }
}

extension VariableDeclSyntax {
  var isInitialized: Bool {
    bindings.first?.initializer != nil
  }

  var isConstant: Bool {
    isInitialized && bindingSpecifier.tokenKind == .keyword(.let)
  }

  var isComputedProperty: Bool {
    guard let accessors = bindings.first?.accessorBlock?.accessors else { return false }
    switch accessors {
    case .accessors(let node):
      return !node.contains {
        let kw = $0.accessorSpecifier.keyword
        return kw == .willSet || kw == .didSet
      }
    case .getter:
      return true
    }
  }
}

extension TokenSyntax {
  var keyword: Keyword? {
    if case let .keyword(kw) = tokenKind { return kw }
    return nil
  }
}

extension SyntaxExpressibleByStringInterpolation {
  init(format: String, _ arguments: CVarArg...) {
    self.init(stringLiteral: String(format: format, arguments))
  }
}

extension AttributeSyntax {
  func labeledArguments() -> [String: LabeledExprSyntax] {
    guard let args = arguments?.as(LabeledExprListSyntax.self) else { return [:] }
    return Dictionary(uniqueKeysWithValues: args.map { ($0.label?.text ?? "", $0) })
  }

  func getArgument<Value>(name: String, default: Value) throws -> Value {
    guard let argument = labeledArguments()[name] else { return `default` }
    switch `default` {
    case is Bool:
      if let literal = argument.expression.as(BooleanLiteralExprSyntax.self)?.literal.text,
         let value = Bool(literal) {
        return value as! Value
      }
    case is Int:
      if let literal = argument.expression.as(IntegerLiteralExprSyntax.self)?.literal.text,
         let value = Int(literal) {
        return value as! Value
      }
    case is Float, is Double:
      if let literal = argument.expression.as(FloatLiteralExprSyntax.self)?.literal.text,
         let value = Float(literal) {
        return value as! Value
      }
    default:
      throw MacroError.message("Type \(`default`.self) is not supported in the arguments")
    }
    return `default`
  }
}
