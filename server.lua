RegisterNetEvent("sit:sync", function(coords, heading, anim)
    TriggerClientEvent("sit:play", -1, source, coords, heading, anim)
end)