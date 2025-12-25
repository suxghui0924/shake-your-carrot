return {
	Name = "globalmessage",
	Aliases = { "gm" },
	Description = "모든 서버에 메시지를 보냅니다.",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "메시지",
			Description = "보낼 메시지 내용 입니다.",
		},
	},
}
