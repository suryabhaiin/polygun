RegisterNetEvent("polygun:save")
AddEventHandler("polygun:save", function(zone, text)
  file = io.open(GetResourcePath('polygun') .. "/zones.txt", "a")
  io.output(file)
  io.write("--Name: " .. zone.name .. " | " .. os.date("!%Y-%m-%dT%H:%M:%SZ\n") .. text)
  io.close(file)
end)

lib.addCommand('polygun', {
  help = 'Create Polyzon at entity',
  restricted = 'group.admin'
}, function(source, args, raw)
  TriggerClientEvent("polygun:runpolygun", source)
end)

lib.addCommand('plaser', {
  help = 'Copy coordinates at laser point',
  restricted = 'group.admin'
}, function(source, args, raw)
  TriggerClientEvent("polygun:runlaser", source)
end)
