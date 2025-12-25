-- ServerStorage/Cmdr/Types/template.lua
return function(registry)
	registry:RegisterType("template", registry.Cmdr.Util.MakeEnumType("Template", { "None" }))
end
