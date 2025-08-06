-- Script rapide pour envoyer Job ID via Webhook (sans GUI)
-- Créé par funnyoutubeurreal

wait(2) -- La ligne que tu as demandé d'ajouter au tout début

local HttpService = game:GetService("HttpService")

-- Configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1402536478432694302/-2kXN0vSJTT_dsAOtevRMeaBvNDIMKS3WZl8W3PSlCc45NYxWE_asQfF2oJGR7o7xGOY"

-- Fonction pour envoyer le Job ID via webhook
local function sendJobId()
    local jobId = game.JobId
    
    if not jobId or jobId == "" then
        warn("❌ Job ID introuvable")
        return false
    end
    
    -- Données à envoyer - SEULEMENT le Job ID
    local webhookData = {
        content = jobId
    }
    
    -- Conversion en JSON
    local jsonData = HttpService:JSONEncode(webhookData)
    
    -- Envoi du webhook
    local success, result = pcall(function()
        if syn and syn.request then
            return syn.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        elseif request then
            return request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        else
            return HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
        end
    end)
    
    if success then
        print("✅ Job ID envoyé: " .. jobId)
        return true
    else
        warn("❌ Échec envoi Job ID: " .. tostring(result))
        return false
    end
end

-- Exécution immédiate dès le lancement du script
print("🚀 Envoi du Job ID...")
sendJobId()
print("📤 Script terminé")
