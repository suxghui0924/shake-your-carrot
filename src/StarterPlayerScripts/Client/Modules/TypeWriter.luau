local SoundController = require(script.Parent.Parent.Controllers.SoundController)

local TypeWriter = {}

function TypeWriter.Typing(object, text, delay, soundEnabled)
	if object:IsA("TextLabel") or object:IsA("TextBox") then
		object.Text = "" -- Reset text
		
		local cancelled = false
		local function cancel()
			cancelled = true
		end

		task.spawn(function()
			for char in text:gmatch(utf8.charpattern) do
				if cancelled then break end
				task.wait(delay)
				if cancelled then break end
				
				object.Text ..= char
				
				-- Play Sound
				if soundEnabled ~= false and SoundController then
					SoundController:PlaySound("typewriter", nil, 0.5)
				end
			end
		end)
		
		return cancel
	else
		warn("TypeWriter: object가 TextLabel이 아닙니다. 현재 클래스: "..object.ClassName)
		return function() end -- No-op cancel
	end
end

function TypeWriter.text(object, text, delay, soundEnabled)
    return TypeWriter.Typing(object, text, delay, soundEnabled)
end

return TypeWriter
