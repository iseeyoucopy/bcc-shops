function OpenInitialManageMenu(stores, players)
    Pages.initialManagePage = BCCShopsMainMenu:RegisterPage('bcc-shops:initialmanage')
    Pages.initialManagePage:RegisterElement('header', {
        value = _U('manageStores'),
        slot = "header"
    })

    Pages.initialManagePage:RegisterElement('button', {
        label = _U('createStore'),
        slot = "content"
    }, function()
        OpenCreateStoreMenu()
    end)

    Pages.initialManagePage:RegisterElement('button', {
        label = _U('manageStores'),
        slot = "content"
    }, function()
        Pages.initialManageStores = BCCShopsMainMenu:RegisterPage('bcc-shops:managestores')

        -- Header
        Pages.initialManageStores:RegisterElement('header', {
            value = _U('manageStores'),
            slot = "header"
        })

        -- NPC Shops Button
        Pages.initialManageStores:RegisterElement('button', {
            label = _U('npcStores'),
            slot = "content"
        }, function()
            BccUtils.RPC:Call("bcc-shops:FetchNPCShops", {}, function(npcShops)
                if npcShops then
                    npcStores = npcShops
                    devPrint("✅ NPC shops refreshed: " .. #npcShops)

                    -- Open NPC List Page
                    local npcListPage = BCCShopsMainMenu:RegisterPage("bcc-shops:listnpcstores")
                    npcListPage:RegisterElement("header", { value = _U("npcStores"), slot = "header" })

                    for _, shop in ipairs(npcShops) do
                        local label = (shop.shop_label or shop.shop_name) .. " [" .. shop.shop_name .. "]"
                        npcListPage:RegisterElement("button", {
                            label = label,
                            slot = "content"
                        }, function()
                            OpenEditShopPage(shop)
                        end)
                    end

                    npcListPage:RegisterElement("button", {
                        label = _U("backButton"),
                        slot = "footer"
                    }, function()
                        Pages.initialManageStores:RouteTo()
                    end)

                    BCCShopsMainMenu:Open({ startupPage = npcListPage })
                else
                    devPrint("⚠️ No NPC shops returned.")
                end
            end)
        end)

        -- Player Shops Button
        Pages.initialManageStores:RegisterElement('button', {
            label = _U('playerStores'),
            slot = "content"
        }, function()
            BccUtils.RPC:Call("bcc-shops:FetchPlayerShops", {}, function(playerShops)
                if playerShops then
                    playerStores = playerShops
                    devPrint("✅ Player shops refreshed: " .. #playerShops)

                    -- Open Player List Page
                    Pages.playerListPage = BCCShopsMainMenu:RegisterPage("bcc-shops:listplayerstores")
                    Pages.playerListPage:RegisterElement("header", { value = _U("playerStores"), slot = "header" })

                    for _, shop in ipairs(playerShops) do
                        local label = (shop.shop_label or shop.shop_name) .. " [" .. shop.shop_name .. "]"
                        Pages.playerListPage:RegisterElement("button", {
                            label = label,
                            slot = "content"
                        }, function()
                            OpenEditShopPage(shop)
                        end)
                    end
                    Pages.playerListPage:RegisterElement("button", {
                        label = _U("backButton"),
                        slot = "footer"
                    }, function()
                        Pages.initialManageStores:RouteTo()
                    end)

                    BCCShopsMainMenu:Open({ startupPage = Pages.playerListPage })
                else
                    devPrint("⚠️ No player shops returned.")
                end
            end)
        end)

        -- Line separator
        Pages.initialManageStores:RegisterElement('line', {
            slot = "footer",
            style = {}
        })

        -- Back button
        Pages.initialManageStores:RegisterElement('button', {
            label = _U('backButton'),
            slot = "footer"
        }, function()
            Pages.initialManagePage:RouteTo()
        end)

        -- Bottom line
        Pages.initialManageStores:RegisterElement('bottomline', {
            slot = "footer",
            style = {}
        })

        -- Open the page
        BCCShopsMainMenu:Open({ startupPage = Pages.initialManageStores })
    end)

    Pages.initialManagePage:RegisterElement('button', {
        label = _U('deleteStores'),
        slot = "content"
    }, function()
        OpenDeleteStoresMenu(stores)
    end)

    Pages.initialManagePage:RegisterElement('button', {
        label = "Categories",
        slot = "content"
    }, function()
        local CategoryPage = BCCShopsMainMenu:RegisterPage('bcc-shops:category:page')
        CategoryPage:RegisterElement('header', {
            value = "Categories",
            slot = "header"
        })

        CategoryPage:RegisterElement('button', {
            label = "Create Category",
            slot = "content"
        }, function()
            OpenCreateCategoryMenu()
        end)

        CategoryPage:RegisterElement('button', {
            label = "Edit Category",
            slot = "content"
        }, function()
            OpenEditCategoryMenu()
        end)

        CategoryPage:RegisterElement('button', {
            label = "Delete Category",
            slot = "content"
        }, function()
            OpenDeleteCategoryMenu()
        end)

        CategoryPage:RegisterElement('line', {
            slot = "footer",
            style = {}
        })
        CategoryPage:RegisterElement('button', {
            label = _U('backButton'),
            slot = "footer"
        }, function()
            Pages.initialManagePage:RouteTo()
        end)
        CategoryPage:RegisterElement('bottomline', {
            slot = "footer",
            style = {}
        })
        BCCShopsMainMenu:Open({ startupPage = CategoryPage })
    end)

    Pages.initialManagePage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })
    Pages.initialManagePage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        BCCShopsMainMenu:Close()
    end)
    Pages.initialManagePage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })
    BCCShopsMainMenu:Open({ startupPage = Pages.initialManagePage })
end

function OpenCreateStoreMenu()
    local createStorePage = BCCShopsMainMenu:RegisterPage('player:store:createstore')
    createStorePage:RegisterElement('header', {
        value = _U('createStore'),
        slot = "header"
    })

    createStorePage:RegisterElement('button', {
        label = _U('createNPCStore'),
        slot = "content"
    }, function()
        OpenCreateNPCStoreMenu()
    end)

    createStorePage:RegisterElement('button', {
        label = _U('createPlayerStore'),
        slot = "content"
    }, function()
        FetchPlayersForOwnerSelection()
    end)

    createStorePage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    createStorePage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenInitialManageMenu()
    end)

    createStorePage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({ startupPage = createStorePage })
end

function OpenDeleteStoresMenu()
    local deleteStoresPage = BCCShopsMainMenu:RegisterPage('bcc-shops:deletestores')
    deleteStoresPage:RegisterElement('header', {
        value = _U('deleteStores'),
        slot = "header"
    })

    deleteStoresPage:RegisterElement('button', {
        label = _U('npcStores'),
        slot = "content"
    }, function()
        currentAction = "deleteNPCStores"
        devPrint("Pressed NPC Stores button — sending RPC")
        BccUtils.RPC:Call("bcc-shops:FetchNPCShops", {}, function(npcShops)
            if npcShops then
                npcStores = npcShops
                devPrint("NPC shops refreshed: " .. #npcShops)
                OpenDeleteNPCStoresMenu()
            else
                devPrint("No NPC shops returned.")
                FeatherMenu:Notify({
                    message = _U('noNPCShopFound'),
                    type = "warning",
                    autoClose = 3000
                })
            end
        end)
    end)

    deleteStoresPage:RegisterElement('button', {
        label = _U('playerStores'),
        slot = "content"
    }, function()
        currentAction = "deletePlayerStores"

        local playerShops = BccUtils.RPC:CallAsync("bcc-shops:FetchPlayerShops", {})
        if playerShops and #playerShops > 0 then
            playerStores = playerShops
            devPrint("Player shops refreshed: " .. tostring(#playerShops))
            OpenDeletePlayerStoresMenu()
        else
            devPrint("No player shops returned.")
            FeatherMenu:Notify({
                message = _U('noPlayerShopFound'),
                type = "warning",
                autoClose = 3000
            })
        end
    end)

    deleteStoresPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    deleteStoresPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenInitialManageMenu()
    end)

    deleteStoresPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({ startupPage = deleteStoresPage })
end

function OpenDeletePlayerStoresMenu()
    local deletePlayerStoresPage = BCCShopsMainMenu:RegisterPage('bcc-shops:deleteplayerstores')
    deletePlayerStoresPage:RegisterElement('header', {
        value = _U('deletePlayerStore'),
        slot = "header"
    })

    for _, store in ipairs(playerStores) do
        deletePlayerStoresPage:RegisterElement('button', {
            label = store.shop_name,
            slot = "content"
        }, function()
            OpenDeleteConfirmationMenu(store.shop_id, store.shop_name, "player")
        end)
    end

    deletePlayerStoresPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    deletePlayerStoresPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenDeleteStoresMenu()
    end)

    deletePlayerStoresPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({ startupPage = deletePlayerStoresPage })
end

function OpenDeleteConfirmationMenu(storeId, shopName, storeType)
    local confirmationPage = BCCShopsMainMenu:RegisterPage('bcc-shops:confirmdelete')
    confirmationPage:RegisterElement('header', {
        value = _U('confirmDeletion'),
        slot = "header"
    })
    confirmationPage:RegisterElement('subheader', {
        value = _U('areYouSure') .. shopName,
        slot = "content"
    })

    confirmationPage:RegisterElement('button', {
        label = _U('yes'),
        slot = "content"
    }, function()
        if storeType == "npc" then
            BccUtils.RPC:Call("bcc-shops:deleteNPCShop", { shopId = storeId })
        else
            BccUtils.RPC:Call("bcc-shops:deletePlayerShop", { shopId = storeId })
        end
        BCCShopsMainMenu:Close()
    end)

    confirmationPage:RegisterElement('button', {
        label = _U('no'),
        slot = "content"
    }, function()
        if storeType == "npc" then
            OpenDeleteNPCStoresMenu()
        else
            OpenDeletePlayerStoresMenu()
        end
    end)

    confirmationPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    confirmationPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        if storeType == "npc" then
            OpenDeleteNPCStoresMenu()
        else
            OpenDeletePlayerStoresMenu()
        end
    end)

    confirmationPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({ startupPage = confirmationPage })
end

function OpenCreateCategoryMenu()
    local createPage = BCCShopsMainMenu:RegisterPage("bcc-shops:createCategory")

    createPage:RegisterElement('header', { value = _U('createCategory'), slot = "header" })

    local newName = ""
    createPage:RegisterElement('input', {
        label = _U('categoryName'),
        slot = "content",
        type = "text",
        placeholder = "Enter category name..."
    }, function(data)
        newName = data.value
    end)

    createPage:RegisterElement('button', {
        label = _U("submitChanges"),
        slot = "footer"
    }, function()
        if newName and newName:len() > 0 then
            BccUtils.RPC:Call("bcc-shops:CreateCategory", { name = newName }, function(success)
                if success then
                    Notify(_U("categoryCreated"), "success")
                else
                    Notify(_U("categoryCreateFailed"), "error")
                end
            end)
        end
    end)

    createPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        BCCShopsMainMenu:Close()
    end)

    BCCShopsMainMenu:Open({ startupPage = createPage })
end

function OpenEditCategoryMenu()
    local editPage = BCCShopsMainMenu:RegisterPage("bcc-shops:editCategory")
    editPage:RegisterElement('header', { value = _U('editCategory'), slot = "header" })

    local categories = BccUtils.RPC:CallAsync("bcc-shops:GetAllCategories", {})

    for _, cat in ipairs(categories) do
        editPage:RegisterElement('button', {
            label = cat.name,
            slot = "content"
        }, function()
            local renamePage = BCCShopsMainMenu:RegisterPage("bcc-shops:renameCategory")
            local newLabel = cat.name

            renamePage:RegisterElement('input', {
                label = _U('categoryName'),
                slot = "content",
                type = "text",
                default = cat.name
            }, function(data)
                newLabel = data.value
            end)

            renamePage:RegisterElement('button', {
                label = _U("submitChanges"),
                slot = "footer"
            }, function()
                BccUtils.RPC:Call("bcc-shops:EditCategory", {
                    id = cat.id,
                    name = newLabel
                }, function(success)
                    if success then
                        Notify(_U("categoryUpdated"), "success")
                    else
                        Notify(_U("categoryUpdateFailed"), "error")
                    end
                end)
            end)

            renamePage:RegisterElement('button', {
                label = _U('backButton'),
                slot = "footer"
            }, function()
                editPage:RouteTo()
            end)

            BCCShopsMainMenu:Open({ startupPage = renamePage })
        end)
    end

    editPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        BCCShopsMainMenu:Close()
    end)

    BCCShopsMainMenu:Open({ startupPage = editPage })
end

function OpenEditShopPage(shop)
    Pages.editPage = BCCShopsMainMenu:RegisterPage("bcc-shops:editshop_" .. shop.shop_id)
    Pages.editPage:RegisterElement("header", {
        value = _U("editShopHeader"),
        slot = "header"
    })

    local fields = {
        { key = "shop_name",     label = _U("editShopName") },
        { key = "shop_location", label = _U("editShopLocation") },
        { key = "inv_limit",     label = _U("editInventoryLimit") },
        { key = "webhook_link",  label = _U("editWebhookLink") },
        { key = "ledger",        label = _U("editLedgerAmount") },
        { key = "blip_hash",     label = _U("editBlipHash") },
        { key = "npc_model",     label = _U("editNPCModel") },
        { key = "show_blip",     label = _U("editShowBlip") },
    }

    local edits = {}

    for _, field in ipairs(fields) do
        Pages.editPage:RegisterElement("input", {
            label = field.label,
            placeholder = tostring(shop[field.key] or ""),
            default = tostring(shop[field.key] or ""),
            slot = "content"
        }, function(value)
            edits[field.key] = value.value or value -- FIX HERE
        end)
    end

    -- Submit changes
    Pages.editPage:RegisterElement("button", {
        label = _U("submitChanges"),
        slot = "footer"
    }, function()
        edits.shopId = shop.shop_id
        edits.shop_type = shop.shop_type -- optional, in case you log or display type

        BccUtils.RPC:Call("bcc-shops:EditShop", edits, function(success)
            if success then
                Notify(_U("itemUpdated"), "success")
                Pages.initialManageStores:RouteTo()
            else
                Notify(_U("itemUpdatedFail"), "error")
            end
        end)
    end)

    -- Back button
    Pages.editPage:RegisterElement("button", {
        label = _U("backButton"),
        slot = "footer"
    }, function()
       Pages.initialManageStores:RouteTo()
    end)

    BCCShopsMainMenu:Open({ startupPage = Pages.editPage })
end

-- Open Delete Category Menu
function OpenDeleteCategoryMenu()
    local deletePage = BCCShopsMainMenu:RegisterPage("bcc-shops:deleteCategory")
    deletePage:RegisterElement('header', { value = _U('deleteCategory'), slot = "header" })

    local categories = BccUtils.RPC:CallAsync("bcc-shops:GetAllCategories", {})

    for _, cat in ipairs(categories) do
        deletePage:RegisterElement('button', {
            label = cat.name,
            slot = "content"
        }, function()
            BccUtils.RPC:Call("bcc-shops:DeleteCategory", { id = cat.id }, function(success)
                if success then
                    Notify(_U("categoryDeleted"), "success")
                else
                    Notify(_U("categoryDeleteFailed"), "error")
                end
            end)
        end)
    end

    deletePage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        BCCShopsMainMenu:Back()
    end)

    BCCShopsMainMenu:Open({ startupPage = deletePage })
end
