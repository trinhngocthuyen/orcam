@attached(member, names: named(init))
public macro Init(
  defaultForOptional: Bool = true
) = #externalMacro(module: "OrcamImpl", type: "InitMacro")


@attached(member, names: named(init))
public macro Singleton() = #externalMacro(module: "OrcamImpl", type: "SingletonMacro")
