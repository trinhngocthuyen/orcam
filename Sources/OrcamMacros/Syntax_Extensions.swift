import SwiftSyntax
import SwiftSyntaxBuilder


extension DeclGroupSyntax {
  func getKeywords() -> [Keyword] {
    modifiers.compactMap { $0.name.keyword }
  }

  func isPublic() -> Bool {
    let keywords = getKeywords()
    return keywords.contains(.public) || keywords.contains(.open)
  }

  func storedProperties() -> [VariableDeclSyntax] {
    memberBlock.members.compactMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self), !variable.isComputedProperty else { return nil }
      return variable
    }
  }
}

extension VariableDeclSyntax {
  var isInitialized: Bool {
    bindings.first?.initializer != nil
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
