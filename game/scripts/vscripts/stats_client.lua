if StatsClient == nil then
	_G.StatsClient = class({})
end

StatsClient.ServerAddress = (IsInToolsMode() and "http://127.0.0.1:3228" or "https://angelarenablackstar-ark120202.rhcloud.com") .. "/AABSServer/"
function StatsClient:OnGameBegin()
	local data = {
		matchid = tostring(GameRules:GetMatchID()),
		players = {},
	}
	for i = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:IsValidPlayerID(i) and not IsPlayerAbandoned(i) then
			data.players[i] = {
				steam_id = tostring(PlayerResource:GetSteamID(i)),
			}
		end
	end
	--Should return rating table
	--[[StatsClient:Send("startMatch", data, function(response)
		PrintTable(response)
	end)]]
end
--StatsClient:OnGameBegin()
function StatsClient:OnGameEnd(winner)
	if not IsInToolsMode() and (GameRules:IsCheatMode() or GetInGamePlayerCount() < 8) then
		return
	end
	local data = {
		version = ARENA_VERSION,
		matchid = tostring(GameRules:GetMatchID()),
		WinnerTeam = winner,
		players = {},
		DuelsTimesTeamWins = Duel.TimesTeamWins,
	}
	for i = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:IsValidPlayerID(i) then
			local hero = PlayerResource:GetSelectedHeroEntity(i)
			local playerInfo = {
				abandoned = IsPlayerAbandoned(i),
				steamid = tostring(PlayerResource:GetSteamID(i)),
				stats = PLAYER_DATA[i].HeroStats or {},
				hero_name = HeroSelection:GetSelectedHeroName(i),
				team = tonumber(PlayerResource:GetTeam(i)),
				level = PLAYER_DATA[i].LevelBeforeAbandon or 0,
				items = {}
			}
			table.merge(playerInfo.stats, {
				Kills = PlayerResource:GetKills(i),
				Deaths = PlayerResource:GetDeaths(i),
				Assists = PlayerResource:GetAssists(i),
				Lasthits = PlayerResource:GetLastHits(i)
			})
			if IsValidEntity(hero) then
				playerInfo.level = hero:GetLevel()
				for item_slot = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
					local item = hero:GetItemInSlot(item_slot)
					if item then
						local charges = item:GetCurrentCharges()
						playerInfo.items[item_slot] = {
							name = item:GetAbilityName(),
							stacks = item:GetInitialCharges() ~= charges and charges or nil
						}
					end
				end
			end
			data.players[i] = playerInfo
		end
	end
	PrintTable(data)
	StatsClient:Send("endMatch", data, function(response)
		PrintTable(response)
	end, 4)
end
--StatsClient:OnGameEnd(2)
function StatsClient:HandleError(err)
	if err and type(err) == "string" then
		StatsClient:Send("HandleError", {
			version = ARENA_VERSION,
			text = err
		})
	end
end

function StatsClient:Send(path, data, callback, retryCount, _currentRetry)
	local request = CreateHTTPRequest('POST', self.ServerAddress .. path)
	request:SetHTTPRequestGetOrPostParameter("data", JSON:encode(data))
	request:Send(function(response)
		if response.StatusCode ~= 200 or not response.Body then
			print("error, status == " .. response.StatusCode)
			local currentRetry = (_currentRetry or 0) + 1
			if currentRetry < (retryCount or 0) then
				Timers:CreateTimer(1, function()
					print("Retry (" .. currentRetry .. ")")
					StatsClient:Send(path, data, callback, retryCount, currentRetry)
				end)
			end
		else
			local obj, pos, err = JSON:decode(response.Body, 1, nil)
			if callback then
				callback(obj)
			end
		end
	end)
end