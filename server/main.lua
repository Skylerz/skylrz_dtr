ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- getting info for players
function getIdentity(source)
	local identifier = GetPlayerIdentifiers(source)[1]
	local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = identifier})
	if result[1] ~= nil then
		local identity = result[1]

		return {
			identifier = identity['identifier'],
			firstname = identity['firstname'],
			lastname = identity['lastname'],
			dateofbirth = identity['dateofbirth'],
			sex = identity['sex'],
            height = identity['height'],
            job = identity['job']
			
		}
	else
		return nil
	end
end

-- function for time in
function timeIn(source, client, discord, identifier, time, job)
    local discordAttendance
    MySQL.Async.fetchAll('SELECT time_out FROM jobs_dtr WHERE users_identifier = @identifier AND time_out = "" ORDER BY ID DESC LIMIT 1', {
        ['@identifier']		= identifier,
    },function(data)
        if data[1] == nil then
            if job == 'ambulance' then 
                discordAttendance = 'lsmc-attendance'
            elseif job == 'police' then
                discordAttendance = 'lspd-attendance'
            elseif job == 'mechanic' then
                discordAttendance = 'lsc-attendance'
            end    
            MySQL.Async.execute('INSERT INTO jobs_dtr (users_identifier, time_in, jobs_name) VALUES (@identifier, @time, @jobs_name)', {
                ['@identifier']		= identifier,
                ['@time']		    = time,
                ['@jobs_name']		= job,
            }, function(rowsChanged)
                if rowsChanged ~= 0 then
                    print(rowsChanged)
                    TriggerClientEvent('chatMessage', source, '', { 255, 255, 255 }, client)
                    TriggerEvent('DiscordBot:ToDiscord', discordAttendance, GetPlayerName(source) .. ' [ID: ' .. source .. ']', discord, 'steam', true, source)
                else
                    return nil
                end
            end)
        else
            TriggerClientEvent('chatMessage', source , '', { 255, 255, 255 }, '^2 You have already have entry for this session')
        end
        
    end)
    
end   

-- function for time out
function timeOut(source, identifier, time)
    local discordAttendance
    MySQL.Async.execute('UPDATE `jobs_dtr` SET `time_out` = @time WHERE users_identifier = @identifier AND time_out = "" ORDER BY ID DESC LIMIT 1', {
        ['@identifier']		= identifier,
		['@time']		    = time,
    }, function(rowsChanged)
        print(rowsChanged)
        if rowsChanged ~= 0 then
            MySQL.Async.fetchAll('SELECT ROUND(TIMESTAMPDIFF(MINUTE, time_in, time_out)/60, 2) AS hours , jobs_name FROM jobs_dtr WHERE users_identifier = @identifier ORDER BY ID DESC LIMIT 1', {
                ['@identifier']		= identifier,
            }, function(data)
                if data[1].jobs_name == 'ambulance' then 
                    discordAttendance = 'lsmc-attendance'
                elseif data[1].jobs_name == 'police' then
                    discordAttendance = 'lspd-attendance'
                elseif data[1].jobs_name == 'mechanic' then
                    discordAttendance = 'lsc-attendance'
                end
                local discord = '```diff\n' .. '-TIME OUT | Hrs played this session: ' .. data[1].hours.. '\n```'
                local client = '^1 ' .. GetPlayerName(source) .. ', ^*TIME OUT has been logged on attendance. Total hrs played today: ' .. data[1].hours
                TriggerClientEvent('chatMessage', source, '', { 255, 255, 255 }, client)
                TriggerEvent('DiscordBot:ToDiscord', discordAttendance, GetPlayerName(source) .. ' [ID: ' .. source .. ']', discord, 'steam', true, source)
            end)
        else
            return nil
        end
	end)
end

-- total hrs rendered in current job
function checkTotalHours(source, identifier, name)
    MySQL.Async.fetchAll('SELECT SUM(ROUND(TIMESTAMPDIFF(MINUTE, time_in, time_out)/60, 2)) AS hours FROM jobs_dtr WHERE users_identifier = @identifier', {
        ['@identifier']		= identifier,
    }, function(data)
        print(data[1].hours)
        local client = '^5 Total hrs played: ' .. data[1].hours .. 'hrs'
        TriggerClientEvent('chatMessage', source, '', { 255, 255, 255 }, client)
    end)
end

-- for checking your currenthrs without using timeout
function checkSessionHours(source, identifier, name)
    MySQL.Async.fetchAll('SELECT * FROM jobs_dtr WHERE users_identifier = @identifier AND time_out = "" ORDER BY ID DESC LIMIT 1', {
        ['@identifier']		= identifier,
    },function(data)
        MySQL.Async.fetchAll('SELECT SUM(ROUND(TIMESTAMPDIFF(MINUTE, time_in, DATE_FORMAT(NOW(),"%Y-%m-%d %H:%i:%s"))/60, 2)) AS hours FROM jobs_dtr WHERE users_identifier = @identifier AND time_out = "" ORDER BY ID DESC LIMIT 1', {
            ['@identifier']		= identifier,
        }, function(hrs)
            if hrs[1].hours ~= nil then
                local client = '^5 Current hrs played: ' .. hrs[1].hours .. 'hrs'
                TriggerClientEvent('chatMessage', source, '', { 255, 255, 255 }, client)
            else    
                TriggerClientEvent('chatMessage', source , '', { 255, 255, 255 }, '^2 You need to time in to check your current session')
            end
        end)
    end)
end

-- anti exploit for hrs farming | auto timeout if player leaves/quit the game
AddEventHandler('playerDropped', function(reason)
    local id = source
    local discordAttendance
    local time = os.date("%Y-%m-%d %X")
    local playerName = GetPlayerName(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    split = stringsplit(identifier, ":");

    MySQL.Async.execute('UPDATE `jobs_dtr` SET `time_out` = @time WHERE users_identifier = @identifier AND time_out = "" ORDER BY ID DESC LIMIT 1', {
        ['@identifier']		= identifier,
		['@time']		    = time,
    }, function(rowsChanged)
        if rowsChanged ~= 0 then
            MySQL.Async.fetchAll('SELECT ROUND(TIMESTAMPDIFF(MINUTE, time_in, time_out)/60, 2) AS hours , jobs_name FROM jobs_dtr WHERE users_identifier = @identifier ORDER BY ID DESC LIMIT 1', {
                ['@identifier']		= identifier,
            }, function(data)
                if data[1].jobs_name == 'ambulance' then 
                    discordAttendance = 'lsmc-attendance'
                elseif data[1].jobs_name == 'police' then
                    discordAttendance = 'lspd-attendance'
                elseif data[1].jobs_name == 'mechanic' then
                    discordAttendance = 'lsc-attendance'
                end
                local discord = '```diff\n' .. '-TIME OUT | Hrs played this session: ' .. data[1].hours.. '\n```'
                TriggerEvent('DiscordBot:ToDiscord', discordAttendance, playerName .. ' [ID: ' .. id .. ']', discord, 'withoutid', true, '', split[2])
            end)
        else
            return nil
        end
	end)
end)

-- can be bind on your job duty marker i guess
RegisterCommand('duty', function(source, args, rawCommand)
    ESX.SavePlayers()
    print(getIdentity(source).job)
    local playerName = GetPlayerName(source)
    local msg = rawCommand:sub(6)
    local name = getIdentity(source)
    split = stringsplit(msg, " ");
    local discord = ''
    local client = ''
    local datetime = os.date("%Y-%m-%d %X")

    if getIdentity(source).job == 'ambulance' or getIdentity(source).job == 'police' or getIdentity(source).job == 'mechanic' then
        if split[1] == "in" then
            discord = '```diff\n' .. '+TIME IN' .. '\n```'
            client = '^2 ' .. GetPlayerName(source) .. ', ^*TIME IN has been logged on attendance' 
    
            timeIn(source, client, discord, getIdentity(source).identifier, datetime, getIdentity(source).job)
        elseif split[1] == "out" then
            discord = '```diff\n' .. '-TIME OUT' .. '\n```'
            client = '^1 ' .. GetPlayerName(source) .. ', ^*TIME OUT has been logged on attendance'
    
            timeOut(source, getIdentity(source).identifier, datetime)
        end
    else
        TriggerClientEvent('chatMessage', source, '', { 255, 255, 255 }, 'You are not whitelisted')
    end
    
end, false)

-- command for checking total hrs rendered
RegisterCommand('checkhrs', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    local msg = rawCommand:sub(10)
    local identifier = GetPlayerIdentifiers(source)[1]

    checkTotalHours(source, identifier)

end, false)

-- command for checking your current hrs played in this session without doing timeout
RegisterCommand('currenthrs', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    local msg = rawCommand:sub(10)
    local identifier = GetPlayerIdentifiers(source)[1]

    checkSessionHours(source, identifier)

end, false)

function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end