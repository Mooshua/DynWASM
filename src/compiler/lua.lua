
local Language = {
    Macro = {}
}


Language.Ref = "<-name-> = <-value->"
Language.NewRef = "local <-name-> = <-value->"
Language.FallbackToRef = {"%."}
Language.Emit = "Dst:Util_append(<-section->, <-data->)"
Language.Symbol = "Dst:Symbol(<-type->,<-name->)"
Language.Vector = " {<-values->}"
Language.ArgSeparator = ", "
Language.Macro = "Dst:Macro_<-name->(<-arg->)"

return Language