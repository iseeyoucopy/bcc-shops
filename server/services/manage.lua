BccUtils.RPC:Register("bcc-shops:createNPCStore", function(params, cb, source)
    devPrint("Creating NPC Store: " .. tostring(params.shopName) .. " at " .. tostring(params.shopLocation))

    -- Fetch character info
    local user = VORPcore.getUser(source)
    local char = user and user.getUsedCharacter
    local charId = char and char.charIdentifier or "unknown"
    local firstName = char and char.firstname or "unknown"
    local lastName = char and char.lastname or "unknown"

    local insertQuery = [[
        INSERT INTO bcc_shops (
            owner_id, shop_name, shop_location, shop_type, webhook_link, inv_limit, ledger,
            blip_hash, is_npc_shop, pos_x, pos_y, pos_z, pos_heading, npc_model
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]

    local defaultBlipHash = Config.DefaultBlipHash
    local defaultModel = Config.DefaultNPCModel

    MySQL.insert(insertQuery, {
        nil,
        params.shopName,
        params.shopLocation,
        params.storeType,
        Config.Webhook,
        0, -- invLimit
        0, -- ledger
        tostring(params.blipHash or defaultBlipHash),
        1,
        params.posX,
        params.posY,
        params.posZ,
        params.posHeading,
        params.npcModel or defaultModel
    }, function(result)
        if result then
            devPrint("NPC Shop created: " .. params.shopName)

            -- Send Discord log
            local embed = {{
                color = 5763719,
                title = "🏪 NPC Shop Created",
                description = table.concat({
                    "**Shop Name:** `" .. params.shopName .. "`",
                    "**Location:** `" .. params.shopLocation .. "`",
                    "**Position:** " .. string.format("`%.2f, %.2f, %.2f`", params.posX, params.posY, params.posZ),
                    "**Created By:** `" .. firstName .. " " .. lastName .. "`",
                    "**Char ID:** `" .. tostring(charId) .. "`"
                }, "\n")
            }}
            BccUtils.Discord.sendMessage(Config.Webhook, Config.WebhookTitle, Config.WebhookAvatar, "NPC Shop Created", nil, embed)

            NotifyClient(source, _U('shopCreatedSuccess'), "success")
            BccUtils.RPC:Notify("bcc-shops:RefreshStoreData", {}, source)
            cb(true)
        else
            devPrint("Failed to create NPC shop.")
            NotifyClient(source, _U('shopCreatedFail'), "error")
            cb(false)
        end
    end)
end)

BccUtils.RPC:Register("bcc-shops:createplayershop", function(params, cb, source)
    local ownerId = params.ownerId
    devPrint("Owner ID received: " .. tostring(ownerId))

    if not ownerId then
        devPrint("Invalid owner ID received.")
        NotifyClient(source, _U('invalidOwnerId'), "warning")
        return cb(false)
    end

    local user = VORPcore.getUser(ownerId)
    local char = user and user.getUsedCharacter
    if not char or not char.charIdentifier then
        devPrint("Character not found or missing charIdentifier for owner ID: " .. tostring(ownerId))
        NotifyClient(source, _U('charNotFound'), "warning")
        return cb(false)
    end

    local charId = char.charIdentifier
    local firstName = char.firstname or "unknown"
    local lastName = char.lastname or "unknown"

    local pos_x, pos_y, pos_z, heading = params.pos_x, params.pos_y, params.pos_z, params.storeHeading
    local shopType = params.storeType or "player"
    local blipHash = params.blipHash or Config.DefaultBlipHash
    local invLimit = params.invLimit or 0
    local shopLocation = params.storeLocation or shopType

    MySQL.insert([[
        INSERT INTO bcc_shops (
            owner_id, shop_name, pos_x, pos_y, pos_z, pos_heading,
            shop_type, blip_hash, ledger, inv_limit, is_npc_shop, shop_location, npc_model
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        charId, params.shopName,
        pos_x, pos_y, pos_z, heading,
        shopType, blipHash, 0, invLimit, 0, shopLocation,
        Config.DefaultNPCModel
    }, function(inserted)
        if inserted then
            devPrint("Player Shop created: " .. params.shopName)

            -- Send Discord log
            local embed = {{
                color = 65280,
                title = "🏪 Player Shop Created",
                description = table.concat({
                    "**Shop Name:** `" .. params.shopName .. "`",
                    "**Location:** `" .. shopLocation .. "`",
                    "**Position:** " .. string.format("`%.2f, %.2f, %.2f`", pos_x, pos_y, pos_z),
                    "**Created By:** `" .. firstName .. " " .. lastName .. "`",
                    "**Char ID:** `" .. tostring(charId) .. "`"
                }, "\n")
            }}
            BccUtils.Discord.sendMessage(Config.Webhook, Config.WebhookTitle, Config.WebhookAvatar, "Player Shop Created", nil, embed)

            BccUtils.RPC:Notify("bcc-shops:RefreshStoreData", {}, source)
            cb(true)
        else
            devPrint("Failed to create player shop.")
            cb(false)
        end
    end)
end)

BccUtils.RPC:Register("bcc-shops:deleteNPCShop", function(params, cb, src)
    local shopId = params.shopId
    if not shopId then
        devPrint("Missing shopId")
        cb(false)
        return
    end

    devPrint("Starting deletion for NPC shopId: " .. tostring(shopId))

    -- Fetch player character info
    local user = VORPcore.getUser(src)
    local char = user and user.getUsedCharacter
    local charId = char and char.charIdentifier or "unknown"
    local firstName = char and char.firstname or "unknown"
    local lastName = char and char.lastname or "unknown"

    -- Fetch shop data
    local shopData = MySQL.query.await('SELECT shop_name, shop_location FROM bcc_shops WHERE shop_id = ?', { shopId })
    local shopName = shopData[1] and shopData[1].shop_name or "Unknown"
    local shopLocation = shopData[1] and shopData[1].shop_location or "Unknown"

    -- Delete items
    local itemDeleteResult = MySQL.update.await('DELETE FROM bcc_shop_items WHERE shop_id = ?', { shopId })
    devPrint("Deleted " .. tostring(itemDeleteResult or 0) .. " regular items")

    local weaponDeleteResult = MySQL.update.await('DELETE FROM bcc_shop_weapon_items WHERE shop_id = ?', { shopId })
    devPrint("Deleted " .. tostring(weaponDeleteResult or 0) .. " weapon items")

    -- Delete shop
    local shopDeleteResult = MySQL.update.await('DELETE FROM bcc_shops WHERE shop_id = ? AND is_npc_shop = 1', { shopId })
    if not shopDeleteResult or shopDeleteResult <= 0 then
        devPrint("Failed to delete shop with shopId: " .. tostring(shopId))
        NotifyClient(src, _U("npcstore_delete_failed"), "error")
        return cb(false)
    end

    devPrint("NPC shop deleted: " .. shopName .. " | ID: " .. shopId)

    -- Send Discord log
    local embed = {{
        color = 16711680,
        title = "🗑️ NPC Shop Deleted",
        description = table.concat({
            "**Shop Name:** `" .. shopName .. "`",
            "**Location:** `" .. shopLocation .. "`",
            "**Shop ID:** `" .. tostring(shopId) .. "`",
            "**Deleted By:** `" .. firstName .. " " .. lastName .. "`",
            "**Char ID:** `" .. tostring(charId) .. "`"
        }, "\n")
    }}

    BccUtils.Discord.sendMessage(Config.Webhook, Config.WebhookTitle, Config.WebhookAvatar, "NPC Shop Deleted", nil, embed)

    -- Notify clients
    BccUtils.RPC:Notify("bcc-shops:clientCleanup", {}, -1)
    NotifyClient(src, _U("npcstore_deleted_success"), "success")
    BccUtils.RPC:Notify("bcc-shops:RefreshStoreData", {}, src)
    cb(true)
end)

BccUtils.RPC:Register("bcc-shops:deletePlayerShop", function(params, cb, src)
    local shopId = params.shopId
    if not shopId then
        devPrint("Missing shopId")
        cb(false)
        return
    end

    devPrint("Starting deletion for player shopId: " .. tostring(shopId))

    -- Fetch player character info
    local user = VORPcore.getUser(src)
    local char = user and user.getUsedCharacter
    local charId = char and char.charIdentifier or "unknown"
    local firstName = char and char.firstname or "unknown"
    local lastName = char and char.lastname or "unknown"

    -- Fetch shop data
    local shopData = MySQL.query.await('SELECT shop_name, shop_location, owner_id FROM bcc_shops WHERE shop_id = ?', { shopId })
    local shopName = shopData[1] and shopData[1].shop_name or "Unknown"
    local shopLocation = shopData[1] and shopData[1].shop_location or "Unknown"
    local ownerId = shopData[1] and shopData[1].owner_id or "Unknown"

    -- Delete items
    local itemDeleteResult = MySQL.update.await('DELETE FROM bcc_shop_items WHERE shop_id = ?', { shopId })
    devPrint("Deleted " .. tostring(itemDeleteResult or 0) .. " regular items")

    local weaponDeleteResult = MySQL.update.await('DELETE FROM bcc_shop_weapon_items WHERE shop_id = ?', { shopId })
    devPrint("Deleted " .. tostring(weaponDeleteResult or 0) .. " weapon items")

    -- Delete shop
    local shopDeleteResult = MySQL.update.await('DELETE FROM bcc_shops WHERE shop_id = ? AND owner_id IS NOT NULL', { shopId })
    if not shopDeleteResult or shopDeleteResult <= 0 then
        devPrint("Failed to delete player shop with shopId: " .. tostring(shopId))
        NotifyClient(src, _U("playerstore_delete_failed"), "error")
        return cb(false)
    end

    devPrint("Player shop deleted: " .. shopName .. " | ID: " .. shopId)

    -- Send Discord log
    local embed = {{
        color = 16711680,
        title = "🗑️ Player Shop Deleted",
        description = table.concat({
            "**Shop Name:** `" .. shopName .. "`",
            "**Location:** `" .. shopLocation .. "`",
            "**Shop ID:** `" .. tostring(shopId) .. "`",
            "**Owner ID:** `" .. tostring(ownerId) .. "`",
            "**Deleted By:** `" .. firstName .. " " .. lastName .. "`",
            "**Char ID:** `" .. tostring(charId) .. "`"
        }, "\n")
    }}

    BccUtils.Discord.sendMessage(Config.Webhook, Config.WebhookTitle, Config.WebhookAvatar, "Player Shop Deleted", nil, embed)

    -- Notify clients
    BccUtils.RPC:Notify("bcc-shops:clientCleanup", {}, -1)
    NotifyClient(src, _U("playerstore_deleted_success"), "success")
    BccUtils.RPC:Notify("bcc-shops:RefreshStoreData", {}, src)
    cb(true)
end)

function manageStores(source, isAdmin)
    if isAdmin then
        devPrint("Admin " .. source .. " is managing shops.")
        local players = GetPlayers()
        local playerList = {}
        for _, playerId in ipairs(players) do
            local player = VORPcore.getUser(playerId)
            local character = player.getUsedCharacter
            table.insert(playerList, { id = playerId, name = character.firstname .. ' ' .. character.lastname })
        end
        MySQL.query('SELECT * FROM bcc_shops', {}, function(shops)
            BccUtils.RPC:Notify("bcc-shops:OpenManageStoresUI", {
                shops = shops,
                players = playerList
            }, source)
        end)
    else
        VORPcore.NotifyObjective(source, 'You do not have permission to use this command!', 3000)
    end
end

RegisterCommand(Config.ManageShopsCommand, function(source, args, rawCommand)
    local User = VORPcore.getUser(source)
    if not User then return end

    local group = User.getGroup
    local job = User.getUsedCharacter.job

    local isAdminGroup = false
    for _, g in ipairs(Config.adminGroups) do
        if g == group then
            isAdminGroup = true
            break
        end
    end

    local isAllowedJob = false
    for _, j in ipairs(Config.AllowedJobs) do
        if j == job then
            isAllowedJob = true
            break
        end
    end

    if isAdminGroup or isAllowedJob then
        manageStores(source, true)
    else
        manageStores(source, false)
    end
end, false)

BccUtils.RPC:Register("bcc-shops:FetchPlayersForOwnerSelection", function(params, cb, src)
    local players = {}

    -- Optional: Filter by online status, group, etc., using params if needed
    for _, playerId in ipairs(GetPlayers()) do
        local user = VORPcore.getUser(playerId)
        if user then
            local char = user.getUsedCharacter
            local name = char and (char.firstname .. " " .. char.lastname) or GetPlayerName(playerId)
            table.insert(players, { id = playerId, name = name })
        end
    end

    cb(players)
end)

BccUtils.RPC:Register("bcc-shops:FetchOnlinePlayers", function(_, cb, source)
    local playersForAccess = {}

    for _, playerId in ipairs(GetPlayers()) do
        local name = GetPlayerName(playerId)
        local user = VORPcore.getUser(tonumber(playerId))
        local character = user and user.getUsedCharacter
        if character then
            table.insert(playersForAccess, {
                playerId = tonumber(playerId),
                charId = character.charIdentifier,
                name = name .. " | ID: " .. character.charIdentifier
            })
        end
    end

    cb(playersForAccess)
end)

BccUtils.RPC:Register("bcc-shops:SetPlayerShopBlip", function(params, cb, src)
    local shopName = params.shopName
    local blipHash = tonumber(params.blipHash)

    if not shopName or not blipHash then
        NotifyClient(src, "Missing parameters", "error")
        return cb(false)
    end

    local User = VORPcore.getUser(src)
    local Character = User and User.getUsedCharacter
    if not Character or not Character.charIdentifier then
        devPrint("Character not found or missing charidentifier for owner ID: " .. tostring(src))
        NotifyClient(src, _U('charNotFound'), "warning")
        return cb(false)
    end

    local charidentifier = Character.charIdentifier
    local affectedRows = MySQL.update.await(
        "UPDATE bcc_shops SET blip_hash = ? WHERE shop_name = ? AND owner_id = ?",
        { blipHash, shopName, charidentifier }
    )

    if affectedRows and affectedRows > 0 then
        devPrint(("Updated blip hash for shop '%s' to %s"):format(shopName, blipHash))
        cb(true)
    else
        devPrint(("Failed to update blip for shop '%s'"):format(shopName))
        cb(false)
    end
end)

BccUtils.RPC:Register("bcc-shops:SetShopBlipEnabled", function(params, cb, src)
    local shopName = params.shopName
    local enabled = params.enabled

    if not shopName or enabled == nil then
        devPrint("Missing shopName or enabled in SetShopBlipEnabled")
        return cb(false)
    end

    local affected = MySQL.update.await(
        "UPDATE bcc_shops SET show_blip = ? WHERE shop_name = ?",
        { enabled and 1 or 0, shopName }
    )

    if affected > 0 then
        devPrint(("Updated show_blip for shop '%s' to %s"):format(shopName, tostring(enabled)))
        cb(true)
    else
        devPrint(("No rows updated for shop '%s'"):format(shopName))
        cb(false)
    end
end)

BccUtils.RPC:Register("bcc-shops:CreateCategory", function(params, cb, src)
    if not params or not params.name then return cb(false) end

    local label   = (params.label and params.label:match("%S")) and params.label or params.name
    local result = MySQL.insert.await("INSERT INTO bcc_shop_categories (name, label) VALUES (?, ?)", { params.name, label })
    cb(result ~= nil)
end)

BccUtils.RPC:Register("bcc-shops:EditCategory", function(params, cb, src)
    if not params or not params.id or not params.name then return cb(false) end

    local label   = (params.label and params.label:match("%S")) and params.label or params.name
    local updated = MySQL.update.await("UPDATE bcc_shop_categories SET name = ?, label = ? WHERE id = ?", { params.name, label, params.id })
    cb(updated and updated > 0)
end)

BccUtils.RPC:Register("bcc-shops:DeleteCategory", function(params, cb, src)
    if not params or not params.id then
        NotifyClient(source, _U('missingCategoryId'), "success")
        return cb(false)
    end

    local categoryId = tonumber(params.id)
    if not categoryId then
        devPrint("Invalid category id: " .. tostring(params.id))
        return cb(false)
    end

    -- Check references before attempting delete
    local inUseItems   = MySQL.scalar.await("SELECT COUNT(*) FROM bcc_shop_items WHERE category_id = ?", { categoryId }) or 0
    local inUseWeapons = MySQL.scalar.await("SELECT COUNT(*) FROM bcc_shop_weapon_items WHERE category_id = ?", { categoryId }) or 0

    if (inUseItems + inUseWeapons) > 0 then
        local msg = ("Category is in use: " .. inUseItems .. " item(s), " .. inUseWeapons .. " weapon(s). Remove or reassign them first.")
        devPrint("[DeleteCategory] Blocked delete for id " .. categoryId .. " -> " .. msg)
        return cb(false, msg)
    end

    -- Safe to delete
    local ok, resOrErr = pcall(function()
        return MySQL.update.await("DELETE FROM bcc_shop_categories WHERE id = ?", { categoryId })
    end)

    if not ok then
        devPrint(("[DeleteCategory] DB error while deleting id %d: %s"):format(categoryId, tostring(resOrErr)))
        return cb(false)
    end

    local affected = resOrErr or 0
    if affected > 0 then
        devPrint(("[DeleteCategory] Deleted category id %d"):format(categoryId))
        return cb(true)
    else
        devPrint(("[DeleteCategory] Nothing deleted for id " .. categoryId .. " (not found?)"))
        return cb(false)
    end
end)


BccUtils.RPC:Register("bcc-shops:GetAllCategories", function(_, cb, src)
    local categories = MySQL.query.await("SELECT id, name, label FROM bcc_shop_categories ORDER BY label ASC")
    cb(categories or {})
end)

BccUtils.RPC:Register("bcc-shops:EditShop", function(params, cb, source)
    if not params or not params.shopId then
        devPrint("Missing required parameter: shopId")
        return cb(false)
    end

    local shopId = tonumber(params.shopId)
    if not shopId then
        devPrint("Invalid shopId provided")
        return cb(false)
    end

    local updateFields, updateValues = {}, {}

    local fieldMap = {
        shop_name     = params.shop_name,
        shop_location = params.shop_location,
        shop_type     = params.shop_type,
        webhook_link  = params.webhook_link,
        inv_limit     = params.inv_limit,
        ledger        = params.ledger,
        blip_hash     = params.blip_hash,
        show_blip     = params.show_blip,
        npc_model     = params.npc_model,
        pos_x         = params.pos and params.pos.x,
        pos_y         = params.pos and params.pos.y,
        pos_z         = params.pos and params.pos.z,
        pos_heading   = params.heading
    }

    for field, value in pairs(fieldMap) do
        if value ~= nil then
            table.insert(updateFields, field .. " = ?")
            table.insert(updateValues, value)
        end
    end

    if #updateFields == 0 then
        devPrint("No fields to update for shop ID " .. tostring(shopId))
        return cb(false)
    end

    table.insert(updateValues, shopId)

    local sql = "UPDATE bcc_shops SET " .. table.concat(updateFields, ", ") .. " WHERE shop_id = ?"

    local success = MySQL.update.await(sql, updateValues) > 0
    devPrint("Shop update result for ID " .. shopId .. ": " .. tostring(success))
    cb(success)
end)

local npcLoopStarted = false

BccUtils.RPC:Register("bcc-shops:StartNpcPurchases", function(_, cb)
    print(" NPC purchase loop status: " .. tostring(npcLoopStarted))

    npcLoopStarted = true -- always allow (idempotent)
    print("NPC purchase loop triggered (idempotent).")
    cb(true)
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        npcLoopStarted = false
    end
end)
