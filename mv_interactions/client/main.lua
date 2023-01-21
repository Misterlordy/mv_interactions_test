local PlayerData, handcuffTimer, dragStatus = {}, {}, {}
local isDead, isHandcuffed, hasAlreadyJoined, isOn, HaveBagOnHead, emotePlaying = false, false, false, false, false, false
local societymoney = nil
dragStatus.isDragged = false
ESX = nil

lockDistance = 25


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	PlayerData = ESX.GetPlayerData()
	RefreshMoney()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	RefreshMoney()
end)

AddEventHandler('baseevents:enteredVehicle', function(veh)
	SetVehicleAutoRepairDisabled(veh, true)
end)

AddEventHandler('baseevents:leftVehicle', function(veh)
	SetVehicleAutoRepairDisabled(veh, false)
end)
------------------------------------------------------------------------------------------------------
-------------------RP-MENU----------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
function OpenRPActionsMenu()
	--ESX.UI.Menu.CloseAll()
	local elements = {}

	if Config.CitizenInteractionEnabled then
		table.insert(elements, {label = 'Interakcie', value = 'citizen_interaction'})
	end
	if Config.VehicleInteractionEnabled then
		table.insert(elements, {label = 'Vozidlo', value = 'vehicle_interaction'})
	end
	if Config.InvoicesMenuEnabled then
		table.insert(elements, {label = 'Faktury', value = 'show_invoices'})
	end
	if Config.LicensesMenuEnabled then
		table.insert(elements, {label = 'Doklady', value = 'show_licenses'})
	end

	table.insert(elements, {label = 'Ability', value = 'ability_menu'})


	if Config.PortFolioMenu and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss' or  PlayerData.job.grade_name == 'boss_shrf' then
		table.insert(elements, {label = 'Firma', value = 'show_portfolio'})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'hs_f5menu', {
		title    = 'Osobné menu',
		align    = 'right',
		elements = elements

	}, function(data, menu)
		
		if data.current.value == 'citizen_interaction' then
			if (IsPedSittingInAnyVehicle(PlayerPedId())) then
				--exports['dopeNotify']:Alert("Server", "Tato akce není možná ve vozidle", 5000, 'error')
				exports['mythic_notify']:DoHudText('error', 'Tato akce není možná ve vozidle')
			else
				OpenCitizenInteractionMenu ()
			end
		elseif data.current.value == 'vehicle_interaction' then
			OpenVehicleInteractionMenu ()

		elseif data.current.value == 'show_invoices' then
			ShowBillsMenu()

		elseif data.current.value == 'show_licenses' then
			OpenLicensesMenu ()

		elseif data.current.value == 'show_portfolio' then
			OpenPortFolioMenu()

		elseif data.current.value == 'ability_menu' then
			exports["gamz-skillsystem"]:SkillMenu()

		end
	end, function(data, menu)
		menu.close()
	end)
end





----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------	
---------------- INTERACTION ----------------
---------------------------------------------
function OpenCitizenInteractionMenu ()
	local elements = {}

	if Config.SearchPlayerEnabled then
		table.insert(elements,{label = 'Prohledat', value = 'body_search'})
	end
	if Config.HeadBagEnabled then
		table.insert(elements, {label = 'Nandat pytel', value = 'head_bag'})
	end
	if Config.HandCuffEnabled then
		table.insert(elements, {label = 'Spoutat/Odpoutat Normálně', value = 'handcuff'})
		table.insert(elements, {label = 'Spoutat/Odpoutat Agresivně', value = 'handcuff_2'})
	end
	if Config.DragPlayerEnabled then
		table.insert(elements, {label = 'Vzít/Pustiť', value = 'drag'})
	end
	if Config.PutInOutVehicleEnabled then
		table.insert(elements, {label = 'Dát do vozidla', value = 'put_in_vehicle'})
		table.insert(elements, {label = 'Vytáhnout z vozidla', value = 'out_the_vehicle'})
	end
	table.insert(elements, {label = 'Zajmout', value = 'take_hostage'})

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
		title    = 'Interakce',
		align    = 'right',
		elements = elements
	}, function(data2, menu2)
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
			local action = data2.current.value
				if action == 'body_search' then
					exports.ox_inventory:openNearbyInventory()
					ExecuteCommand('me Prohledává osobu')
					ExecuteCommand('doc 5')
					TriggerServerEvent('esx_policejob:message', GetPlayerServerId(closestPlayer), 'Jsi prohledáván')
			
				elseif action == 'head_bag' then
				OpenHeadBagMenu()
			
			elseif action == 'handcuff' then
				local target, distance = ESX.Game.GetClosestPlayer()
				playerheading = GetEntityHeading(GetPlayerPed(-1))
				playerlocation = GetEntityForwardVector(PlayerPedId())
				playerCoords = GetEntityCoords(GetPlayerPed(-1))
				--exports['pogressBar']:drawBar(3760, 'Poutáš osobu')
				ExecuteCommand('me Bere pouta z opasku a poutá')
				local target_id = GetPlayerServerId(target)
				if distance <= 2.0 then
					TriggerServerEvent('esx_policejob:handcuff',  GetPlayerServerId(closestPlayer))
					
				else
					--exports['dopeNotify']:Alert("Server", "Nejsi dostatečně blízko pro spoutání osoby", 5000, 'error')
					exports["mythic_notify"]:DoHudText('error', 'Nejsi dostatečně blízko pro spoutání osoby')
				end
			elseif action == 'handcuff_2' then
				local target, distance = ESX.Game.GetClosestPlayer()
				playerheading = GetEntityHeading(GetPlayerPed(-1))
				playerlocation = GetEntityForwardVector(PlayerPedId())
				playerCoords = GetEntityCoords(GetPlayerPed(-1))
				--exports['pogressBar']:drawBar(3760, 'Agresivní Poutání')
				ExecuteCommand('me Bere pouta a poutá osobu agresivne')
				local target_id = GetPlayerServerId(target)
				if distance <= 2.0 then
					TriggerServerEvent('esx_ruski_areszt:startAreszt', GetPlayerServerId(closestPlayer)) -- Rozpoczyna Funkcje na Animacje (Cala Funkcja jest Powyzej^^^)
					Citizen.Wait(3000)
					TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.0, 'cuff', 0.7)
					TriggerServerEvent('esx_policejob:handcuff',  GetPlayerServerId(closestPlayer))
				else
					--exports['dopeNotify']:Alert("Server", "Žádní hráči v okolí!", 5000, 'error')
				 exports["mythic_notify"]:DoHudText('error', 'Žádní hráči v okolí!')
				end

			elseif action == 'uncuff' then
				local target, distance = ESX.Game.GetClosestPlayer()
				playerheading = GetEntityHeading(GetPlayerPed(-1))
				playerlocation = GetEntityForwardVector(PlayerPedId())
				playerCoords = GetEntityCoords(GetPlayerPed(-1))
				--exports['pogressBar']:drawBar(3760, 'Odpoutávaš Osobu')
				ExecuteCommand('me Odpoutává')
				local target_id = GetPlayerServerId(target)
				if distance <= 2.0 then
					TriggerServerEvent('esx_policejob:requestrelease', target_id, playerheading, playerCoords, playerlocation)
					TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 3, 'uncuff', 0.5)
				else
					--exports['dopeNotify']:Alert("Server", "Nejsi dostatečně blízko pro odpoutání osoby", 5000, 'error')
					exports["mythic_notify"]:DoHudText('error', 'Nejsi dostatečně blízko pro odpoutání osoby')
				end
			  elseif action == 'drag' then
				--exports['pogressBar']:drawBar(3760, 'Bereš/Pouštíš Osobu')
				ExecuteCommand('me Bere/Poušťí Osobu')
				TriggerServerEvent('esx_policejob:drag', GetPlayerServerId(closestPlayer))
			elseif action == 'put_in_vehicle' then
				--exports['pogressBar']:drawBar(3760, 'Dávaš osobu do vozidla')
				ExecuteCommand('me Dává osobu do vozidla')
				TriggerServerEvent('esx_policejob:putInVehicle', GetPlayerServerId(closestPlayer))
			elseif action == 'out_the_vehicle' then
				--exports['pogressBar']:drawBar(3760, 'Vyndávaš osobu z vozidla')
				ExecuteCommand('me Vyndává osobu z vozidla')
				TriggerServerEvent('esx_policejob:OutVehicle', GetPlayerServerId(closestPlayer))
			end

    	else
			--exports['dopeNotify']:Alert("Server", "Poblíž vás se nikdo nenachází", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Poblíž vás se nikdo nenachází')
		end
	end, function(data2, menu2)
		menu2.close()
	end)
end
	




----------------------------------------------------------	
---------------- VEHICLE INTERACTION MENU ----------------
----------------------------------------------------------
function OpenVehicleInteractionMenu ()
	local elements  = {}

	if Config.LockAnyVehicleEnabled then
		table.insert(elements, {label = 'Zámek', value = 'lock_vehicle'})
	end

	if (IsPedSittingInAnyVehicle(PlayerPedId())) then
		if Config.LockAnyVehicleEnabled then
			table.insert(elements, {label = 'Uložit', value = 'save_vehicle'})
		end
		if Config.EngineEnabled then
			table.insert(elements, {label = 'Motor', value = 'engine_vehicle'})
		end
		if Config.DoorsEnabled then
			table.insert(elements, {label = 'Dveře', value = 'doors_vehicle'})
		end
		if Config.WindowsEnabled then
			table.insert(elements, {label = 'Okna', value = 'window_vehicle'})
		end
		if Config.SeatsEnabled then
			table.insert(elements, {label = 'Sedadlo', value = 'seats_vehicle'})
		end
		if Config.NeonsEnabled then
			table.insert(elements, {label = 'Neony', value = 'neon_vehicle'})
		end
		if Config.ColorHeadlightsEnabled then
			table.insert(elements, {label = 'Světla', value = 'headlights_vehicle'})
		end
		if Config.ExtrasEnabled then
			table.insert(elements, {label = 'Extra', value = 'extras'})
		end
		if Config.LiveriesEnabled then
			table.insert(elements, {label = 'Polepy', value = 'liveries'})
		end
		if Config.ShowCarPlateEnabled then
			table.insert(elements, {label = 'Zobrazit SPZ', value = 'show_spz'})
		end
	end	


	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_interaction', {
		title    = 'Vozidlo',
		align    = 'right',
		elements = elements	
	}, 
		function(data2, menu2)
		action  = data2.current.value

		if action == 'engine_vehicle' then
			VehicleEngineControl ()
			
		elseif action == 'doors_vehicle' then
			OpenVehicleDoorMenu ()
		
		elseif action == 'window_vehicle' then
			OpenVehicleWindowMenu()

		elseif action == 'seats_vehicle' then
			OpenVehicleSeatsMenu()
			
		elseif action == 'neon_vehicle' then
			OpenVehicleNeonMenu ()

		elseif action == 'lock_vehicle' then
			LockVehicle()
		elseif action == 'save_vehicle' then
			TriggerEvent('hs_f5menu:SaveVehicle')
				
		elseif action == 'show_spz' then
			--local vehicleData = ESX.Game.GetVehicleProperties(vehicle)
			--OpenVehicleInfosMenu(vehicleData)
			--exports['dopeNotify']:Alert("Server", "SPZ Vozidla (GetVehicleNumberPlateText(GetVehiclePedIsUsing(PlayerPedId(), false)))", Time, 'info')
			--exports['mythic_notify']:DoHudText('inform', 'SPZ - ' ..(GetVehicleNumberPlateText(GetVehiclePedIsUsing(PlayerPedId(), false))))
		
		elseif action == 'liveries' then
			local veh = GetVehiclePedIsUsing(PlayerPedId())
			SetVehicleModKit(veh, 0)
			if GetVehicleLiveryCount(veh) == -1 and GetNumVehicleMods(veh, 48) == 0 then
				--exports['dopeNotify']:Alert("Server", "Toto vozidlo nemá žádné livery", 5000, 'error')
				--exports['mythic_notify']:DoHudText('error', 'Toto vozidlo nemá žádné livery')
			else
				OpenLiveryMenu()
			end
		elseif action == 'extras' then
			OpenVehicleExtraMenu()
		elseif action == 'headlights_vehicle' then
			OpenVehicleHeadlightMenu()
		end

	end, function(data2, menu2)
		menu2.close()
	end)
end

----------------------------------------------------------------------------
-------------------------------- OPEN BILL MENU ----------------------------
----------------------------------------------------------------------------
function ShowBillsMenu()

	ESX.TriggerServerCallback('esx_billing:getBills', function(bills, actualtime)
		ESX.UI.Menu.Close()
		local elements = {}
			for i=1, #bills, 1 do
				local expiration = bills[i].expiration
				local percentage = (math.floor(bills[i].amount/25)*10)

				if expiration > actualtime then
				    table.insert(elements, {
				    	label  = ('<span style="color:green;">Zaplatit</span> %s - <span style="color:green;">%s</span> | Čas %s'):format(bills[i].label, ESX.Math.GroupDigits(bills[i].amount).. ' $', bills[i].date),
				    	billID = bills[i].id
					})
				else
					table.insert(elements, {
				    	label  = ('<span style="color:red;">(Expirovaná faktura)</span> %s - <span style="color:green;">%s</span> <span style="color:red;">+ ' ..percentage.. '$ </span>| Datum %s'):format(bills[i].label, ESX.Math.GroupDigits(bills[i].amount), bills[i].date),
				    	billID = bills[i].id
					})
				end
			end
		

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'show_invoices',
		{
			title    = 'Faktury',
			align    = 'right',
			elements = elements
		}, function(data, menu)
			menu.close()

			ESX.TriggerServerCallback('esx_billing:payBill', function()
				ShowBillsMenu()
			end, data.current.billID)
		end, function(data, menu)
			menu.close()
		end)
	end)
end





----------------------------------------------------------------------------
-------------------------------- OPEN LICENSE MENU -------------------------
----------------------------------------------------------------------------
function OpenLicensesMenu ()
	local elements = {
		{label = 'Zobrazit ID', value = 'checkID'},
		{label = 'Zobrazit Řidičský Průkaz', value = 'checkDriver'},
		{label = 'Zobrazit Zbrojní Průkaz', value = 'checkFirearms'},
		{label = 'Ukázat ID', value = 'showID'},
		{label = 'Ukázat Řidičský Průkaz', value = 'showDriver'},
		{label = 'Ukázat Zbrojní Průkaz', value = 'showFirearms'},
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'id_menu', {
		title    = 'Vaše Doklady',
		align    = 'bottom-right',
		elements = elements
	}, function(data2, menu2)
		local action = data2.current.value


		if action == 'checkID' then
			TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
		
		elseif action == 'showID' then
			local player, distance = ESX.Game.GetClosestPlayer()

			if distance ~= -1 and distance <= 3.0 then
				TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(player))
				OpenTrashCan()
			else
				--exports['dopeNotify']:Alert("Server", "Poblíž vás se nikdo nenachází", 5000, 'error')
				--exports['mythic_notify']:DoHudText('error', 'Poblíž vás se nikdo nenachází')
			end
		
		elseif action == 'checkDriver' then
			TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
		
		elseif action == 'showDriver' then
			local player, distance = ESX.Game.GetClosestPlayer()

			if distance ~= -1 and distance <= 3.0 then
				TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(player), 'driver')
				OpenTrashCan()
			else
				--exports['dopeNotify']:Alert("Server", "Poblíž vás se nikdo nenachází", 5000, 'error')
				--exports['mythic_notify']:DoHudText('error', 'Poblíž vás se nikdo nenachází')
			end
		
		elseif action == 'showFirearms' then
			local player, distance = ESX.Game.GetClosestPlayer()

			if distance ~= -1 and distance <= 3.0 then
				TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(player), 'weapon')
				OpenTrashCan()
			else
				--exports['dopeNotify']:Alert("Server", "Poblíž vás se nikdo nenachází", 5000, 'error')
				--exports['mythic_notify']:DoHudText('error', 'Poblíž vás se nikdo nenachází')
			end
		
		elseif action == 'checkFirearms' then
			TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'weapon')
		end

	end, function(data2, menu2)
		menu2.close()
	end)
end

function OpenTrashCan()
    local pid = PlayerPedId()
    RequestAnimDict("mp_common")
    while (not HasAnimDictLoaded("mp_common")) do 
		Citizen.Wait(10) 
	end
	TaskPlayAnim(pid, "mp_common", "givetake2_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
	Citizen.Wait(2000)
    ClearPedTasks(pid)
end


----------------------------------------------------------------------------
-------------------------------- PORTFOLIO MENU ----------------------------
----------------------------------------------------------------------------
function OpenPortFolioMenu()
	local elements  = {}

	table.insert(elements, {label = (''..PlayerData.job.label..' - '..PlayerData.job.grade_label..''), value = ''})

	if PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss'  or  PlayerData.job.grade_name == 'boss_shrf' then
		if societymoney ~= nil then
			table.insert(elements, {label = (''..societymoney..' $'), value = ''})
		end
	end
	--table.insert(elements, {label = ('Hotovost: '..ESX.Math.GroupDigits(PlayerData.money)..' $'), value = ''})

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'portfolio_menu', {
		title    = ''..PlayerData.job.label..'',
		align    = 'right',
		elements = elements	
	}, 
		function(data2, menu2)
	end, function(data2, menu2)
		menu2.close()
	end)

end

function RefreshMoney()
	if PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss'  or  PlayerData.job.grade_name == 'boss_shrf' then
		ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
			UpdateSocietyMoney(money)
		end, PlayerData.job.name)
	end
end

RegisterNetEvent('esx_addonaccount:setMoney')
AddEventHandler('esx_addonaccount:setMoney', function(society, money)
	if PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss' and 'society_' .. PlayerData.job.name == society then
		UpdateSocietyMoney(money)
	end
end)

function UpdateSocietyMoney(money)
	societymoney = ESX.Math.GroupDigits(money)
end

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- SEARCH ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
function OpenBodySearchMenu()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	local searchPlayerPed = GetPlayerPed(closestPlayer)

		if IsEntityPlayingAnim(searchPlayerPed, 'mp_arresting', 'idle', 3) or IsEntityPlayingAnim(searchPlayerPed, 'random@mugging3', 'handsup_standing_base', 3) or DecorGetBool(searchPlayerPed, 'isDead') then
			-- exports['mythic_progbar']:Progress({
			-- name = "stealing",
			-- duration = 8000,
			-- label = 'Okrádáte hrace',
			-- useWhileDead = false,
			-- canCancel = true,
			-- controlDisables = {
			-- 	disableMovement = true,
			-- 	disableCarMovement = true,
			-- 	disableMouse = false,
			-- 	disableCombat = true,
			-- },
			-- }, function(cancelled)
			-- 	if not cancelled then
			-- 		exports['mythic_notify']:DoHudText('inform', 'Prohledáváte hráče ' .. GetPlayerName(closestPlayer))
			-- 		TriggerServerEvent('esx_policejob:message', GetPlayerServerId(closestPlayer), ('Jste prohledáván'))
			-- 		OpenInventoryHud(closestPlayer)
			-- 	else
			-- 		--exports['dopeNotify']:Alert("Server", "Přestali jste prohledávat hráče", 5000, 'error')
			-- 		exports['mythic_notify']:DoHudText('error', 'Přestali jste prohledávat hráče')
			-- 	end
			-- end)
		else
			--exports['dopeNotify']:Alert("Server", "Akce není možná, osoba musí mít ruce nahoře, mít spoutané ruce nebo být mrtvá", 7000, 'error')
		--	exports['mythic_notify']:DoHudText('error', 'Akce není možná, osoba musí mít ruce nahoře, mít spoutané ruce nebo být mrtvá', 7000)
		end

    function OpenInventoryHud(player)
	    TriggerEvent("esx_inveRFLXntoryhud:openPlRFLXayerInventory", GetPlayerServerId(player), GetPlayerName(player))
    end
end





-------------------------------------------------------------------------------------------------------------------------------------------
------------------------------CUFF/UNCUFF/PUT IN/PUT OUT/DRAG------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('hs_f5menu:drag')
AddEventHandler('hs_f5menu:drag', function(copId)
	if not isHandcuffed or IsPedDeadOrDying(copId) == false then
		return
	end
	--TriggerServerEvent('hs_f5menu:dragmess')

	dragStatus.isDragged = not dragStatus.isDragged
	dragStatus.CopId = copId
end)

Citizen.CreateThread(function()  --- in feature try optimalize that code
	local playerPed
	local targetPed

	while true do
		Citizen.Wait(1)

		if isHandcuffed then
			playerPed = PlayerPedId()

			if dragStatus.isDragged then
				targetPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.CopId))

				-- undrag if target is in an vehicle
				if not IsPedSittingInAnyVehicle(targetPed) then
					AttachEntityToEntity(playerPed, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
				else
					dragStatus.isDragged = false
					DetachEntity(playerPed, true, false)
				end

				if IsPedDeadOrDying(targetPed, true) then
					dragStatus.isDragged = false
					DetachEntity(playerPed, true, false)
				end

			else
				DetachEntity(playerPed, true, false)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('hs_f5menu:putInVehicle')
AddEventHandler('hs_f5menu:putInVehicle', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	if not isHandcuffed then
		return
	end

	if IsAnyVehicleNearPoint(coords, 5.0) then
		local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

			for i=maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle, i) then
					freeSeat = i
					break
				end
			end

			if freeSeat then
				TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
				dragStatus.isDragged = false
			end
			--TriggerServerEvent('hs_f5menu:putInVehiclemess')
		end
	end
end)

RegisterNetEvent('hs_f5menu:OutVehicle')
AddEventHandler('hs_f5menu:OutVehicle', function()
	local playerPed = PlayerPedId()

	if not IsPedSittingInAnyVehicle(playerPed) then
		return
	end

	local vehicle = GetVehiclePedIsIn(playerPed, false)
	TaskLeaveVehicle(playerPed, vehicle, 16)
	--TriggerServerEvent('hs_f5menu:OutVehiclemess')
end)






--------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- HAND CUFF --------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()  --- in feature try optimalize that code
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if isHandcuffed then
			DisableControlAction(0, 1, true) -- Disable pan
			DisableControlAction(0, 2, true) -- Disable tilt
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			--DisableControlAction(0, 32, true) -- W
			--DisableControlAction(0, 34, true) -- A
			--DisableControlAction(0, 31, true) -- S
			--DisableControlAction(0, 30, true) -- D

			DisableControlAction(0, 45, true) -- Reload
			--DisableControlAction(0, 22, true) -- Jump
			--DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 131, true) -- Sprint
			DisableControlAction(0, 23, true) -- Also 'enter'?

			DisableControlAction(0, 288,  true) -- Disable phone
			DisableControlAction(0, 289, true) -- Inventory
			DisableControlAction(0, 170, true) -- Animations
			DisableControlAction(0, 167, true) -- Job

			DisableControlAction(0, 0, true) -- Disable changing view
			DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(2, 199, true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle

			DisableControlAction(2, 36, true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle

			if IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3) ~= 1 then
				ESX.Streaming.RequestAnimDict('mp_arresting', function()
					TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
				end)
			end
		else
			Citizen.Wait(500)
		end
	end
end)
--[[
Citizen.CreateThread(function()
    local wasgettingup = false
    while true do
        Citizen.Wait(250)
        if IsHandcuffed then
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3) and not IsEntityPlayingAnim(ped, "mp_arrest_paired", "crook_p2_back_right", 3) or (wasgettingup and not IsPedGettingUp(ped)) then ESX.Streaming.RequestAnimDict("mp_arresting", function() TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0) end) end
            wasgettingup = IsPedGettingUp(ped)
        end
    end
end)
]]--

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
	TriggerEvent('hs_f5menu:unrestrain')

	if not hasAlreadyJoined then
		TriggerServerEvent('hs_f5menu:spawned')
	end
	hasAlreadyJoined = true
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('hs_f5menu:unrestrain')

		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
	end
end)

-- handcuff timer, unrestrain the player after an certain amount of time
function StartHandcuffTimer()
	if Config.EnableHandcuffTimer and handcuffTimer.active then
		ESX.ClearTimeout(handcuffTimer.task)
	end

	handcuffTimer.active = true

	handcuffTimer.task = ESX.SetTimeout(Config.HandcuffTimer, function()
		--exports['dopeNotify']:Alert("Server", "Pouta se rozbila, utíkejte!", 5000, 'info')
		--exports['mythic_notify']:DoHudText('inform', 'Pouta se rozbila, utíkejte!')

		TriggerEvent('hs_f5menu:unrestrain')
		handcuffTimer.active = false
	end)
end

RegisterNetEvent('hs_f5menu:handcuff')
AddEventHandler('hs_f5menu:handcuff', function()
	isHandcuffed = not isHandcuffed
	local playerPed = PlayerPedId()

	Citizen.CreateThread(function()
		if isHandcuffed then

			RequestAnimDict('mp_arresting')
			while not HasAnimDictLoaded('mp_arresting') do
				Citizen.Wait(100)
			end
			TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)

			SetEnableHandcuffs(playerPed, true)
			DisablePlayerFiring(playerPed, true)
			SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) -- unarm player
			SetPedCanPlayGestureAnims(playerPed, false)
			--FreezeEntityPosition(playerPed, true)
			-- DisplayRadar(false)

			if Config.EnableHandcuffTimer then
				if handcuffTimer.active then
					ESX.ClearTimeout(handcuffTimer.task)
				end

				StartHandcuffTimer()
			end
		else
			if Config.EnableHandcuffTimer and handcuffTimer.active then
				ESX.ClearTimeout(handcuffTimer.task)
			end

			ClearPedSecondaryTask(playerPed)
			SetEnableHandcuffs(playerPed, false)
			DisablePlayerFiring(playerPed, false)
			SetPedCanPlayGestureAnims(playerPed, true)
			--FreezeEntityPosition(playerPed, false)
			-- DisplayRadar(true)
		end
	end)
end)

RegisterNetEvent('hs_f5menu:unrestrain')
AddEventHandler('hs_f5menu:unrestrain', function()
	if isHandcuffed then
		local playerPed = PlayerPedId()
		isHandcuffed = false

		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		-- DisplayRadar(true)

		-- end timer
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
		TriggerServerEvent('hs_f5menu:uncuffed')
	end
end)


RegisterNetEvent('hs_f5menu:unrestrain')
AddEventHandler('hs_f5menu:unrestrain', function()
	 while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        if IsHandcuffed then
            SetEnableHandcuffs(playerPed, true)
            DisablePlayerFiring(playerPed, true)
            SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
            SetPedCanPlayGestureAnims(playerPed, false)
            -- DisplayRadar(false)
            DisableControlAction(0, 140, true)
        end
        if not IsHandcuffed and not IsControlEnabled(0, 140) then EnableControlAction(0, 140, true) end
    end
end)





----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- SHOW PLATE -----------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
function OpenVehicleInfosMenu(vehicleData)
	ESX.TriggerServerCallback('hs_f5menu:getVehicleInfos', function(retrivedInfo)
		
		if retrivedInfo.plate then
			--exports['dopeNotify']:Alert("Server", "SPZ - " ..retrivedInfo.plate, 5000, 'info')
		   -- exports['mythic_notify']:DoHudText('inform', 'SPZ - ' ..retrivedInfo.plate, '6500')
	    else
			--exports['dopeNotify']:Alert("Server", "Poblíž tebe se nenachází žádné vozidlo", 5000, 'info')
		   -- exports['mythic_notify']:DoHudText('error', 'Poblíž tebe se nenachází žádné vozidlo')
		end

	end, vehicleData.plate)
end

------------------------------------------------------------------------------------------------------------------------------
-------------------- SAVE / LOCK VEHICLES ------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('hs_f5menu:SaveVehicle')
AddEventHandler('hs_f5menu:SaveVehicle', function()
	local player = PlayerPedId()
	if (IsPedSittingInAnyVehicle(player)) then
		vehicle = GetVehiclePedIsIn(player,true) 
		exports["rflx_vehlock"]:givePlayerKeys(GetVehicleNumberPlateText(vehicle))
		--exports['dopeNotify']:Alert("Server", GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))).. "je nyní tvoje vozidlo!", 5000, 'success')
		--exports['mythic_notify']:DoHudText('inform', GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))).. ' je nyní tvoje vozidlo!')
	else
		--exports['dopeNotify']:Alert("Server", "Musíte sedět ve vozidle", 5000, 'error')
		--exports['mythic_notify']:DoHudText('error', 'Musíte sedět ve vozidle')
	end	
end)

function LockVehicle()
	local player = PlayerPedId()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        local vehicle = GetVehiclePedIsIn(player,true) 
		exports["rflx_vehlock"]:toggleLock(vehicle)
    else
		local vehicle = ESX.Game.GetClosestVehicle()
        if DoesEntityExist(vehicle) then
			exports["rflx_vehlock"]:toggleLock(vehicle)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- OWNED CAR LOCK -----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
RegisterCommand('LockOwnedVehicle', function ()
	LockVehicle()
end)

----------------------------------------------------------------------------------------------------------------------------
--------- HEADBAG ----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
function OpenHeadBagMenu()
	local elements = {
		{label = 'Nasadit pytel', value = 'puton'},
		{label = 'Sundat pytel', value = 'putoff'},
	}
  ESX.UI.Menu.CloseAll()
  ESX.UI.Menu.Open(
	'default', GetCurrentResourceName(), 'head_bag',
	{
	  title    = 'Pytel na hlavu',
	  align    = 'right',
	  elements = elements,
	  },
		function(data2, menu2)
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then		
		        if data2.current.value == 'puton' then
				    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					local player = PlayerPedId()
					local BagPlayerPed = GetPlayerPed(closestPlayer)
					if not HaveBagOnHead then
						if IsEntityPlayingAnim(BagPlayerPed, 'mp_arresting', 'idle', 3) or IsEntityPlayingAnim(BagPlayerPed, 'random@mugging3', 'handsup_standing_base', 3) or DecorGetBool(BagPlayerPed, 'isDead') then
						    TriggerServerEvent('hs_f5menu:sendclosest', GetPlayerServerId(closestPlayer))
							TriggerServerEvent('hs_f5menu:closest')
						else
							exports['mythic_notify']:DoHudText('error', 'Hráč musí mít ruce nahoře nebo být spoutaný')
						end
					else
						exports['mythic_notify']:DoHudText('error', 'Tento hráč má už jeden pytel na hlavě')
					end
			    end
			    if data2.current.value == 'putoff' then
				    TriggerServerEvent('hs_f5menu:headbag_putoff')
				end
			else
				--exports['dopeNotify']:Alert("Server", "Poblíž vás se nikdo nenachází", 5000, 'error')
				--exports['mythic_notify']:DoHudText('error', 'Poblíž vás se nikdo nenachází')
			end
	end, function(data2, menu2)
		menu2.close()
	end)
end

RegisterNetEvent('hs_f5menu:headbag_puton') --This event put head bag on nearest player
AddEventHandler('hs_f5menu:headbag_puton', function(gracz)
    local playerPed = PlayerPedId()
    Pytel = CreateObject(GetHashKey("prop_money_bag_01"), 0, 0, 0, true, true, true) -- Create head bag object!
    AttachEntityToEntity(Pytel, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 12844), 0.2, 0.04, 0, 0, 270.0, 60.0, true, true, false, true, 1, true) -- Attach object to head
    SetNuiFocus(false,false)
    SendNUIMessage({type = 'openGeneral'})
	HaveBagOnHead = true
	--TriggerServerEvent('hs_f5menu:headbagon')
	--exports['dopeNotify']:Alert("Server", "Někdo ti nasadil pytel na hlavu", 5000, 'info')
	--exports['mythic_notify']:DoHudText('inform', 'Někdo ti nasadil pytel na hlavu')
end)    

AddEventHandler('playerSpawned', function() --This event delete head bag when player is spawn again
DeleteEntity(Pytel)
SetEntityAsNoLongerNeeded(Pytel)
SendNUIMessage({type = 'closeAll'})
HaveBagOnHead = false
end)

RegisterNetEvent('hs_f5menu:headbag_putoffserver') --This event delete head bag from player head
AddEventHandler('hs_f5menu:headbag_putoffserver', function(gracz)
	--exports['dopeNotify']:Alert("Server", "Někdo ti sundal pytel z hlavy", 5000, 'info')
	--exports['mythic_notify']:DoHudText('inform', 'Někdo ti sundal pytel z hlavy')
    DeleteEntity(Pytel)
    SetEntityAsNoLongerNeeded(Pytel)
    SendNUIMessage({type = 'closeAll'})
	HaveBagOnHead = false
	--TriggerServerEvent('hs_f5menu:headbagoff')
	--if HaveBagOnHead then
		--TriggerServerEvent('hs_f5menu:giveheadbag')
	--end
end)





------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- MUGSHOT ------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function notification(title, text, msg)
	local mugshot, mugshotStr = ESX.Game.GetPedMugshot(PlayerPedId())
	ESX.ShowAdvancedNotification(title, text, msg, mugshotStr, 7)
	UnregisterPedheadshot(mugshot)
end




------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- VEHICLE WINDOWS MENU -----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenVehicleWindowMenu ()
	local elements  = {
		{label = 'Všechna okna', value = 'all_windows'},
		{label = 'Přední pravé okno', value = 'frontright_windows'},
		{label = 'Přední levé okno', value = 'frontleft_windows'},
		{label = 'Zadní pravé okno', value = 'backright_windows'},
		{label = 'Zadní levé okno', value = 'backleft_windows'},
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'window_vehicle', {
		title    = 'Ovládání oken',
		align    = 'right',
		elements = elements
	}, function(data3, menu3)
		action  = data3.current.value
		
		if (IsPedSittingInAnyVehicle(PlayerPedId())) then
			if action == 'all_windows' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if windowall == false then
					RollDownWindows(playerVeh, 0)
					windowall = true
				else
					RollUpWindow(playerVeh, 0)
					RollUpWindow(playerVeh, 1)
					RollUpWindow(playerVeh, 2)
					RollUpWindow(playerVeh, 3)
					windowall = false
				end
			elseif action == 'frontleft_windows' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if windowavg == false then
					RollDownWindow(playerVeh, 0)
					windowavg = true
				else
					RollUpWindow(playerVeh, 0)
					windowavg = false
				end
			elseif action == 'frontright_windows' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if windowavd == false then
					RollDownWindow(playerVeh, 1)
					windowavd = true
				else
					RollUpWindow(playerVeh, 1)
					windowavd = false
				end
			elseif action == 'backleft_windows' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
			
				if windowarg == false then
					RollDownWindow(playerVeh, 2)
					windowarg = true
				else
					RollUpWindow(playerVeh, 2)
					windowarg = false
				end
			elseif action == 'backright_windows' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if windoward == false then
					RollDownWindow(playerVeh, 3)
					windoward = true
				else
					RollUpWindow(playerVeh, 3)
					windoward = false
				end
			end
		else
			--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle')
		end
	end, function(data3, menu3)
		menu3.close()
	end)
end

------------------------------------------------------------------------------------------------------------------------
---------------------------------------------- VEHICLE SEATS MENU ------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenVehicleSeatsMenu ()
	local elements  = {
		{label = 'Sedadlo 1(Vodic)', value = 'seat_driver'},
		{label = 'Sedadlo 2(Spolujazdec)', value = 'seat_codriver'},
		{label = 'Sedadlo 3', value = 'seat_3'},
		{label = 'Sedadlo 4', value = 'seat_4'},
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'seats_vehicle', {
		title    = 'Zmena sedadla',
		align    = 'right',
		elements = elements
	}, function(data3, menu3)
		action  = data3.current.value
		
		if (IsPedSittingInAnyVehicle(PlayerPedId())) then
			if action == 'seat_driver' then
				local result = checkseat(-1)
				local status = nil
				if result then
					status = "volne"
					switchseat(-1)
				else
					status = "zabrane"
				end
			elseif action == 'seat_codriver' then
				local result = checkseat(0)
				local status = nil
				if result then
					status = "volne"
					switchseat(0)
				else
					status = "zabrane"
				end
			elseif action == 'seat_3' then
				local result = checkseat(1)
				local status = nil
				if result then
					status = "volne"
					switchseat(1)
				else
					status = "zabrane"
				end
			elseif action == 'seat_4' then
				local result = checkseat(2)
				local status = nil
				if result then
					status = "volne"
					switchseat(2)
				else
					status = "zabrane"
				end
			end
		else
			--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle')
		end
	end, function(data3, menu3)
		menu3.close()
	end)
end

function switchseat(pos)
    local pedveh = GetVehiclePedIsIn(PlayerPedId(), false)
    SetPedIntoVehicle(PlayerPedId(), pedveh, tonumber(pos))
    --exports['mythic_notify']:DoHudText('success', 'Teraz sedíš na sedadle: '..pos)
end

function getmaxseat()
    local pedveh = GetVehiclePedIsIn(PlayerPedId(), false)
    local maxseat = GetVehicleModelNumberOfSeats(maxseat)
    return maxseat
end

function checkseat(seat)
    local pedveh = GetVehiclePedIsIn(PlayerPedId(), false)
    local result = IsVehicleSeatFree(pedveh, tonumber(seat))
    return result
end
------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- VEHICLE ENGINE -----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function VehicleEngineControl ()

    if (IsPedSittingInAnyVehicle(PlayerPedId())) then
		local plyPed = PlayerPedId()
		local plyVehicle = GetVehiclePedIsIn(plyPed, false)
		local vehicleSpeedSource = GetEntitySpeed(plyVehicle)
		local vehicleSpeed = math.ceil(vehicleSpeedSource * 3.6)
		
		if vehicleSpeed > 5 then
			--exports['dopeNotify']:Alert("Server", "Pro vypnutí motoru musíte stát", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Pro vypnutí motoru musíte stát')
		else
			if GetIsVehicleEngineRunning(plyVehicle) then
				SetVehicleEngineOn(plyVehicle, false, false, true)
				SetVehicleUndriveable(plyVehicle, true)
			elseif not GetIsVehicleEngineRunning(plyVehicle) then
				SetVehicleEngineOn(plyVehicle, true, false, true)
				SetVehicleUndriveable(plyVehicle, false)
			end
		end
	else
		--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
		--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle')
	end
end


------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- OPEN VEHICLE DOOR MENU ---------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenVehicleDoorMenu ()
	local elements  = {
		{label = 'Všechny dveře', value = 'all_door'},
		{label = 'Kapota', value = 'hood_door'},
		{label = 'Kufr', value = 'trunk_door'},
		{label = 'Přední levé dveře', value = 'frontleft_door'},
		{label = 'Přední pravé dveře', value = 'frontright_door'},
		{label = 'Zadní levé dveře', value = 'backleft_door'},
		{label = 'Zadní pravé dveře', value = 'backright_door'},
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'doors_vehicle', {
		title    = 'Ovládání dveří ',
		align    = 'right',
		elements = elements
	}, function(data3, menu3)
		action  = data3.current.value
		
		if (IsPedSittingInAnyVehicle(PlayerPedId())) then
			if action == 'all_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 0) > 0.0 or GetVehicleDoorAngleRatio(playerVeh, 1) > 0.0 or GetVehicleDoorAngleRatio(playerVeh, 2) > 0.0 or GetVehicleDoorAngleRatio(playerVeh, 3) > 0.0 or GetVehicleDoorAngleRatio(playerVeh, 4) > 0.0 or GetVehicleDoorAngleRatio(playerVeh, 5) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 0, false)
					SetVehicleDoorShut(playerVeh, 1, false)
					SetVehicleDoorShut(playerVeh, 2, false)
					SetVehicleDoorShut(playerVeh, 3, false)
					SetVehicleDoorShut(playerVeh, 4, false)
					SetVehicleDoorShut(playerVeh, 5, false)
				else
					SetVehicleDoorOpen(playerVeh, 0, false)
					SetVehicleDoorOpen(playerVeh, 1, false)
					SetVehicleDoorOpen(playerVeh, 2, false)
					SetVehicleDoorOpen(playerVeh, 3, false)
					SetVehicleDoorOpen(playerVeh, 4, false)
					SetVehicleDoorOpen(playerVeh, 5, false)
				end
			elseif action == 'hood_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 4) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 4, false)
				else
					SetVehicleDoorOpen(playerVeh, 4, false)
				end
			elseif action == 'trunk_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 5) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 5, false)
				else
					SetVehicleDoorOpen(playerVeh, 5, false)
				end
			elseif action == 'frontleft_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 0) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 0, false)
				else
					SetVehicleDoorOpen(playerVeh, 0, false)
				end
			elseif action == 'frontright_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 1) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 1, false)
				else
					SetVehicleDoorOpen(playerVeh, 1, false)
				end
			elseif action == 'backleft_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 2) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 2, false)
				else
					SetVehicleDoorOpen(playerVeh, 2, false)
				end
			elseif action == 'backright_door' then
				local playerPed = PlayerPedId()
				local playerVeh = GetVehiclePedIsIn(playerPed, false)
				
				if GetVehicleDoorAngleRatio(playerVeh, 3) > 0.0 then 
					SetVehicleDoorShut(playerVeh, 3, false)
				else
					SetVehicleDoorOpen(playerVeh, 3, false)
				end
			end	
		else
			--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle')
		end
	end, function(data3, menu3)
		menu3.close()
	end)
end




------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- OPEN VEHICLE NEON MENU ---------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenVehicleNeonMenu ()
	local elements  = {
		{label = 'Všechny neony', value = 'neon_all'},
		{label = 'Přední neony', value = 'neon_front'},
		{label = 'Zadní neony', value = 'neon_back'},
		{label = 'Levé neony', value = 'neon_left'},
		{label = 'Pravé neony', value = 'neon_right'},
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'neon_vehicle', {
		title    = 'Ovládání neonů',
		align    = 'right',
		elements = elements
	}, function(data3, menu3)
		action  = data3.current.value
	
		if (IsPedSittingInAnyVehicle(PlayerPedId())) then
			if action == 'neon_all' then
				local ped = PlayerPedId()
				local veh = GetVehiclePedIsIn(ped, false)
				
				if isOn then
					SetVehicleNeonLightEnabled(veh, 0, false)
					SetVehicleNeonLightEnabled(veh, 1, false)
					SetVehicleNeonLightEnabled(veh, 2, false)
					SetVehicleNeonLightEnabled(veh, 3, false)	
					isOn = false
				else
					SetVehicleNeonLightEnabled(veh, 0, true)
					SetVehicleNeonLightEnabled(veh, 1, true)
					SetVehicleNeonLightEnabled(veh, 2, true)
					SetVehicleNeonLightEnabled(veh, 3, true)
					isOn = true
			   end
			elseif action == 'neon_front' then
				local ped = PlayerPedId()
				local veh = GetVehiclePedIsIn(ped, false)
				
				if IsVehicleNeonLightEnabled(veh, 2) then
					SetVehicleNeonLightEnabled(veh, 2, false)
				else
					SetVehicleNeonLightEnabled(veh, 2, true)
					isOn = true
				end
			elseif action == 'neon_back' then
				local ped = PlayerPedId()
				local veh = GetVehiclePedIsIn(ped, false)
				
				if IsVehicleNeonLightEnabled(veh, 3) then
					SetVehicleNeonLightEnabled(veh, 3, false)
				else
					SetVehicleNeonLightEnabled(veh, 3, true)
					isOn = true
				end
			elseif action == 'neon_left'	then
				local ped = PlayerPedId()
				local veh = GetVehiclePedIsIn(ped, false)
			
				if IsVehicleNeonLightEnabled(veh, 0) then
					SetVehicleNeonLightEnabled(veh, 0, false)
				else
					SetVehicleNeonLightEnabled(veh, 0, true)
					isOn = true
				end
			elseif action == 'neon_right' then
				local ped = PlayerPedId()
				local veh = GetVehiclePedIsIn(ped, false)
				
				if IsVehicleNeonLightEnabled(veh, 1) then
					SetVehicleNeonLightEnabled(veh, 1, false)
				else
					SetVehicleNeonLightEnabled(veh, 1, true)
					isOn = true
				end
			end
		else
			--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle')
		end
	end, function(data3, menu3)
		menu3.close()
	end)
end




------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- OPEN VEHICLE EXTRA MENU --------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenVehicleExtraMenu()
	local elements = {}
    local veh = GetVehiclePedIsUsing(PlayerPedId())

    for i = 0, 16 do
        if DoesExtraExist(veh, i) then
            if IsVehicleExtraTurnedOn(veh, i) then
		        table.insert(elements, {label = '<span style="color:green;">Extra ' .. i .. '</span>', value = i})
            else
		        table.insert(elements, {label = '<span style="color:red;">Extra ' .. i .. '</span>', value = i})
			end
	    end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'extras',
	  {
		title    = 'Extra tuning',
		align    = 'right',
		elements = elements,
	  },
	  function(data3, menu3)
		local action = data3.current.value

		if IsVehicleExtraTurnedOn(veh, action) then
			SetVehicleExtra(veh, action, true)
			ESX.UI.Menu.CloseAll()
			Wait(250)
			OpenVehicleExtraMenu()
		else
			SetVehicleAutoRepairDisabled(veh, true)
			SetVehicleExtra(veh, action, false)
			ESX.UI.Menu.CloseAll()
			Wait(250)
			OpenVehicleExtraMenu()
		end
	end,
	function(data3, menu3)
	    menu3.close()
	end)
end



------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- LIVERY MENU --------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenLiveryMenu()
	local elements  = {}
	local createdLiveries = 0
	local playerPed = PlayerPedId()
	local veh = GetVehiclePedIsIn(playerPed)

	table.insert(elements, {label = '<span style="color:red;">Základní</span>', value = 'default'})

	local liveryCount = GetVehicleLiveryCount(veh)
	for i = 1, (liveryCount - 1) do
		createdLiveries = createdLiveries + 1
		table.insert(elements, {label = 'Livery - '..(createdLiveries), value = 'livery'..i})
	end

	local modCount = GetNumVehicleMods(veh, 48)
	for i = 0, (modCount - 1) do
		createdLiveries = createdLiveries + 1
		local name = GetLabelText(GetModTextLabel(veh, 48, i))
		table.insert(elements, {label = 'Livery - '..(name ~= 'NULL' and name or createdLiveries), value = 'mod'..i})
	end


	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'neon_vehicle', {
		title    = 'Livery',
		align    = 'right',
		elements = elements
	}, function(data3, menu3)
		local action  = data3.current.value

		if (IsPedSittingInAnyVehicle(playerPed)) then
			if action == 'default' then
				if modCount ~= 0 then
					SetVehicleMod(veh, 48, -1)
				end
				if liveryCount ~= -1 then
					SetVehicleLivery(veh, 0)
				end
				
			elseif string.find(action, 'livery') then
				local num = string.gsub(action, 'livery', '')
				num = tonumber(num)
				SetVehicleLivery(veh, num)
			elseif string.find(action, 'mod') then
				local num = string.gsub(action, 'mod', '')
				num = tonumber(num)
				SetVehicleMod(veh, 48, num)
			end
		else
			--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle')
		end
	end, function(data3, menu3)
		menu3.close()
	end)
end
------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- VEHICLE HEADLIGHT MENU ---------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function OpenVehicleHeadlightMenu ()
	local elements  = {
		{label = '<span style="color:lightcyan;">Xenon</span>',                 value = 'headlight255'},
		{label = '<span style="color:white;">Bílá</span>',                      value = 'headlight0'},
		{label = '<span style="color:blue;">Modrá</span>',                      value = 'headlight1'},
		{label = '<span style="color:deepskyblue;">Světle modrá</span>',        value = 'headlight2'},
		{label = '<span style="color:mediumspringgreen;">Mátově zelená</span>', value = 'headlight3'},
		{label = '<span style="color:greenyellow;">Limetkově zelená</span>',    value = 'headlight4'},
		{label = '<span style="color:khaki;">Žlutá</span>',		                value = 'headlight5'},
		{label = '<span style="color:gold;">Zlatá</span>',	                    value = 'headlight6'},
		{label = '<span style="color:orange;">Oranžová</span>',		            value = 'headlight7'},
		{label = '<span style="color:red;">Červená</span>',	                    value = 'headlight8'},
		{label = '<span style="color:hotpink;">Růžová</span>',		            value = 'headlight9'},
		{label = '<span style="color:magenta;">Tmavě růžová</span>',	        value = 'headlight10'},
		{label = '<span style="color:darkviolet;">Fialová</span>',		        value = 'headlight11'},
		{label = '<span style="color:darkslateblue;">Tmavě fialová</span>',	    value = 'headlight12'},
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'headlights_vehicle', {
		title    = 'Barva světel',
		align    = 'right',
		elements = elements
	}, function(data3, menu3)
		action = data3.current.value
		local veh = GetVehiclePedIsUsing(PlayerPedId())
		if not (veh == nil) then
			TriggerServerEvent('hs_f5menu:changeHeadlights', action, veh)
		else
			--exports['dopeNotify']:Alert("Server", "Nenacházíte se ve vozidle", 5000, 'error')
			--exports['mythic_notify']:DoHudText('error', 'Nenacházíte se ve vozidle!')
		end
	end, function(data3, menu3)
		menu3.close()
	end)
end

RegisterNetEvent('hs_f5menu:clientHeadlights')
AddEventHandler('hs_f5menu:clientHeadlights', function(action, vehicle)
	local veh = vehicle
	local num = string.gsub(action, 'headlight', '')
	num = tonumber(num)
	NetworkRequestControlOfEntity(veh)
	ToggleVehicleMod(veh, 22, true)
	SetVehicleXenonLightsColour(veh, num)
end)


function cancelEmote()
	ClearPedTasksImmediately(PlayerPedId())
	emotePlaying = false
end

function playAnimation(dictionary, animation)
	if emotePlaying then
		cancelEmote()
	end
	RequestAnimDict(dictionary)
	while not HasAnimDictLoaded(dictionary) do
		Wait(1)
	end
	TaskPlayAnim(PlayerPedId(), dictionary, animation, 8.0, 0.0, -1, 1, 0, 0, 0, 0)
	emotePlaying = true
end


------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- KEY CONTROL --------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if emotePlaying then
            if (IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35)) then
                cancelEmote()
			end
		else
			Wait(250)
        end
	end
end)

RegisterKeyMapping('EngineControl', '<font face = "Fire Sans">Zapnutí/vypnutí motoru', 'keyboard', 'INSERT')
RegisterKeyMapping('OpenRPMenu', '<font face = "Fire Sans">F5 Menu', 'keyboard', 'F5')
RegisterKeyMapping('LockOwnedVehicle', '<font face = "Fire Sans">Zamknout své vozidlo', 'keyboard', 'N+')

RegisterCommand('EngineControl', function ()
	if not isDead then
	    VehicleEngineControl()
	end
end)

RegisterCommand('OpenRPMenu', function ()
	if not isDead and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'hs_f5menu') then
	    OpenRPActionsMenu()
	end
end)