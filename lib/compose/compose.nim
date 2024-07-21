import std/macros

# Defines a simple getter property for a field with an optional name
# to export. If no name is specified, the exported name is the same
# as the name of the field.
macro getter*(
  t: typed,
  field: untyped,
  name: untyped = newNimNode(nnkNone)
): untyped =
  let id: NimNode =
    if name.kind == nnkNone:
      field
    else:
      name.expectKind(nnkIdent)
      name

  field.expectKind(nnkIdent)
  let quoted = newTree(nnkAccQuoted, id)

  quote do:
    func `quoted`*(self: `t`): auto =
      self.`field`

# Unrolls a type into another type. For example:
# type Foo = unroll Header, Body, Footer makes all
# fields in Header, Body, and Footer fields of Foo.
# This removes a level of indirection, so that, for example,
# foo.header.field can be accessed as foo.field.
macro unroll*(types: varargs[typed]): untyped =
  var fields = newNimNode(nnkRecList)

  for t in types:
    t.expectKind(nnkSym)
    assert(t.symKind == nskType)
    let impl = t.getImpl()
    let obj = impl.findChild(it.kind == nnkObjectTy)
    assert(obj != nil)
    let list = obj.findChild(it.kind == nnkRecList)
    assert(list != nil)
    list.copyChildrenTo(fields)

  nnkObjectTy.newTree(
    newEmptyNode(),
    newEmptyNode(),
    fields
  )
