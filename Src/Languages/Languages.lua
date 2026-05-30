---@class LanguagesModule
---@overload fun(key: string): string
---@field currentLocale BomLocaleDict
---@field english BomLocaleDict

local languagesModule = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local englishModule = LibStub("Buffomat-LanguageEnglish") --[[@as BomLanguageEnglishModule]]
local germanModule = LibStub("Buffomat-LanguageGerman") --[[@as BomLanguageGermanModule]]
local frenchModule = LibStub("Buffomat-LanguageFrench") --[[@as BomLanguageFrenchModule]]
local russianModule = LibStub("Buffomat-LanguageRussian") --[[@as BomLanguageRussianModule]]
local chineseModule = LibStub("Buffomat-LanguageChinese") --[[@as BomLanguageChineseModule]]

---@alias BomLanguageId "enUS" | "deDE" | "frFR" | "ruRU" | "zhCN"
---@alias BomLanguageSetting "auto" | BomLanguageId
---@alias BomLocaleDict table<string, string>

---@class BomAllLocalesCollection
---@field [BomLanguageId] BomLocaleDict
---@field enUS BomLocaleDict
---@field deDE BomLocaleDict
---@field frFR BomLocaleDict
---@field ruRU BomLocaleDict
---@field zhCN BomLocaleDict

languagesModule.languageOptions = {
  auto = "Auto (WoW client language)",
  enUS = "English",
  deDE = "German",
  frFR = "French",
  ruRU = "Russian",
  zhCN = "Chinese",
}

languagesModule.languageOptionsOrder = { "auto", "enUS", "deDE", "frFR", "ruRU", "zhCN" }

---@param language BomLanguageSetting|string|nil
---@return BomLanguageSetting
function languagesModule:NormalizeLanguageSetting(language)
  if language and self.languageOptions[language] then
    return language --[[@as BomLanguageSetting]]
  end

  return "auto"
end

---@param locale BomLanguageId|string|nil
---@return BomLocaleDict|nil
function languagesModule:LoadLanguage(locale)
  if locale == "deDE" then
    return germanModule:Translations()
  end
  if locale == "frFR" then
    return frenchModule:Translations()
  end
  if locale == "ruRU" then
    return russianModule:Translations()
  end
  if locale == "zhCN" then
    return chineseModule:Translations()
  end
end

function languagesModule:SetupTranslations()
  -- Allow calling the languagesModule as a function to get a translation
  setmetatable(languagesModule, {
    __call = ---@param k string
        function(_, k)
          if languagesModule.currentLocale and languagesModule.currentLocale[k] then
            return languagesModule.currentLocale[k] or ("¶" .. k)
          else
            return "¶" .. k
          end
        end
  })

  local language = "auto"
  if BuffomatShared then
    language = self:NormalizeLanguageSetting(BuffomatShared.Language)
    BuffomatShared.Language = language
  end

  local locale = language == "auto" and GetLocale() or language
  self.currentLocale = self:LoadLanguage(locale) or {}

  for englishKey, englishText in pairs(englishModule:Translations()) do
    if not self.currentLocale[englishKey] then
      self.currentLocale[englishKey] = englishText
    end
  end

  self.currentLocale["AboutCredits"] = "nanjuekaien1 & wellcat for the Chinese translation|n" ..
      "OlivBEL for the french translation|n" ..
      "Arrogant_Dreamer & kvakvs for the russian translation|n"
end

function languagesModule:LocalizationInit()
  if BuffomatShared and BuffomatShared.CustomLocales then
    for key, value in pairs(BuffomatShared.CustomLocales) do
      if value ~= nil and value ~= "" then
        self.currentLocale[key .. "_org"] = self.currentLocale[key]
        self.currentLocale[key] = value
      end
    end
  end
end
