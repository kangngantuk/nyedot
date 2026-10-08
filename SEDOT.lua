-- =======================================================
-- ⚙️ PENGATURAN MODE DOWNLOAD
-- =======================================================
local NAMA_FILE_GABUNGAN = "Hasil_Animasi_Game_V1"

-- 🎭 MODE ANIMASI: Scan seluruh game untuk mengambil semua animasi
local SCAN_SELURUH_GAME = true -- true = scan semua (workspace, Players, ReplicatedStorage, dll)

-- Jika SCAN_SELURUH_GAME = false, kamu bisa tentukan target manual:
local TARGET_ALAMAT_MANUAL = {
    workspace
}

-- =======================================================
-- 🏟️ PENGATURAN MODE ARENA ISOLASI
-- =======================================================
-- Jika MODE_ARENA_ISOLASI = true, script akan mengabaikan SCAN_SELURUH_GAME
-- dan hanya meng-capture geometri Part/MeshPart/Model di sekitar karakter kamu.
-- Berguna untuk mengekstrak arena spesifik (contoh: Arena Escape Tsunami)
-- tanpa ikut-serta mengunduh seluruh world / lobby game.

local MODE_ARENA_ISOLASI = false

-- Radius box scan (dalam satuan studs) yang berpusat pada posisi berdiri karakter.
-- 500 = kotak 500x500x500 studs. Sesuaikan ukuran dengan arena target.
local ARENA_SCAN_RADIUS = 500

-- Nama file output khusus mode arena (terpisah dari animasi)
local NAMA_FILE_ARENA = "Hasil_Arena_Isolasi_V1"

-- =======================================================
-- ⛔ JANGAN UBAH SCRIPT DI BAWAH GARIS INI ⛔
-- =======================================================

local KELAS_ANIMASI = {
    ["Animation"]           = true,
    ["AnimationController"] = true,
    ["Animator"]            = true,
    ["KeyframeSequence"]    = true,
    ["Keyframe"]            = true,
    ["Pose"]                = true,
    ["AnimationTrack"]      = true,
    ["NumberSequence"]      = false,
    ["Humanoid"]            = true,
}

local LOKASI_SCAN = {
    workspace,
    game:GetService("Players"),
    game:GetService("ReplicatedStorage"),
    game:GetService("ReplicatedFirst"),
    game:GetService("ServerStorage"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("StarterPlayer"),
    game:GetService("SoundService"),
    game:GetService("Chat"),
}

local TARGET_ALAMAT = SCAN_SELURUH_GAME and LOKASI_SCAN or TARGET_ALAMAT_MANUAL

local CoreGui    = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Players    = game:GetService("Players")

-- Cleanup sesi lama
if CoreGui:FindFirstChild("AnimRadarUI")    then CoreGui.AnimRadarUI:Destroy()    end
if CoreGui:FindFirstChild("GUDANG_ANIMASI") then CoreGui.GUDANG_ANIMASI:Destroy() end
if CoreGui:FindFirstChild("GUDANG_ARENA")   then CoreGui.GUDANG_ARENA:Destroy()   end

-- =======================================================
-- 📦 GUDANG ANIMASI
-- =======================================================
local GudangUtama = Instance.new("Folder")
GudangUtama.Name   = "GUDANG_ANIMASI"
GudangUtama.Parent = CoreGui

local FolderAnimasi    = Instance.new("Folder", GudangUtama); FolderAnimasi.Name    = "Animations"
local FolderController = Instance.new("Folder", GudangUtama); FolderController.Name = "AnimationControllers"
local FolderAnimator   = Instance.new("Folder", GudangUtama); FolderAnimator.Name   = "Animators"
local FolderKeyframe   = Instance.new("Folder", GudangUtama); FolderKeyframe.Name   = "KeyframeSequences"
local FolderHumanoid   = Instance.new("Folder", GudangUtama); FolderHumanoid.Name   = "Humanoids"
local FolderLainnya    = Instance.new("Folder", GudangUtama); FolderLainnya.Name    = "Lainnya"

-- 📦 GUDANG ARENA ISOLASI
local GudangArena = Instance.new("Folder")
GudangArena.Name   = "GUDANG_ARENA"
GudangArena.Parent = CoreGui

-- =======================================================
-- 🔢 STATE TRACKING
-- =======================================================
local SemuaKoneksi  = {}
-- [FIX #1] Key = Instance reference langsung, bukan tostring(obj)
-- Mencegah animasi ber-nama sama (Walk, Run) dari game berbeda terlewat.
local SudahDiSimpan = {}

local TotalAnimasi    = 0
local TotalAnimation  = 0
local TotalController = 0
local TotalAnimator   = 0
local TotalKeyframe   = 0
local TotalHumanoid   = 0

local TotalPart      = 0
local TotalMesh      = 0
local TotalModel     = 0
local TotalArena     = 0
local IsScannedArena = false

-- =======================================================
-- 🎨 UI TRACKER LIVE
-- =======================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "AnimRadarUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent       = CoreGui

local frameHeight = MODE_ARENA_ISOLASI and 400 or 330
local MainFrame = Instance.new("Frame")
MainFrame.Size             = UDim2.new(0, 440, 0, frameHeight)
MainFrame.Position         = UDim2.new(0.5, -220, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local accentColor = MODE_ARENA_ISOLASI and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(150, 80, 255)
local headerColor = MODE_ARENA_ISOLASI and Color3.fromRGB(160, 80, 0)  or Color3.fromRGB(80, 30, 180)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color     = accentColor
Stroke.Thickness = 2

local Header = Instance.new("Frame", MainFrame)
Header.Size             = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = headerColor
Header.BorderSizePixel  = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size               = UDim2.new(1, -40, 1, 0)
Title.Position           = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text               = MODE_ARENA_ISOLASI and "🏟️ ARENA ISOLATOR V2" or "🎭 ANIMATION HUNTER V2"
Title.TextColor3         = Color3.fromRGB(255, 255, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 16
Title.TextXAlignment     = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size             = UDim2.new(0, 36, 0, 36)
CloseBtn.Position         = UDim2.new(1, -38, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
CloseBtn.Text             = "X"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 16
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local function BuatLabel(parent, posY, warna, teks)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size               = UDim2.new(1, -20, 0, 24)
    lbl.Position           = UDim2.new(0, 10, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text               = teks
    lbl.TextColor3         = warna
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    return lbl
end

local LblTotal      = BuatLabel(MainFrame, 50,  Color3.fromRGB(255, 220, 0),   "🎭 Total Animasi: 0")
local LblAnimation  = BuatLabel(MainFrame, 76,  Color3.fromRGB(100, 200, 255), "  >> Animation (ID): 0")
local LblController = BuatLabel(MainFrame, 100, Color3.fromRGB(180, 120, 255), "  >> AnimationController: 0")
local LblAnimator   = BuatLabel(MainFrame, 124, Color3.fromRGB(100, 255, 180), "  >> Animator: 0")
local LblKeyframe   = BuatLabel(MainFrame, 148, Color3.fromRGB(255, 160, 80),  "  >> KeyframeSequence/Pose: 0")
local LblHumanoid   = BuatLabel(MainFrame, 172, Color3.fromRGB(255, 100, 150), "  >> Humanoid: 0")

local StatusLbl = BuatLabel(MainFrame, 200, Color3.fromRGB(180, 180, 180), "🔍 Status: Scanning...")
StatusLbl.TextSize = 12

local LblArenaTotal, LblArenaPart, LblArenaMesh, LblArenaModel, StatusArena
if MODE_ARENA_ISOLASI then
    local Sep = Instance.new("Frame", MainFrame)
    Sep.Size             = UDim2.new(0.9, 0, 0, 1)
    Sep.Position         = UDim2.new(0.05, 0, 0, 228)
    Sep.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    Sep.BorderSizePixel  = 0

    LblArenaTotal = BuatLabel(MainFrame, 236, Color3.fromRGB(255, 200, 0),   "🏟️ Total Arena Captured: 0")
    LblArenaPart  = BuatLabel(MainFrame, 260, Color3.fromRGB(150, 220, 255), "  >> Part: 0")
    LblArenaMesh  = BuatLabel(MainFrame, 284, Color3.fromRGB(255, 180, 100), "  >> MeshPart: 0")
    LblArenaModel = BuatLabel(MainFrame, 308, Color3.fromRGB(180, 255, 150), "  >> Model: 0")
    StatusArena   = BuatLabel(MainFrame, 332, Color3.fromRGB(180, 180, 180), "🏟️ Arena: Belum di-scan")
    StatusArena.TextSize = 12
end

-- =======================================================
-- 🔔 NOTIFIKASI
-- =======================================================
local function SendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
    end)
end

-- =======================================================
-- 🎭 CEK ANIMASI
-- =======================================================
local function AdaAnimasiDiDalamnya(obj)
    if obj:IsA("Animation")           then return true end
    if obj:IsA("AnimationController") then return true end
    if obj:IsA("Animator")            then return true end
    if obj:IsA("KeyframeSequence")    then return true end
    if obj:IsA("Keyframe")            then return true end
    if obj:IsA("Pose")                then return true end
    if obj:IsA("Humanoid")            then return true end
    return false
end

-- =======================================================
-- ⚡ PENYIMPAN ANIMASI
-- =======================================================
local function SimpanAnimasi(obj)
    if not GudangUtama or not GudangUtama.Parent then return end
    -- [FIX #1] Reference Instance sebagai key (bukan string nama)
    if SudahDiSimpan[obj] then return end
    SudahDiSimpan[obj] = true

    local folderTarget = FolderLainnya

    if obj:IsA("Animation") then
        folderTarget    = FolderAnimasi
        TotalAnimation  = TotalAnimation + 1
    elseif obj:IsA("AnimationController") then
        folderTarget    = FolderController
        TotalController = TotalController + 1
    elseif obj:IsA("Animator") then
        folderTarget  = FolderAnimator
        TotalAnimator = TotalAnimator + 1
    elseif obj:IsA("KeyframeSequence") or obj:IsA("Keyframe") or obj:IsA("Pose") then
        folderTarget  = FolderKeyframe
        TotalKeyframe = TotalKeyframe + 1
    elseif obj:IsA("Humanoid") then
        folderTarget  = FolderHumanoid
        TotalHumanoid = TotalHumanoid + 1
    end

    obj.Archivable = true
    local success, clone = pcall(function() return obj:Clone() end)
    if success and clone then
        if obj:IsA("Animation") then
            local animId = "?"
            pcall(function() animId = tostring(obj.AnimationId) end)
            clone.Name = obj.Name .. " [" .. animId .. "]"
        end
        clone.Parent = folderTarget
        TotalAnimasi = TotalAnimasi + 1

        Stroke.Color = Color3.fromRGB(255, 80, 255)
        task.delay(0.1, function()
            if Stroke and Stroke.Parent then
                Stroke.Color = Color3.fromRGB(150, 80, 255)
            end
        end)
    end
end

-- =======================================================
-- 🔍 SCAN REKURSIF ANIMASI
-- =======================================================
local function ScanRekursif(obj)
    if not obj or not obj.Parent then return end
    if obj:IsA("LuaSourceContainer") then return end
    if AdaAnimasiDiDalamnya(obj) then SimpanAnimasi(obj) end
    for _, child in ipairs(obj:GetChildren()) do
        ScanRekursif(child)
    end
end

-- =======================================================
-- 🏟️ ARENA ISOLASI - SPATIAL BOUNDING BOX SCANNER
-- =======================================================
local function JalankanArenaIsolasi()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        if StatusArena then StatusArena.Text = "❌ LocalPlayer tidak ditemukan!" end
        return
    end
    local character = localPlayer.Character
    if not character then
        if StatusArena then StatusArena.Text = "❌ Character belum spawn!" end
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        if StatusArena then StatusArena.Text = "❌ HumanoidRootPart tidak ditemukan!" end
        return
    end

    local centerCFrame = CFrame.new(rootPart.CFrame.Position)
    local boxSize      = Vector3.new(ARENA_SCAN_RADIUS, ARENA_SCAN_RADIUS, ARENA_SCAN_RADIUS) * 2

    if StatusArena then
        StatusArena.Text = "⏳ Scanning Box " .. ARENA_SCAN_RADIUS .. "^3 studs..."
    end

    GudangArena:ClearAllChildren()
    TotalPart  = 0
    TotalMesh  = 0
    TotalModel = 0
    TotalArena = 0

    local trackModel   = {}
    local partsInBox   = workspace:GetPartBoundsInBox(centerCFrame, boxSize)

    for _, part in ipairs(partsInBox) do
        if part:IsDescendantOf(character) then continue end
        if part:IsA("Terrain") then continue end

        local rootModel = part:FindFirstAncestorWhichIsA("Model")
        if rootModel and rootModel ~= workspace then
            if not trackModel[rootModel] then
                trackModel[rootModel] = true
                rootModel.Archivable  = true
                local ok, clone = pcall(function() return rootModel:Clone() end)
                if ok and clone then
                    clone.Parent = GudangArena
                    TotalModel   = TotalModel + 1
                    TotalArena   = TotalArena + 1
                end
            end
        else
            part.Archivable = true
            local ok, clone = pcall(function() return part:Clone() end)
            if ok and clone then
                clone.Parent = GudangArena
                if part:IsA("MeshPart") then
                    TotalMesh = TotalMesh + 1
                else
                    TotalPart = TotalPart + 1
                end
                TotalArena = TotalArena + 1
            end
        end
    end

    IsScannedArena = true
    if StatusArena then
        StatusArena.Text = "✅ " .. TotalArena .. " objek dicapture dalam radius " .. ARENA_SCAN_RADIUS
    end
    SendNotification("🏟️ ARENA CAPTURED!", TotalArena .. " objek dalam " .. ARENA_SCAN_RADIUS .. " studs berhasil dikumpulkan.")
end

-- =======================================================
-- 🔧 LOAD saveinstance (Shared, dengan Fallback)
-- =======================================================
local _cachedSynSave = nil
local function GetSaveInstance()
    if _cachedSynSave then return true, _cachedSynSave end
    -- [FIX #3] Cek global built-in executor dulu (syn, xeno, wave, dll)
    if type(saveinstance) == "function" then
        _cachedSynSave = saveinstance
        return true, saveinstance
    end
    -- Fallback ke HTTP jika tidak ada built-in
    local Params = {
        RepoURL = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/",
        SSI     = "saveinstance",
    }
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
    end)
    if ok then
        _cachedSynSave = result
        return true, result
    end
    return false, nil
end

-- =======================================================
-- 🔘 TOMBOL SCAN ARENA (hanya muncul jika mode aktif)
-- =======================================================
if MODE_ARENA_ISOLASI then
    local ScanBtn = Instance.new("TextButton", MainFrame)
    ScanBtn.Size             = UDim2.new(0.92, 0, 0, 36)
    ScanBtn.Position         = UDim2.new(0.04, 0, 1, -106)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 0)
    ScanBtn.Text             = "📡 SCAN ARENA (berdiri di tengah arena dulu!)"
    ScanBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    ScanBtn.Font             = Enum.Font.GothamBold
    ScanBtn.TextSize         = 12
    ScanBtn.TextWrapped      = true
    Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 8)
    local ScanStroke = Instance.new("UIStroke", ScanBtn)
    ScanStroke.Color     = Color3.fromRGB(255, 200, 0)
    ScanStroke.Thickness = 1.5

    ScanBtn.MouseButton1Click:Connect(function()
        ScanBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
        ScanBtn.Text = "⏳ Scanning..."
        task.spawn(function()
            JalankanArenaIsolasi()
            ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
            ScanBtn.Text = "✅ Re-Scan Arena"
        end)
    end)
end

-- =======================================================
-- ⬇️ TOMBOL DOWNLOAD ANIMASI
-- =======================================================
local DownloadAnimBtn = Instance.new("TextButton", MainFrame)
DownloadAnimBtn.Size             = UDim2.new(0.92, 0, 0, 36)
DownloadAnimBtn.Position         = UDim2.new(0.04, 0, 1, -60)
DownloadAnimBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 180)
DownloadAnimBtn.Text             = "📥 EXPORT ANIMASI"
DownloadAnimBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
DownloadAnimBtn.Font             = Enum.Font.GothamBold
DownloadAnimBtn.TextSize         = 13
Instance.new("UICorner", DownloadAnimBtn).CornerRadius = UDim.new(0, 8)
local BtnStroke = Instance.new("UIStroke", DownloadAnimBtn)
BtnStroke.Color     = Color3.fromRGB(180, 120, 255)
BtnStroke.Thickness = 1.5

-- ⬇️ TOMBOL DOWNLOAD ARENA (hanya muncul jika mode aktif)
if MODE_ARENA_ISOLASI then
    local DownloadArenaBtn = Instance.new("TextButton", MainFrame)
    DownloadArenaBtn.Size             = UDim2.new(0.92, 0, 0, 36)
    DownloadArenaBtn.Position         = UDim2.new(0.04, 0, 1, -60)
    DownloadArenaBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 0)
    DownloadArenaBtn.Text             = "🏟️ EXPORT ARENA"
    DownloadArenaBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    DownloadArenaBtn.Font             = Enum.Font.GothamBold
    DownloadArenaBtn.TextSize         = 13
    Instance.new("UICorner", DownloadArenaBtn).CornerRadius = UDim.new(0, 8)
    local ArenaBtnStroke = Instance.new("UIStroke", DownloadArenaBtn)
    ArenaBtnStroke.Color     = Color3.fromRGB(255, 200, 0)
    ArenaBtnStroke.Thickness = 1.5

    -- Geser tombol animasi agar tidak overlap
    DownloadAnimBtn.Position = UDim2.new(0.04, 0, 1, -16)
    DownloadAnimBtn.Size     = UDim2.new(0.92, 0, 0, 28)
    DownloadAnimBtn.TextSize = 11

    local IsSavingArena = false
    DownloadArenaBtn.MouseButton1Click:Connect(function()
        if IsSavingArena then return end
        if not IsScannedArena or TotalArena == 0 then
            SendNotification("⚠️ ARENA KOSONG", "Klik SCAN ARENA dulu sebelum export!")
            return
        end
        IsSavingArena = true
        DownloadArenaBtn.Text             = "⏳ Export Arena..."
        DownloadArenaBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
        SendNotification("⏳ EXPORT ARENA", TotalArena .. " objek. Game mungkin freeze!")

        local ok, synsaveinstance = GetSaveInstance()
        if not ok then
            DownloadArenaBtn.Text             = "❌ Gagal load saveinstance!"
            DownloadArenaBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
            IsSavingArena = false
            return
        end

        warn("🏟️ Export Arena → " .. NAMA_FILE_ARENA)
        synsaveinstance({
            Object    = GudangArena,
            noscripts = true,
            mode      = "optimized",
            SafeMode  = false,
            FileName  = NAMA_FILE_ARENA
        })

        DownloadArenaBtn.Text             = "✅ Arena Tersimpan!"
        DownloadArenaBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
        IsSavingArena = false
        SendNotification("✅ ARENA EXPORTED!", TotalArena .. " objek disimpan ke " .. NAMA_FILE_ARENA)
    end)
end

-- =======================================================
-- 📺 UI UPDATER (live)
-- =======================================================
task.spawn(function()
    while true do
        if not ScreenGui.Parent then break end
        LblTotal.Text      = "🎭 Total Animasi: " .. TotalAnimasi
        LblAnimation.Text  = "  >> Animation (ID): " .. TotalAnimation
        LblController.Text = "  >> AnimationController: " .. TotalController
        LblAnimator.Text   = "  >> Animator: " .. TotalAnimator
        LblKeyframe.Text   = "  >> KeyframeSequence/Pose: " .. TotalKeyframe
        LblHumanoid.Text   = "  >> Humanoid: " .. TotalHumanoid

        if TotalAnimasi > 0 then
            DownloadAnimBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
            DownloadAnimBtn.Text = "📥 EXPORT " .. TotalAnimasi .. " ANIMASI"
        end

        if MODE_ARENA_ISOLASI and LblArenaTotal then
            LblArenaTotal.Text = "🏟️ Total Arena Captured: " .. TotalArena
            LblArenaPart.Text  = "  >> Part: " .. TotalPart
            LblArenaMesh.Text  = "  >> MeshPart: " .. TotalMesh
            LblArenaModel.Text = "  >> Model: " .. TotalModel
        end
        task.wait(0.5)
    end
end)

-- =======================================================
-- ❌ TOMBOL CLOSE
-- =======================================================
CloseBtn.MouseButton1Click:Connect(function()
    for _, k in ipairs(SemuaKoneksi) do
        if k then k:Disconnect() end
    end
    table.clear(SemuaKoneksi)
    if GudangUtama then GudangUtama:Destroy() end
    if GudangArena  then GudangArena:Destroy()  end
    table.clear(SudahDiSimpan)
    ScreenGui:Destroy()
    SendNotification("🛑 BERHENTI", "Animation Hunter V2 dimatikan.")
end)

-- =======================================================
-- 📥 EXPORT ANIMASI
-- =======================================================
local IsSavingAnim = false
DownloadAnimBtn.MouseButton1Click:Connect(function()
    if IsSavingAnim then return end
    if TotalAnimasi == 0 then
        SendNotification("⚠️ KOSONG", "Belum ada animasi yang ditemukan!")
        return
    end
    IsSavingAnim = true
    DownloadAnimBtn.Text             = "⏳ Export Animasi..."
    DownloadAnimBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
    SendNotification("⏳ EXPORT DIMULAI", "Game mungkin freeze sebentar!")

    local ok, synsaveinstance = GetSaveInstance()
    if not ok then
        DownloadAnimBtn.Text             = "❌ Gagal load saveinstance!"
        DownloadAnimBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        IsSavingAnim = false
        return
    end

    warn("🚀 Export Animasi → " .. NAMA_FILE_GABUNGAN)
    synsaveinstance({
        Object    = GudangUtama,
        noscripts = true,
        mode      = "optimized",
        SafeMode  = false,
        FileName  = NAMA_FILE_GABUNGAN
    })

    DownloadAnimBtn.Text             = "✅ SELESAI! Cek folder Workspace"
    DownloadAnimBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
    IsSavingAnim = false
    SendNotification("✅ EXPORT BERHASIL!", TotalAnimasi .. " animasi disimpan!")
end)

-- =======================================================
-- 🚀 MULAI SCAN ANIMASI (hanya jika bukan mode arena)
-- =======================================================
if not MODE_ARENA_ISOLASI then
    if #TARGET_ALAMAT == 0 or not TARGET_ALAMAT[1] then
        warn("❌ Target tidak ditemukan!")
    else
        StatusLbl.Text = "🔍 Status: Scanning " .. #TARGET_ALAMAT .. " lokasi..."
        for _, lokasi in ipairs(TARGET_ALAMAT) do
            pcall(function()
                if lokasi then
                    ScanRekursif(lokasi)
                    -- [FIX #2] Validasi kelas SEBELUM task.wait()
                    -- Mencegah ribuan coroutine kosong dari spawn di task-scheduler
                    local koneksi = lokasi.DescendantAdded:Connect(function(baruMuncul)
                        if AdaAnimasiDiDalamnya(baruMuncul) then
                            task.wait()
                            SimpanAnimasi(baruMuncul)
                        end
                    end)
                    table.insert(SemuaKoneksi, koneksi)
                end
            end)
        end
        StatusLbl.Text = "✅ Status: Live Monitoring Aktif"
    end
else
    StatusLbl.Text       = "🏟️ Mode Arena Isolasi Aktif"
    StatusLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
end

warn("🎭 Animation Hunter V2 aktif! Mode: " .. (MODE_ARENA_ISOLASI and "ARENA ISOLASI" or "FULL SCAN"))
