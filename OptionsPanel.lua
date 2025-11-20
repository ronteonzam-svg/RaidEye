local L = LibStub("AceLocale-3.0"):GetLocale("RaidEye")
local AceConfig = LibStub("AceConfig-3.0")
local ipairs, max, min, pairs, tonumber = ipairs, max, min, pairs, tonumber

-- Таблица порядка классов для сортировки
local CLASS_ORDER = {
	WARRIOR = 1,
	PALADIN = 2,
	DEATHKNIGHT = 3,
	DRUID = 4,
	PRIEST = 5,
	SHAMAN = 6,
	HUNTER = 7,
	ROGUE = 8,
	MAGE = 9,
	WARLOCK = 10,
	RACIAL = 11,
	OTHER = 12,
}

-- Иконки классов
local CLASS_ICONS = {
	WARRIOR = "Interface\\ICONS\\ClassIcon_Warrior",
	PALADIN = "Interface\\ICONS\\ClassIcon_Paladin",
	DEATHKNIGHT = "Interface\\ICONS\\ClassIcon_DeathKnight",
	DRUID = "Interface\\ICONS\\ClassIcon_Druid",
	PRIEST = "Interface\\ICONS\\ClassIcon_Priest",
	SHAMAN = "Interface\\ICONS\\ClassIcon_Shaman",
	HUNTER = "Interface\\ICONS\\ClassIcon_Hunter",
	ROGUE = "Interface\\ICONS\\ClassIcon_Rogue",
	MAGE = "Interface\\ICONS\\ClassIcon_Mage",
	WARLOCK = "Interface\\ICONS\\ClassIcon_Warlock",
	RACIAL = "Interface\\ICONS\\Achievement_Character_Human_Male",
	OTHER = "Interface\\ICONS\\INV_Misc_QuestionMark",
}

function RaidEye:OptionsPanel()
	local myOptionsTable = {
		type = "group",
		childGroups = "tab",
		args = {
			

			linking = {
				name = L["Link to chat/whisper (Shift-Click/Ctrl-Click)"],
				desc = L["Enables ability to link remaining cooldown duration to raid/party chat. Disables click-through."],
				type = "toggle",
				set = function(_, val)
					self.db.global.link = val
					for i = 1, #self.groups do
						for j = 1, #self.groups[i].CooldownFrames do
							self:EnableMouse(self.groups[i].CooldownFrames[j], not val)
						end
					end
				end,
				get = function()
					return self.db.global.link
				end
			},
			selfignore = {
				name = L["Ignore myself"],
				desc = L["Do not show your own cooldowns."],
				type = "toggle",
				set = function(_, val)
					self.db.global.selfignore = val
					self:updateRaidCooldowns()
				end,
				get = function()
					return self.db.global.selfignore
				end
			},
			hidesolo = {
				name = L["Hide when not in raid"],
				desc = L["Do not show cooldowns when not in raid or party."],
				type = "toggle",
				set = function(_, val)
					self.db.global.hidesolo = val
					self:updateFramesVisibility()
				end,
				get = function()
					return self.db.global.hidesolo
				end
			},
			testMode = {
				name = L["Test Mode"],
				desc = L["Enable test mode to display sample abilities in each group for layout testing."],
				type = "toggle",
				set = function(_, val)
					self:setTestMode(val)
				end,
				get = function()
					return self.db.global.testMode
				end
			},
			frames = {
            name = L["Frames"],
            type = "group",
            childGroups = "tab",
            order = 1,
            args = {
                management = {
                    name = "Управление",
                    type = "group",
                    order = 0,
                    args = {
                        header = {
                            type = "header",
                            name = "Управление панелями",
                            order = 0,
                        },
                        addPanel = {
                            name = "Добавить панель",
                            type = "execute",
                            order = 1,
                            func = function() self:AddGroup() end,
                        },
                        removePanel = {
                            name = "Удалить последнюю панель",
                            type = "execute",
                            order = 2,
                            confirm = true,
                            confirmText = "Удалить последнюю панель? Заклинания с неё будут перенесены на Панель 1.",
                            func = function() self:RemoveLastGroup() end,
                        },
                        desc = {
                            type = "description",
                            name = "Вы можете создавать дополнительные панели для гибкой настройки. Удаление всегда убирает последнюю созданную панель.",
                            order = 3,
                        },
                    },
                },
            },
        },
			spells = {
				name = L["Spells"],
				type = "group",
				childGroups = "select",
				args = {},
				order = 2
			},
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
			comms = {
				name = L["Comms"],
				type = "group",
				args = {
					desc = {
						type = "header",
						name = L["Only change this if you have specific issues. Otherwise should be enabled."],
						order = 4
					}
				}
			}
		}
	}

	InterfaceOptionsFrame:SetWidth(max(min(1000, GetScreenWidth()), InterfaceOptionsFrame:GetWidth()))

	for i = 1, #self.groups do
		myOptionsTable.args.frames.args["frame" .. i] = {
			name = L["Frame"] .. " " .. i,
			order = i,
			type = "group",
			childGroups = "tab",
			args = {
				size = {
					name = L["Size and position"],
					type = "group",
					disabled = self.db.profile[i].inherit and i ~= 1,
					args = {
						frameWidth = {
							name = L["Frame width"],
							type = "range",
							min = 100,
							max = 300,
							step = 1,
							order = 1,
							get = function()
								return self.db.profile[i].frameWidth
							end,
							set = function(_, val)
								self.db.profile[i].frameWidth = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self.groups[j].CooldownFrames[k]:SetWidth(val)
											self:updateCooldownBarProgress(self.groups[j].CooldownFrames[k])
										end
										-- Update title bar width
										if self.groups[j].titleBar then
											self.groups[j].titleBar:SetWidth(val)
										end
									end
								end
							end
						},
						fontSize = {
							name = L["Font size"],
							type = "range",
							min = 8,
							max = 30,
							step = 1,
							order = 3,
							get = function()
								return self.db.profile[i].fontSize
							end,
							set = function(_, val)
								self.db.profile[i].fontSize = val
								local font
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											if not font then
												font = self.groups[j].CooldownFrames[k].playerNameFontString:GetFont()
											end
											self.groups[j].CooldownFrames[k].playerNameFontString:SetFont(font, val)
										end
									end
								end
							end
						},
						fontSizeTarget = {
							name = L["Target font size"],
							type = "range",
							min = 8,
							max = 30,
							step = 1,
							order = 4,
							get = function()
								return self.db.profile[i].fontSizeTarget
							end,
							set = function(_, val)
								self.db.profile[i].fontSizeTarget = val
								local font
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											if not font then
												font = self.groups[j].CooldownFrames[k].targetFontString:GetFont()
											end
											self.groups[j].CooldownFrames[k].targetFontString:SetFont(font, val)
										end
									end
								end
							end
						},
						fontSizeTimer = {
							name = L["Timer font size"],
							type = "range",
							min = 8,
							max = 30,
							step = 1,
							order = 5,
							get = function()
								return self.db.profile[i].fontSizeTimer
							end,
							set = function(_, val)
								self.db.profile[i].fontSizeTimer = val
								local font
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											if not font then
												font = self.groups[j].CooldownFrames[k].timerFontString:GetFont()
											end
											self.groups[j].CooldownFrames[k].timerFontString:SetFont(font, val)
										end
									end
								end
							end
						},
						iconSize = {
							name = L["Icon size"],
							type = "range",
							min = 10,
							max = 60,
							step = 1,
							order = 2,
							get = function()
								return self.db.profile[i].iconSize
							end,
							set = function(_, val)
								self.db.profile[i].iconSize = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self:setFrameHeight(self.groups[j].CooldownFrames[k], val)
										end
									end
									self:repositionFrames(j)
								end
							end
						},
						padding = {
							name = L["Padding"],
							type = "range",
							min = 0,
							max = 50,
							step = 1,
							order = 6,
							get = function()
								return self.db.profile[i].padding
							end,
							set = function(_, val)
								self.db.profile[i].padding = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										self:repositionFrames(j)
									end
								end
							end
						},
						targetJustify = {
							name = L["Target alignment"],
							type = "select",
							values = {
								l = L["Left"],
								r = L["Right"]
							},
							order = 11,
							get = function()
								return self.db.profile[i].targetJustify
							end,
							set = function(_, val)
								self.db.profile[i].targetJustify = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self.groups[j].CooldownFrames[k].targetFontString:SetJustifyH(val == "l" and "LEFT" or "RIGHT")
										end
									end
								end
							end
						},
						timerPosition = {
							name = L["Timer position"],
							type = "select",
							values = {
								l = L["Left"],
								r = L["Right"]
							},
							order = 12,
							get = function()
								return self.db.profile[i].timerPosition
							end,
							set = function(_, val)
								self.db.profile[i].timerPosition = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self:setTimerPosition(self.groups[j].CooldownFrames[k])
										end
									end
								end
							end
						}
					}
				},
				colors = {
					name = L["Colors"],
					type = "group",
					disabled = self.db.profile[i].inherit and i ~= 1,
					args = {
						invertColors = {
							name = L["Invert colors"],
							type = "toggle",
							desc = L["Makes cooldown bar transparent when spell is ready"],
							order = 5,
							get = function()
								return self.db.profile[i].invertColors
							end,
							set = function(_, val)
								self.db.profile[i].invertColors = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self:updateCooldownBarProgress(self.groups[j].CooldownFrames[k])
										end
									end
								end
							end
						},
						separator1 = {
							name = "",
							type = "description",
							order = 10
						},
						opacity = {
							name = L["Cooldown bar transparency"],
							type = "range",
							min = 0,
							max = 1,
							step = 0.01,
							isPercent = true,
							order = 15,
							get = function()
								return tonumber(("%.2f"):format(1 - self.db.profile[i].opacity))
							end,
							set = function(_, val)
								self.db.profile[i].opacity = tonumber(("%.2f"):format(1 - val))
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											local r, g, b = self.groups[j].CooldownFrames[k].bar.active:GetVertexColor()
											self.groups[j].CooldownFrames[k].bar.active:SetVertexColor(r, g, b, self.db.profile[i].opacity)
										end
									end
								end
							end
						},
						separator2 = {
							name = "",
							type = "description",
							order = 20
						},
						background = {
							name = L["Cooldown bar background"],
							type = "color",
							hasAlpha = true,
							order = 25,
							get = function()
								return unpack(self.db.profile[i].background)
							end,
							set = function(_, r, g, b, a)
								self.db.profile[i].background = { r, g, b, a }
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self.groups[j].CooldownFrames[k].bar.inactive:SetVertexColor(r, g, b, a)
										end
									end
								end
							end
						}
					}
				},
				textures = {
					name = L["Textures and fonts"],
					type = "group",
					disabled = self.db.profile[i].inherit and i ~= 1,
					args = {
						barTexture = {
							name = L["Bar texture"],
							type = "select",
							values = self.LibSharedMedia:List("statusbar"),
							order = 7,
							get = function()
								for key, name in ipairs(self.LibSharedMedia:List("statusbar")) do
									if name == self.db.profile[i].statusbar then
										return key
									end
								end
							end,
							set = function(_, val)
								self.db.profile[i].statusbar = self.LibSharedMedia:List("statusbar")[val]
								local texture = self.LibSharedMedia:Fetch("statusbar", self.db.profile[i].statusbar)
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self:setBarTexture(self.groups[j].CooldownFrames[k], texture)
										end
									end
								end
							end
						},
						fontPlayer = {
							name = L["Font"],
							type = "select",
							values = self.LibSharedMedia:List("font"),
							order = 8,
							get = function()
								for key, name in ipairs(self.LibSharedMedia:List("font")) do
									if name == self.db.profile[i].fontPlayer then
										return key
									end
								end
							end,
							set = function(_, val)
								self.db.profile[i].fontPlayer = self.LibSharedMedia:List("font")[val]
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self.groups[j].CooldownFrames[k].playerNameFontString:SetFont(self.LibSharedMedia:Fetch("font", self.db.profile[i].fontPlayer), self.db.profile[i].fontSize)
										end
									end
								end
							end
						},
						fontTarget = {
							name = L["Target font"],
							type = "select",
							values = self.LibSharedMedia:List("font"),
							order = 9,
							get = function()
								for key, name in ipairs(self.LibSharedMedia:List("font")) do
									if name == self.db.profile[i].fontTarget then
										return key
									end
								end
							end,
							set = function(_, val)
								self.db.profile[i].fontTarget = self.LibSharedMedia:List("font")[val]
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self.groups[j].CooldownFrames[k].targetFontString:SetFont(self.LibSharedMedia:Fetch("font", self.db.profile[i].fontTarget), self.db.profile[i].fontSizeTarget)
										end
									end
								end
							end
						},
						fontTimer = {
							name = L["Timer font"],
							type = "select",
							values = self.LibSharedMedia:List("font"),
							order = 10,
							get = function()
								for key, name in ipairs(self.LibSharedMedia:List("font")) do
									if name == self.db.profile[i].fontTimer then
										return key
									end
								end
							end,
							set = function(_, val)
								self.db.profile[i].fontTimer = self.LibSharedMedia:List("font")[val]
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self.groups[j].CooldownFrames[k].timerFontString:SetFont(self.LibSharedMedia:Fetch("font", self.db.profile[i].fontTimer), self.db.profile[i].fontSizeTimer)
										end
									end
								end
							end
						}
					}
				},
				range = {
					name = L["Range"],
					type = "group",
					disabled = self.db.profile[i].inherit and i ~= 1,
					args = {
						dimout = {
							name = L["Dim out"],
							desc = L["Dim out cooldown bars of spells that are out of range"],
							type = "toggle",
							get = function()
								return self.db.profile[i].rangeDimout
							end,
							set = function(_, val)
								self.db.profile[i].rangeDimout = val
								for j = 1, #self.groups do
									if j == i or self.db.profile[j].inherit == i then
										for k = 1, #self.groups[j].CooldownFrames do
											self:setBarColor(self.groups[j].CooldownFrames[k])
										end
									end
								end
							end
						},
						ungroup = {
							name = L["Ungroup"],
							desc = L["Ignore priority and move out of range spells to the bottom of the list"],
							type = "toggle",
							get = function()
								return self.db.profile[i].rangeUngroup
							end,
							set = function(_, val)
								self.db.profile[i].rangeUngroup = val
								self:sortFrames(i)
							end
						}
					}
				},
				titlebar = {
					name = L["Title Bar"],
					type = "group",
					args = {
						showTitleBar = {
							name = L["Show title bar"],
							type = "toggle",
							order = 1,
							get = function()
								return self.db.profile[i].showTitleBar
							end,
							set = function(_, val)
								self.db.profile[i].showTitleBar = val
								-- Only update the specific group, not inherited ones
								if self.groups[i] and self.groups[i].titleBar then
									if val then
										self.groups[i].titleBar:Show()
										-- Re-enable dragging when showing title bar
										self.groups[i].titleBar:EnableMouse(true)
										self.groups[i].titleBar:RegisterForDrag("LeftButton")
									else
										self.groups[i].titleBar:Hide()
										-- Disable dragging when hiding title bar
										self.groups[i].titleBar:EnableMouse(false)
										self.groups[i].titleBar:RegisterForDrag()
									end
								end
								self:repositionFrames(i)
							end
						},
						titleText = {
							name = L["Title text"],
							type = "input",
							order = 2,
							disabled = not self.db.profile[i].showTitleBar,
							get = function()
								return self.db.profile[i].titleText
							end,
							set = function(_, val)
								self.db.profile[i].titleText = val
								-- Only update the specific group, not inherited ones
								if self.groups[i] and self.groups[i].titleBar and self.groups[i].titleBar.text then
									local text = val ~= "" and val or ("Group " .. i)
									self.groups[i].titleBar.text:SetText(text)
								end
							end
						},
						titleBarHeight = {
							name = L["Title bar height"],
							type = "range",
							min = 12,
							max = 30,
							step = 1,
							order = 3,
							disabled = not self.db.profile[i].showTitleBar,
							get = function()
								return self.db.profile[i].titleBarHeight
							end,
							set = function(_, val)
								self.db.profile[i].titleBarHeight = val
								-- Only update the specific group, not inherited ones
								if self.groups[i] and self.groups[i].titleBar then
									self.groups[i].titleBar:SetHeight(val)
								end
								self:repositionFrames(i)
							end
						},
						titleFontSize = {
							name = L["Title font size"],
							type = "range",
							min = 6,
							max = 20,
							step = 1,
							order = 4,
							disabled = not self.db.profile[i].showTitleBar,
							get = function()
								return self.db.profile[i].titleFontSize
							end,
							set = function(_, val)
								self.db.profile[i].titleFontSize = val
								-- Only update the specific group, not inherited ones
								if self.groups[i] and self.groups[i].titleBar and self.groups[i].titleBar.text then
									local font = self.groups[i].titleBar.text:GetFont()
									self.groups[i].titleBar.text:SetFont(font, val)
								end
							end
						},
						titleBackgroundColor = {
							name = L["Title background color"],
							type = "color",
							hasAlpha = true,
							order = 5,
							disabled = not self.db.profile[i].showTitleBar,
							get = function()
								return unpack(self.db.profile[i].titleBackgroundColor)
							end,
							set = function(_, r, g, b, a)
								self.db.profile[i].titleBackgroundColor = { r, g, b, a }
								-- Only update the specific group, not inherited ones
								if self.groups[i] and self.groups[i].titleBar and self.groups[i].titleBar.bg then
									self.groups[i].titleBar.bg:SetVertexColor(r, g, b, a)
									-- Update the hover handlers to use new color
									self.groups[i].titleBar:SetScript("OnEnter", function(s)
										s.bg:SetVertexColor(r * 1.2, g * 1.2, b * 1.2, a)
									end)
									self.groups[i].titleBar:SetScript("OnLeave", function(s)
										s.bg:SetVertexColor(r, g, b, a)
									end)
								end
							end
						}
					}
				}
			}
		}

		if i ~= 1 then
			myOptionsTable.args.frames.args["frame" .. i].args.inheritSettings = {
				name = L["Inherit settings"],
				type = "select",
				desc = L["Copy settings from other frame"],
				values = {},
				set = function(_, val)
					if val == 0 then
						val = false
					end
					self.db.profile[i].inherit = val
					for j = 1, #self.groups[i].CooldownFrames do
						self:applyGroupSettings(self.groups[i].CooldownFrames[j])
					end
					self:repositionFrames(i)
					myOptionsTable.args.frames.args["frame" .. i].args.colors.disabled = val
					myOptionsTable.args.frames.args["frame" .. i].args.range.disabled = val
					myOptionsTable.args.frames.args["frame" .. i].args.size.disabled = val
					myOptionsTable.args.frames.args["frame" .. i].args.textures.disabled = val
					LibStub("AceConfigRegistry-3.0"):NotifyChange("RaidEye")
				end,
				get = function()
					return self.db.profile[i].inherit or 0
				end,
				order = 1
			}
			myOptionsTable.args.frames.args["frame" .. i].args.inheritSettings.values[0] = "disabled"
			for j = 1, #self.groups do
				if j ~= i then
					myOptionsTable.args.frames.args["frame" .. i].args.inheritSettings.values[j] = "Frame" .. j
				end
			end
		end
		myOptionsTable.args.frames.args["frame" .. i].args.resetpos = {
			name = L["Reset frame position"],
			type = "execute",
			func = function()
				self.groups[i].anchor:ClearAllPoints()
				self.groups[i].anchor:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
				self.db.profile[i].pos = {
					point = "CENTER",
					relativeTo = "UIParent",
					relativePoint = "CENTER",
					xOfs = 0,
					yOfs = 0
				}
			end,
			confirm = true,
			order = 2
		}
	end

	-- Создаём группы классов (вкладки слева) в правильном порядке
	do
		local spellsGroup = myOptionsTable.args.spells

		-- Собираем список классов и сортируем их по порядку
		local orderedClasses = {}
		for classKey, orderIndex in pairs(CLASS_ORDER) do
			table.insert(orderedClasses, {key = classKey, order = orderIndex})
		end

		-- Сортируем по полю order
		table.sort(orderedClasses, function(a, b)
			return a.order < b.order
		end)

		-- Создаём вкладки классов в правильном порядке
		for i = 1, #orderedClasses do
			local classKey = orderedClasses[i].key
			local icon = CLASS_ICONS[classKey]
			local className
			-- Для обычных классов берём локализованное имя от клиента
			if classKey ~= "RACIAL" and classKey ~= "OTHER" then
				className = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classKey] or classKey
			elseif classKey == "RACIAL" then
				className = "Racial"
			else
				className = "Other"
			end

			local text
			if icon then
				text = ("|T%s:16|t %s"):format(icon, className)
			else
				text = className
			end

			-- Используем числовой префикс для правильной сортировки в dropdown
			local sortedKey = string.format("class_%02d_%s", orderedClasses[i].order, classKey)

			spellsGroup.args[sortedKey] = {
				name = text,
				type = "group",
				order = orderedClasses[i].order,
				args = {},
			}
		end
	end

	-- Создаём опции для каждого заклинания, разложенные по классам
	for spellID, spellConfig in pairs(self.spells) do
		if not spellConfig.parent then
			local name, _, icon = GetSpellInfo(spellID)
			-- Определяем ключ класса / группы
			local classKey
			if spellConfig.class and CLASS_ORDER[spellConfig.class] then
				classKey = spellConfig.class
			elseif spellConfig.race then
				classKey = "RACIAL"
			else
				classKey = "OTHER"
			end

			-- Создаём ключ с числовым префиксом для правильной сортировки
			local sortedKey = string.format("class_%02d_%s", CLASS_ORDER[classKey] or 99, classKey)
			local classGroup = myOptionsTable.args.spells.args[sortedKey]

			if classGroup then
				local saved = self.db.profile.spells[spellID]
				local priority = (saved and saved.priority) or (spellConfig.priority or 100)
				local spellKey = tostring(spellID)

				-- Создаём имя с иконкой для отображения
				classGroup.args[spellKey] = {
            name = function()
                local isEnabled = self.db.profile.spells[spellID].enable
                if isEnabled then
                     return icon and ("|T%s:16|t |cffffd100%s|r"):format(icon, name) or ("|cffffd100%s|r"):format(name)
                else
                     return icon and ("|T%s:16|t |cff808080%s|r"):format(icon, name) or ("|cff808080%s|r"):format(name)
                end
            end,
            type = "group",
					-- inline = true, -- ЗАКЕММЕНТИРОВАНО для экономии места. Теперь заклинания сворачиваются.
					order = priority,
					args = {
						enable = {
							name = L["Enabled"],
							type = "toggle",
							width = "normal", -- Изменено на normal для читаемости
							order = 1,
							set = function(_, val)
								self.db.profile.spells[spellID].enable = val
								if val then
									for k, _ in pairs(myOptionsTable.args.spells.args[sortedKey].args[spellKey].args) do
										if k ~= "enable" then
											myOptionsTable.args.spells.args[sortedKey].args[spellKey].args[k].disabled = false
										end
									end
								else
									for k, _ in pairs(myOptionsTable.args.spells.args[sortedKey].args[spellKey].args) do
										if k ~= "enable" then
											myOptionsTable.args.spells.args[sortedKey].args[spellKey].args[k].disabled = true
										end
									end
								end
								LibStub("AceConfigRegistry-3.0"):NotifyChange("RaidEye")
								self:updateRaidCooldowns()
							end,
							get = function(_)
								return self.db.profile.spells[spellID].enable
							end,
						},
						alwaysShow = {
							name = L["Always visible"],
							type = "toggle",
							desc = L["Do not hide cooldown bar when spell is ready"],
							width = "normal", -- Изменено на normal
							order = 2,
							disabled = not self.db.profile.spells[spellID].enable,
							set = function(_, val)
								self.db.profile.spells[spellID].alwaysShow = val
								if val then
									self:updateRaidCooldowns()
								else
									local playerNames = {}
									local groupIndex = self.db.profile.spells[spellID].group
									for j = 1, #self.groups[groupIndex].CooldownFrames do
										local frame = self.groups[groupIndex].CooldownFrames[j]
										if frame.spellID == spellID and frame.CDLeft <= 0 then
											table.insert(playerNames, frame.playerName)
										end
									end
									for _, playerName in ipairs(playerNames) do
										self:removeCooldownFrames(playerName, spellID)
									end
									self:repositionFrames()
								end
							end,
							get = function(_)
								return self.db.profile.spells[spellID].alwaysShow
							end,
						},
						frame = {
							name = L["Frame"],
							type = "select",
							width = "normal",
							order = 4,
							disabled = not self.db.profile.spells[spellID].enable,
							values = function()
								local groups = {}
								for i = 1, #self.groups do
									groups[i] = "Frame " .. i
								end
								return groups
							end,
							get = function()
								return self.db.profile.spells[spellID].group
							end,
							set = function(_, val)
								self:setSpellGroupIndex(spellID, val)
							end,
						},
						priority = {
							name = L["Priority"],
							type = "range",
							min = 1,
							max = 200,
							step = 1,
							width = "normal", -- Изменено на normal, чтобы ползунок влезал
							order = 5,
							disabled = not self.db.profile.spells[spellID].enable,
							get = function()
								return self.db.profile.spells[spellID].priority
							end,
							set = function(_, val)
								self.db.profile.spells[spellID].priority = val
								self:sortFrames(self.db.profile.spells[spellID].group)
							end,
						},
					},
				}

				if self.spells[spellID].tanksonly then
					classGroup.args[spellKey].args.tanksonly = {
						name = L["Tanks only"],
						type = "toggle",
						width = "normal", -- Изменено на normal
						desc = L["Show cooldown for tanks only"],
						order = 3,
						set = function(_, val)
							self.db.profile.spells[spellID].tanksonly = val
							self:updateRaidCooldowns()
						end,
						get = function(_)
							return self.db.profile.spells[spellID].tanksonly
						end,
					}
				end
			end
		end
	end

	for prefix, addonName in pairs(self.comms) do
		myOptionsTable.args.comms.args[prefix] = {
			name = addonName,
			type = "toggle",
			set = function(_, val)
				if val and not self.db.global.comms[prefix] then
					self:RegisterComm(prefix)
				end
				self.db.global.comms[prefix] = val
			end,
			get = function(_)
				return self.db.global.comms[prefix]
			end
		}
	end

    AceConfig:RegisterOptionsTable("RaidEye", myOptionsTable, { "RaidEye" })

    if not self.optionsLoaded then
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RaidEye", "RaidEye " .. GetAddOnMetadata("RaidEye", "Version"))
        self.optionsLoaded = true
    end
end
