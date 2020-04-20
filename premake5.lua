local imgui_current_dir = "imgui"
local imgui_min_version_dir = "extern/imgui-1.64"
local project_location = ""
local sdl_dir = "extern/SDL-2.0.12"

function imgui_project(name, imgui_location)
    project(name)
    location(project_location)
    kind "StaticLib"
    language "C++"
    cppdialect "C++98"
    targetdir "lib/%{cfg.buildcfg}"
    files {
        path.join(imgui_location, "**.h"),
        path.join(imgui_location, "**.cpp")
    }
    includedirs {
        imgui_location,
        "gl3w/include", -- TODO: this should be in extern as well
        path.join(sdl_dir, "include") }

    -- TODO: this should be deleted in favor of local SDL
    filter "system:linux"
        -- NOTE: This is to support inclusion via #include <SDL.h>.
        -- Otherwise we would have to do <SDL2/SDL.h> which would not
        -- be compatible with the macOS framework
        includedirs { "/usr/include/SDL2" }
end

function imnodes_example_project(name, example_file)
    project(name)
    location(project_location)
    kind "WindowedApp"
    language "C++"
    targetdir "bin/%{cfg.buildcfg}"
    files {"example/main.cpp", path.join("example", example_file) }
    includedirs {
        ".",
        "imgui",
        "gl3w/include",
        path.join(sdl_dir, "include")
    }
    links { "gl3w", "imgui", "imnodes", "SDL2" }
    filter { "action:gmake" }
        buildoptions { "-std=c++11" }

    filter "system:macosx"
        -- On MacOS, it's very easy to end up with multiple iconvs, if using
        -- some kind of package manager which exports it's own location.
        -- Linking against /usr/lib mitigates against linking errors caused by this.
        libdirs { path.join(sdl_dir, "bin"), "/usr/lib" }
        links {
            "iconv",
            "AudioToolbox.framework",
            "Carbon.framework",
            "Cocoa.framework",
            "CoreAudio.framework",
            "CoreVideo.framework",
            "ForceFeedback.framework",
            "IOKit.framework"
        }

    filter "system:linux"
        includedirs { "/usr/include/SDL2" }
        links { "dl" }

    filter "system:windows"
        defines { "SDL_MAIN_HANDLED" }
end

workspace "imnodes"
    project_location = ""
    if _ACTION then
        project_location = "build/" .. _ACTION
    end

    configurations { "Debug", "Release" }
    architecture "x86_64"
    defines { "IMGUI_DISABLE_OBSOLETE_FUNCTIONS" }

    filter "configurations:Debug"
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"

    filter "action:vs*"
        defines { "_CRT_SECURE_NO_WARNINGS" }

    warnings "Extra"

    startproject "example"

    project "gl3w"
        location(project_location)
        kind "StaticLib"
        language "C"
        targetdir "lib/%{cfg.buildcfg}"
        files { "gl3w/src/gl3w.c" }
        includedirs { "gl3w/include" }

    project "imgui"
        location(project_location)
        kind "StaticLib"
        language "C++"
        cppdialect "C++98"
        targetdir "lib/%{cfg.buildcfg}"
        files { "imgui/**.h", "imgui/**.cpp" }
        includedirs {
            "imgui",
            "gl3w/include",
            path.join(sdl_dir, "include") }

        -- TODO: this should be deleted in favor of local SDL
        filter "system:linux"
            -- NOTE: This is to support inclusion via #include <SDL.h>.
            -- Otherwise we would have to do <SDL2/SDL.h> which would not
            -- be compatible with the macOS framework
            includedirs { "/usr/include/SDL2" }

    project "imnodes"
        location(project_location)
        kind "StaticLib"
        language "C++"
        cppdialect "C++98"
        enablewarnings { "all" }
        targetdir "lib/%{cfg.buildcfg}"
        files { "imnodes.h", "imnodes.cpp" }
        includedirs { "imgui" }

    imnodes_example_project("simple", "simple.cpp")

    imnodes_example_project("saveload", "save_load.cpp")

    imnodes_example_project("colornode", "color_node_editor.cpp")

    imnodes_example_project("multieditor", "multi_editor.cpp")
