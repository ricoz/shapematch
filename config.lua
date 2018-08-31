application =
{

	content =
	{
		width = 320,
		height = 480, 
		scale = "letterbox",
		fps = 60,
		
		---[[
		imageSuffix =
		{
			    ["@2x"] = 1.5,
			    ["@3x"] = 3,
			    ["@4x"] = 4,
		},
		--]]
	},

	--[[
	-- Push notifications
	notification =
	{
		iphone =
		{
			types =
			{
				"badge", "sound", "alert", "newsstand"
			}
		}
	},
	--]]    
}
