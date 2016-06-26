--[[
	Pointshop tmysql4 Adapter by xbeastguyx
		- Meant to follow a similar pattern to the original
	
	Setup: 
	
		Install the tmysql4 module:
			https://facepunch.com/showthread.php?t=1442438
			Instructions for installation are provided

		Set PS.Config.DataProvider = "tmysql"
]]--


local MySQL_Host = ""
local MySQL_User = ""
local MySQL_Pass = ""
local MySQL_Database = ""
local MySQL_Port = 3306


-- Do not edit below

local db, err

local function MySQL_Initialize()
	if !file.Exists( "bin/gmsv_tmysql4_*.dll", "LUA" ) then
		error( "tmysql4 is missing! Please install the tmysql4 module for proper connection." )
	end

	require( "tmysql4" )
	
	print( "PointShop MySQL: Connecting..." )
	
	db, err = tmysql.initialize( MySQL_Host, MySQL_User, MySQL_Pass, MySQL_Database, MySQL_Port )
	
	if err != nil or type( db ) == "boolean" then
		print( "PointShop MySQL: Error connecting to the database!" )
		print( "PointShop MySQL: Error: " .. err )
		return
	end
	
	print( "PointShop MySQL: Connected successfully." )
end

MySQL_Initialize()

local function MySQL_Query( str, callback, err )
	local function cb( res )
		res = res[ 1 ]
		
		if !res.status then
			local er = err and err( res.error, str )
			if !err then
				print( "Pointshop MySQL: " .. res.error .. " on query: " .. str )
			end
			return
		end
		
		if callback then
			callback( res.data, res.lastid, res.affected )
		end
	end

	db:Query( str, cb )
end

local function MySQL_CreateDatabase()
	MySQL_Query( "CREATE TABLE IF NOT EXISTS pointshop_data ( uniqueid varchar( 30 ) NOT NULL PRIMARY KEY, points int( 32 ) NOT NULL, items text NOT NULL )" )
end

MySQL_CreateDatabase()

function PROVIDER:GetData( ply, callback )
	MySQL_Query( "SELECT * FROM pointshop_data WHERE uniqueid = '" .. ply:UniqueID() .. "'", function( data )
		if data and istable( data ) then
			local row = data[ 1 ]
			local points = row.points
			local items = util.JSONToTable( row.items or "{}" )
			
			callback( points, items )
		else
			callback( 0, {} )
		end
	end )
end

function PROVIDER:SetPoints( ply, points )
	MySQL_Query( "INSERT INTO pointshop_data ( uniqueid, points, items ) VALUES ( '" .. ply:UniqueID() .. "', '" .. points .. "', '[]' ) ON DUPLICATE KEY UPDATE points = VALUES ( points )" )
end

function PROVIDER:GivePoints( ply, points )
	MySQL_Query( "INSERT INTO pointshop_data ( uniqueid, points, items ) VALUES ( '" .. ply:UniqueID() .. "', '" .. points .. "', '[]' ) ON DUPLICATE KEY UPDATE points = points + VALUES ( points )" )
end

function PROVIDER:TakePoints( ply, points )
	MySQL_Query( "INSERT INTO pointshop_data ( uniqueid, points, items ) VALUES ( '" .. ply:UniqueID() .. "', '" .. points .. "', '[]' ) ON DUPLICATE KEY UPDATE points = points - VALUES ( points )" )
end

function PROVIDER:SaveItem( ply, item_id, data )
	self:GiveItem( ply, item_id, data )
end

function PROVIDER:GiveItem( ply, item_id, data )
	local tmp = table.Copy( ply.PS_Items )
	tmp[ item_id ] = data
	
	MySQL_Query( "INSERT INTO pointshop_data ( uniqueid, points, items ) VALUES ( '" .. ply:UniqueID() .. "', '0', '" .. db:Escape( util.TableToJSON( tmp ) ) .. "' ) ON DUPLICATE KEY UPDATE items = VALUES ( items )" )
end

function PROVIDER:TakeItem( ply, item_id )
	local tmp = table.Copy( ply.PS_Items )
	tmp[ item_id ] = nil
	
	MySQL_Query( "INSERT INTO pointshop_data ( uniqueid, points, items ) VALUES ( '" .. ply:UniqueID() .. "', '0', '" .. db:Escape( util.TableToJSON( tmp ) ) .. "' ) ON DUPLICATE KEY UPDATE items = VALUES ( items )" )
end

function PROVIDER:SetData( ply, points, items )
	MySQL_Query( "INSERT INTO pointshop_data ( uniqueid, points, items ) VALUES ( '" .. ply:UniqueID() .. "', '" .. points .. "', '" .. items .."' ) ON DUPLICATE KEY UPDATE points = VALUES ( points ), items = VALUES( items )")
end