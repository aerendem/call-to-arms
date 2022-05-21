local FireModes = require(script.Parent.FireModes)

return {
    MG3 = {
        Damage = 8,
        RPM = 0,
        Recoil = 0,
        MagSize = 75,
        FireMode = FireModes.Auto,

        Animations = {
            Idle = "rbxassetid://9679984422",
            Reload = "rbxassetid://9679987384",
        }
    },
    ["PP-19-01 VITYAZ"] = {
        Damage = 5,
        RPM = 0,
        Recoil = 0,
        MagSize = 30,
        FireMode = FireModes.Auto,

        Animations = {
            Idle = "rbxassetid://9678467914",
            Reload = "rbxassetid://9679286898"
        }
    },
    ["M1A EBR"] = {
        Damage = 40,
        RPM = 0,
        Recoil = 0,
        MagSize = 10,
        FireMode = FireModes.BoltAction,

        Animations = {
            Idle = "rbxassetid://9678476818",
            Reload = "rbxassetid://9679977755",
        }
    },
    ["MAGPUL MASADA"] = {
        Damage = 25,
        RPM = 0,
        Recoil = 0,
        MagSize = 30,
        FireMode = FireModes.Auto,

        Animations = {
           Idle = "rbxassetid://9675626624",
           Reload = "rbxassetid://9679977755",
        }
    },

}