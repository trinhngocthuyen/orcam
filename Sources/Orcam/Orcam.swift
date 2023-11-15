@attached(member, names: named(init))
public macro Init(
  defaultForOptional: Bool = true,
  accessLevel: String? = nil
) = #externalMacro(module: "OrcamImpl", type: "InitMacro")

@attached(member, names: named(init), named(shared))
public macro Singleton() = #externalMacro(module: "OrcamImpl", type: "SingletonMacro")
