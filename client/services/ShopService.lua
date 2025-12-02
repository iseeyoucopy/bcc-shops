function CreateBlips()
    for _, shop in ipairs(npcStores) do
        if shop.show_blip then
            local hash = tonumber(shop.blip_hash)
            local blip = BccUtils.Blips:SetBlip(shop.shop_name, hash, 1, shop.pos_x, shop.pos_y, shop.pos_z)
            CreatedBlip[#CreatedBlip + 1] = blip
        end
    end

    for _, shop in ipairs(playerStores) do
        if shop.show_blip then
            local hash = tonumber(shop.blip_hash)
            local blip = BccUtils.Blips:SetBlip(shop.shop_name, hash, 1, shop.pos_x, shop.pos_y, shop.pos_z)
            CreatedBlip[#CreatedBlip + 1] = blip
        end
    end
end

function CreateNPCs()
    for _, shop in ipairs(npcStores) do
        shopPed = BccUtils.Ped:Create(shop.npc_model, shop.pos_x, shop.pos_y, shop.pos_z - 1, 0, 'world', false)
        CreatedNPC[#CreatedNPC + 1] = shopPed
        shopPed:Freeze()
        shopPed:SetHeading(shop.pos_heading)
        shopPed:Invincible()
        shopPed:SetBlockingOfNonTemporaryEvents(true)
    end

    for _, shop in ipairs(playerStores) do
        shopPed = BccUtils.Ped:Create(shop.npc_model, shop.pos_x, shop.pos_y, shop.pos_z - 1, 0, 'world', false)
        CreatedNPC[#CreatedNPC + 1] = shopPed
        shopPed:Freeze()
        shopPed:SetHeading(shop.pos_heading)
        shopPed:Invincible()
        shopPed:SetBlockingOfNonTemporaryEvents(true)
    end
end

function FetchPlayersForOwnerSelection()
    BccUtils.RPC:Call("bcc-shops:FetchPlayersForOwnerSelection", {}, function(players)
        if players then
            -- Replace this with your menu or logic handler
            SelectOwner(players)
        else
            Notify(_U("failedToFetchPlayers"), "error", 4000)
        end
    end)
end

BccUtils.RPC:Register("bcc-shops:clientCleanup", function()
    for _, npc in ipairs(CreatedNPC) do
        if npc and npc.Remove then
            npc:Remove()
        elseif DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    CreatedNPC = {}

    for _, blip in ipairs(CreatedBlip) do
        if blip and blip.Remove then
            blip:Remove()
        else
            RemoveBlip(blip)
        end
    end
    CreatedBlip = {}

    for _, customer in ipairs(CreatedCustomers or {}) do
        if customer and customer.Remove then
            customer:Remove()
        elseif DoesEntityExist(customer) then
            DeleteEntity(customer)
        end
    end
    CreatedCustomers = {}

    BCCShopsMainMenu:Close()

    devPrint("[ClientCleanup] All NPCs, blips, and customers cleaned up.")
end)

BccUtils.RPC:Register("bcc-shops:RefreshStoreData", function(_, cb)
    -- Fetch NPC shops
    npcStores = BccUtils.RPC:CallAsync("bcc-shops:FetchNPCShops")
    devPrint("NPC shops refreshed: " .. tostring(#npcStores))

    -- Fetch player shops (ensure assignment always happens)
    playerStores = BccUtils.RPC:CallAsync("bcc-shops:FetchPlayerShops")
    storesFetched = true
    devPrint("Player stores refreshed: " .. tostring(#playerStores))

    -- Recreate world data
    CreateBlips()
    CreateNPCs()

    if cb then cb(true) end
end)
