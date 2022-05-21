local FireModes = require(script.Parent.FireModes)

return {
    ["M45A1"] = {
        Damage = 15,
        RPM = 0,
        Recoil = 0,
        MagSize = 8,
        FireMode = FireModes.Semi,

        Animations = {
            Idle = "rbxassetid://9679779154",
            Reload = "rbxassetid://9679789345",
        }
    },
    ["M45A1 SIG SRD"] = {
        Damage = 9,
        RPM = 0,
        Recoil = 0,
        MagSize = 8,
        FireMode = FireModes.Semi,

        Animations = {
            Idle = "rbxassetid://9679779154",
            Reload = "rbxassetid://9679789345",
        }
    },
    ["OTS-33 PERNACH"] = {
        Damage = 4,
        RPM = 0,
        Recoil = 0,
        MagSize = 13,
        FireMode = FireModes.Semi,

        Animations = {
            Idle = "rbxassetid://9678479911",
        }
    },
}